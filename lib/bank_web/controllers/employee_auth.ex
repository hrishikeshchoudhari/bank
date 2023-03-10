defmodule BankWeb.EmployeeAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Bank.Admin
  alias BankWeb.Router.Helpers, as: Routes

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in EmployeeToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_bank_web_employee_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the employee in.
  """
  def log_in_employee(conn, employee, params \\ %{}) do
    token = Admin.generate_employee_session_token(employee)
    employee_return_to = get_session(conn, :employee_return_to)

    conn
    |> renew_session()
    |> put_session(:employee_token, token)
    |> put_session(:live_socket_id, "employees_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: employee_return_to || signed_in_path(conn))
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
  # and then immediately set it after clearing
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the employee out.
  """
  def log_out_employee(conn) do
    employee_token = get_session(conn, :employee_token)
    employee_token && Admin.delete_session_token(employee_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      BankWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the employee by looking into the session
  and remember me token.
  """
  def fetch_current_employee(conn, _opts) do
    {employee_token, conn} = ensure_employee_token(conn)
    employee = employee_token && Admin.get_employee_by_session_token(employee_token)
    assign(conn, :current_employee, employee)
  end

  defp ensure_employee_token(conn) do
    if employee_token = get_session(conn, :employee_token) do
      {employee_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if employee_token = conn.cookies[@remember_me_cookie] do
        {employee_token, put_session(conn, :employee_token, employee_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the employee to not be authenticated.
  """
  def redirect_if_employee_is_authenticated(conn, _opts) do
    if conn.assigns[:current_employee] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the employee to be authenticated.
  """
  def require_authenticated_employee(conn, _opts) do
    if conn.assigns[:current_employee] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: Routes.employee_session_path(conn, :new))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :employee_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: "/admin"
end
