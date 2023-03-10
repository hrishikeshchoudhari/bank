defmodule BankWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use BankWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import BankWeb.ConnCase

      alias BankWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint BankWeb.Endpoint
    end
  end

  setup tags do
    Bank.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in employees.

      setup :register_and_log_in_employee

  It stores an updated connection and a registered employee in the
  test context.
  """
  def register_and_log_in_employee(%{conn: conn}) do
    employee = Bank.AdminFixtures.employee_fixture()
    %{conn: log_in_employee(conn, employee), employee: employee}
  end

  @doc """
  Logs the given `employee` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_employee(conn, employee) do
    token = Bank.Admin.generate_employee_session_token(employee)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:employee_token, token)
  end

  @doc """
  Setup helper that registers and logs in customers.

      setup :register_and_log_in_customer

  It stores an updated connection and a registered customer in the
  test context.
  """
  def register_and_log_in_customer(%{conn: conn}) do
    customer = Bank.CoreBankingFixtures.customer_fixture()
    %{conn: log_in_customer(conn, customer), customer: customer}
  end

  @doc """
  Logs the given `customer` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_customer(conn, customer) do
    token = Bank.CoreBanking.generate_customer_session_token(customer)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:customer_token, token)
  end
end
