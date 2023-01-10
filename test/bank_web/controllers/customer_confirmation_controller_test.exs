defmodule BankWeb.CustomerConfirmationControllerTest do
  use BankWeb.ConnCase, async: true

  alias Bank.CoreBanking
  alias Bank.Repo
  import Bank.CoreBankingFixtures

  setup do
    %{customer: customer_fixture()}
  end

  describe "GET /customers/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, Routes.customer_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /customers/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, customer: customer} do
      conn =
        post(conn, Routes.customer_confirmation_path(conn, :create), %{
          "customer" => %{"email" => customer.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(CoreBanking.CustomerToken, customer_id: customer.id).context == "confirm"
    end

    test "does not send confirmation token if Customer is confirmed", %{conn: conn, customer: customer} do
      Repo.update!(CoreBanking.Customer.confirm_changeset(customer))

      conn =
        post(conn, Routes.customer_confirmation_path(conn, :create), %{
          "customer" => %{"email" => customer.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(CoreBanking.CustomerToken, customer_id: customer.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.customer_confirmation_path(conn, :create), %{
          "customer" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(CoreBanking.CustomerToken) == []
    end
  end

  describe "GET /customers/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.customer_confirmation_path(conn, :edit, "some-token"))
      response = html_response(conn, 200)
      assert response =~ "<h1>Confirm account</h1>"

      form_action = Routes.customer_confirmation_path(conn, :update, "some-token")
      assert response =~ "action=\"#{form_action}\""
    end
  end

  describe "POST /customers/confirm/:token" do
    test "confirms the given token once", %{conn: conn, customer: customer} do
      token =
        extract_customer_token(fn url ->
          CoreBanking.deliver_customer_confirmation_instructions(customer, url)
        end)

      conn = post(conn, Routes.customer_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Customer confirmed successfully"
      assert CoreBanking.get_customer!(customer.id).confirmed_at
      refute get_session(conn, :customer_token)
      assert Repo.all(CoreBanking.CustomerToken) == []

      # When not logged in
      conn = post(conn, Routes.customer_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Customer confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_customer(customer)
        |> post(Routes.customer_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, customer: customer} do
      conn = post(conn, Routes.customer_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Customer confirmation link is invalid or it has expired"
      refute CoreBanking.get_customer!(customer.id).confirmed_at
    end
  end
end
