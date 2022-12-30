defmodule BankWeb.EmployeeResetPasswordController do
  use BankWeb, :controller

  alias Bank.Admin

  plug :get_employee_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"employee" => %{"email" => email}}) do
    if employee = Admin.get_employee_by_email(email) do
      Admin.deliver_employee_reset_password_instructions(
        employee,
        &Routes.employee_reset_password_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, _params) do
    render(conn, "edit.html", changeset: Admin.change_employee_password(conn.assigns.employee))
  end

  # Do not log in the employee after reset password to avoid a
  # leaked token giving the employee access to the account.
  def update(conn, %{"employee" => employee_params}) do
    case Admin.reset_employee_password(conn.assigns.employee, employee_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: Routes.employee_session_path(conn, :new))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp get_employee_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if employee = Admin.get_employee_by_reset_password_token(token) do
      conn |> assign(:employee, employee) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
