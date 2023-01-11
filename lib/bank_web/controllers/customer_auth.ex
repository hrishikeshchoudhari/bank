defmodule BankWeb.CustomerAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Bank.CoreBanking
  alias Bank.CoreBanking.Account
  alias BankWeb.Router.Helpers, as: Routes

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in CustomerToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_bank_web_customer_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the customer in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_customer(conn, customer, params \\ %{}) do
    token = CoreBanking.generate_customer_session_token(customer)
    customer_return_to = get_session(conn, :customer_return_to)
    # Map.put(params, "name", customer.name)
    conn = assign(conn, :name, customer.name)

    conn
    |> renew_session()
    |> put_session(:customer_token, token)
    |> put_session(:live_socket_id, "customers_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: customer_return_to || signed_in_path(conn))

  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the customer out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_customer(conn) do
    customer_token = get_session(conn, :customer_token)
    customer_token && CoreBanking.delete_session_token(customer_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      BankWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the customer by looking into the session
  and remember me token.
  """
  def fetch_current_customer(conn, _opts) do
    {customer_token, conn} = ensure_customer_token(conn)
    customer = customer_token && CoreBanking.get_customer_by_session_token(customer_token)
    assign(conn, :current_customer, customer)
    # assign(conn, :name, customer.name)
  end

  defp ensure_customer_token(conn) do
    if customer_token = get_session(conn, :customer_token) do
      {customer_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if customer_token = conn.cookies[@remember_me_cookie] do
        {customer_token, put_session(conn, :customer_token, customer_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the customer to not be authenticated.
  """
  def redirect_if_customer_is_authenticated(conn, _opts) do
    if conn.assigns[:current_customer] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the customer to be authenticated.

  If you want to enforce the customer email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_customer(conn, _opts) do
    if conn.assigns[:current_customer] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: Routes.customer_session_path(conn, :new))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :customer_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(conn) do

    IO.inspect(conn.assigns.name)
    acc = CoreBanking.get_acc_by_name(conn.assigns.name)
    IO.inspect(acc.acn)
    # redirect(conn, to: Routes.account_path(conn, :accounthome, "me3@rishi.xyz"))
    "/accounts/home/" <> acc.fname
  end
end
