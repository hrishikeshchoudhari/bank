defmodule BankWeb.CustomerSettingsControllerTest do
  use BankWeb.ConnCase, async: true

  alias Bank.CoreBanking
  import Bank.CoreBankingFixtures

  setup :register_and_log_in_customer

  describe "GET /customers/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.customer_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if customer is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.customer_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.customer_session_path(conn, :new)
    end
  end

  describe "PUT /customers/settings (change password form)" do
    test "updates the customer password and resets tokens", %{conn: conn, customer: customer} do
      new_password_conn =
        put(conn, Routes.customer_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_customer_password(),
          "customer" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.customer_settings_path(conn, :edit)
      assert get_session(new_password_conn, :customer_token) != get_session(conn, :customer_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert CoreBanking.get_customer_by_email_and_password(customer.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.customer_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "customer" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :customer_token) == get_session(conn, :customer_token)
    end
  end

  describe "PUT /customers/settings (change email form)" do
    @tag :capture_log
    test "updates the customer email", %{conn: conn, customer: customer} do
      conn =
        put(conn, Routes.customer_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_customer_password(),
          "customer" => %{"email" => unique_customer_email()}
        })

      assert redirected_to(conn) == Routes.customer_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert CoreBanking.get_customer_by_email(customer.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.customer_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "customer" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /customers/settings/confirm_email/:token" do
    setup %{customer: customer} do
      email = unique_customer_email()

      token =
        extract_customer_token(fn url ->
          CoreBanking.deliver_update_email_instructions(%{customer | email: email}, customer.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the customer email once", %{conn: conn, customer: customer, token: token, email: email} do
      conn = get(conn, Routes.customer_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.customer_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute CoreBanking.get_customer_by_email(customer.email)
      assert CoreBanking.get_customer_by_email(email)

      conn = get(conn, Routes.customer_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.customer_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, customer: customer} do
      conn = get(conn, Routes.customer_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.customer_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert CoreBanking.get_customer_by_email(customer.email)
    end

    test "redirects if customer is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.customer_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.customer_session_path(conn, :new)
    end
  end
end
