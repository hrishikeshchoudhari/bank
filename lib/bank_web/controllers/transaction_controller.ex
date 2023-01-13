defmodule BankWeb.TransactionController do
  use BankWeb, :controller

  alias Bank.CoreBanking
  alias Bank.CoreBanking.Account
  alias Bank.CoreBanking.Transaction

  def index(conn, _params) do
    acc = CoreBanking.get_acc_by_name(conn.assigns.current_customer.name)
    conn = assign(conn, :account, acc)
    render(conn, "index.html", acc: acc)
  end

  def new(conn, _params) do
    acc = CoreBanking.get_acc_by_name(conn.assigns.current_customer.name)
    conn = assign(conn, :account, acc)
    changeset = CoreBanking.change_transaction(%Transaction{src_acn: acc.acn})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"transaction" => transaction_params}) do
    acc = CoreBanking.get_acc_by_name(conn.assigns.current_customer.name)
    conn = assign(conn, :account, acc)
    case CoreBanking.create_transaction(transaction_params) do
      {:ok, transaction} ->
        conn
        |> put_flash(:info, "Transaction created successfully.")
        |> redirect(to: Routes.transaction_path(conn, :show, transaction))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    transaction = CoreBanking.get_transaction!(id)
    render(conn, "show.html", transaction: transaction)
  end

end
