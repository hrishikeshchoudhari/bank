defmodule BankWeb.CustomerRegistrationController do
  use BankWeb, :controller

  alias Bank.CoreBanking
  alias Bank.CoreBanking.Customer
  alias BankWeb.CustomerAuth

  def new(conn, _params) do
    changeset = CoreBanking.change_customer_registration(%Customer{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"customer" => customer_params}) do
    case CoreBanking.register_customer(customer_params) do
      {:ok, customer} ->
        {:ok, _} =
          CoreBanking.deliver_customer_confirmation_instructions(
            customer,
            &Routes.customer_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "Customer created successfully.")
        |> CustomerAuth.log_in_customer(customer)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
