defmodule BankWeb.EmployeeConfirmationController do
  use BankWeb, :controller

  alias Bank.Admin

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"employee" => %{"email" => email}}) do
    if employee = Admin.get_employee_by_email(email) do
      Admin.deliver_employee_confirmation_instructions(
        employee,
        &Routes.employee_confirmation_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", token: token)
  end

  def update(conn, %{"token" => token}) do
    case Admin.confirm_employee(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Employee confirmed successfully.")
        |> redirect(to: "/")

      :error ->

        case conn.assigns do
          %{current_employee: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "Employee confirmation link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end
end
