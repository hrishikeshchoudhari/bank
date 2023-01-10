defmodule BankWeb.CustomerResetPasswordControllerTest do
  use BankWeb.ConnCase, async: true

  alias Bank.CoreBanking
  alias Bank.Repo
  import Bank.CoreBankingFixtures

  setup do
    %{customer: customer_fixture()}
  end

  describe "GET /customers/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, Routes.customer_reset_password_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Forgot your password?</h1>"
    end
  end

  describe "POST /customers/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, customer: customer} do
      conn =
        post(conn, Routes.customer_reset_password_path(conn, :create), %{
          "customer" => %{"email" => customer.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(CoreBanking.CustomerToken, customer_id: customer.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.customer_reset_password_path(conn, :create), %{
          "customer" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(CoreBanking.CustomerToken) == []
    end
  end

  describe "GET /customers/reset_password/:token" do
    setup %{customer: customer} do
      token =
        extract_customer_token(fn url ->
          CoreBanking.deliver_customer_reset_password_instructions(customer, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn = get(conn, Routes.customer_reset_password_path(conn, :edit, token))
      assert html_response(conn, 200) =~ "<h1>Reset password</h1>"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, Routes.customer_reset_password_path(conn, :edit, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end

  describe "PUT /customers/reset_password/:token" do
    setup %{customer: customer} do
      token =
        extract_customer_token(fn url ->
          CoreBanking.deliver_customer_reset_password_instructions(customer, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, customer: customer, token: token} do
      conn =
        put(conn, Routes.customer_reset_password_path(conn, :update, token), %{
          "customer" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == Routes.customer_session_path(conn, :new)
      refute get_session(conn, :customer_token)
      assert get_flash(conn, :info) =~ "Password reset successfully"
      assert CoreBanking.get_customer_by_email_and_password(customer.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, Routes.customer_reset_password_path(conn, :update, token), %{
          "customer" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Reset password</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, Routes.customer_reset_password_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end
end
