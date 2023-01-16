defmodule BankWeb.EmployeeSessionController do
  use BankWeb, :controller

  alias Bank.CoreBanking
  alias Bank.Admin
  alias BankWeb.EmployeeAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"employee" => employee_params}) do
    %{"email" => email, "password" => password} = employee_params

    if employee = Admin.get_employee_by_email_and_password(email, password) do
      EmployeeAuth.log_in_employee(conn, employee, employee_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> EmployeeAuth.log_out_employee()
  end

  def admin(conn, params) do
    render(conn, "admin.html", params: params)
  end

  def get_cust_acc(conn, params) do
    all = CoreBanking.get_cust_acc(conn, params)
    render(conn, "all_cust_acc.html", all: all)
  end

  def get_all_customers(conn, params) do
    customers = CoreBanking.get_all_customers(conn, params)
    render(conn, "all_customers.html", customers: customers)
  end

  def get_all_accounts(conn, params) do
    accounts = CoreBanking.get_all_accounts(conn, params)
    render(conn, "all_accounts.html", accounts: accounts)
  end
end
