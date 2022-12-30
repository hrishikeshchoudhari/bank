defmodule BankWeb.EmployeeRegistrationController do
  use BankWeb, :controller

  alias Bank.Admin
  alias Bank.Admin.Employee
  alias BankWeb.EmployeeAuth

  def new(conn, _params) do
    changeset = Admin.change_employee_registration(%Employee{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"employee" => employee_params}) do
    case Admin.register_employee(employee_params) do
      {:ok, employee} ->
        {:ok, _} =
          Admin.deliver_employee_confirmation_instructions(
            employee,
            &Routes.employee_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "Employee created successfully.")
        |> EmployeeAuth.log_in_employee(employee)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
