defmodule BankWeb.CustomerAuthTest do
  use BankWeb.ConnCase, async: true

  alias Bank.CoreBanking
  alias BankWeb.CustomerAuth
  import Bank.CoreBankingFixtures

  @remember_me_cookie "_bank_web_customer_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, BankWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{customer: customer_fixture(), conn: conn}
  end

  describe "log_in_customer/3" do
    test "stores the customer token in the session", %{conn: conn, customer: customer} do
      conn = CustomerAuth.log_in_customer(conn, customer)
      assert token = get_session(conn, :customer_token)
      assert get_session(conn, :live_socket_id) == "customers_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert CoreBanking.get_customer_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, customer: customer} do
      conn = conn |> put_session(:to_be_removed, "value") |> CustomerAuth.log_in_customer(customer)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, customer: customer} do
      conn = conn |> put_session(:customer_return_to, "/hello") |> CustomerAuth.log_in_customer(customer)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, customer: customer} do
      conn = conn |> fetch_cookies() |> CustomerAuth.log_in_customer(customer, %{"remember_me" => "true"})
      assert get_session(conn, :customer_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :customer_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_customer/1" do
    test "erases session and cookies", %{conn: conn, customer: customer} do
      customer_token = CoreBanking.generate_customer_session_token(customer)

      conn =
        conn
        |> put_session(:customer_token, customer_token)
        |> put_req_cookie(@remember_me_cookie, customer_token)
        |> fetch_cookies()
        |> CustomerAuth.log_out_customer()

      refute get_session(conn, :customer_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute CoreBanking.get_customer_by_session_token(customer_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "customers_sessions:abcdef-token"
      BankWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> CustomerAuth.log_out_customer()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if customer is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> CustomerAuth.log_out_customer()
      refute get_session(conn, :customer_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_customer/2" do
    test "authenticates customer from session", %{conn: conn, customer: customer} do
      customer_token = CoreBanking.generate_customer_session_token(customer)
      conn = conn |> put_session(:customer_token, customer_token) |> CustomerAuth.fetch_current_customer([])
      assert conn.assigns.current_customer.id == customer.id
    end

    test "authenticates customer from cookies", %{conn: conn, customer: customer} do
      logged_in_conn =
        conn |> fetch_cookies() |> CustomerAuth.log_in_customer(customer, %{"remember_me" => "true"})

      customer_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> CustomerAuth.fetch_current_customer([])

      assert get_session(conn, :customer_token) == customer_token
      assert conn.assigns.current_customer.id == customer.id
    end

    test "does not authenticate if data is missing", %{conn: conn, customer: customer} do
      _ = CoreBanking.generate_customer_session_token(customer)
      conn = CustomerAuth.fetch_current_customer(conn, [])
      refute get_session(conn, :customer_token)
      refute conn.assigns.current_customer
    end
  end

  describe "redirect_if_customer_is_authenticated/2" do
    test "redirects if customer is authenticated", %{conn: conn, customer: customer} do
      conn = conn |> assign(:current_customer, customer) |> CustomerAuth.redirect_if_customer_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "does not redirect if customer is not authenticated", %{conn: conn} do
      conn = CustomerAuth.redirect_if_customer_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_customer/2" do
    test "redirects if customer is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> CustomerAuth.require_authenticated_customer([])
      assert conn.halted
      assert redirected_to(conn) == Routes.customer_session_path(conn, :new)
      assert get_flash(conn, :error) == "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> CustomerAuth.require_authenticated_customer([])

      assert halted_conn.halted
      assert get_session(halted_conn, :customer_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> CustomerAuth.require_authenticated_customer([])

      assert halted_conn.halted
      assert get_session(halted_conn, :customer_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> CustomerAuth.require_authenticated_customer([])

      assert halted_conn.halted
      refute get_session(halted_conn, :customer_return_to)
    end

    test "does not redirect if customer is authenticated", %{conn: conn, customer: customer} do
      conn = conn |> assign(:current_customer, customer) |> CustomerAuth.require_authenticated_customer([])
      refute conn.halted
      refute conn.status
    end
  end
end
