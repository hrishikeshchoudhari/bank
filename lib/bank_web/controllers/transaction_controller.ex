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

end
