defmodule BankWeb.CustomerSessionControllerTest do
  use BankWeb.ConnCase, async: true

  import Bank.CoreBankingFixtures

  setup do
    %{customer: customer_fixture()}
  end

  describe "GET /customers/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.customer_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Register</a>"
      assert response =~ "Forgot your password?</a>"
    end

    test "redirects if already logged in", %{conn: conn, customer: customer} do
      conn = conn |> log_in_customer(customer) |> get(Routes.customer_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /customers/log_in" do
    test "logs the customer in", %{conn: conn, customer: customer} do
      conn =
        post(conn, Routes.customer_session_path(conn, :create), %{
          "customer" => %{"email" => customer.email, "password" => valid_customer_password()}
        })

      assert get_session(conn, :customer_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ customer.email
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "logs the customer in with remember me", %{conn: conn, customer: customer} do
      conn =
        post(conn, Routes.customer_session_path(conn, :create), %{
          "customer" => %{
            "email" => customer.email,
            "password" => valid_customer_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_bank_web_customer_remember_me"]
      assert redirected_to(conn) == "/"
    end

    test "logs the customer in with return to", %{conn: conn, customer: customer} do
      conn =
        conn
        |> init_test_session(customer_return_to: "/foo/bar")
        |> post(Routes.customer_session_path(conn, :create), %{
          "customer" => %{
            "email" => customer.email,
            "password" => valid_customer_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, customer: customer} do
      conn =
        post(conn, Routes.customer_session_path(conn, :create), %{
          "customer" => %{"email" => customer.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /customers/log_out" do
    test "logs the customer out", %{conn: conn, customer: customer} do
      conn = conn |> log_in_customer(customer) |> delete(Routes.customer_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :customer_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the customer is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.customer_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :customer_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
