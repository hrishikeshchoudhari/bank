defmodule BankWeb.CustomerSessionController do
  use BankWeb, :controller

  alias Bank.CoreBanking
  alias BankWeb.CustomerAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"customer" => customer_params}) do
    %{"email" => email, "password" => password} = customer_params

    if customer = CoreBanking.get_customer_by_email_and_password(email, password) do
      CustomerAuth.log_in_customer(conn, customer, customer_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> CustomerAuth.log_out_customer()
  end
end
