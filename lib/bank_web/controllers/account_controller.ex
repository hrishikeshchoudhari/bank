defmodule BankWeb.AccountController do
  use BankWeb, :controller

  alias Bank.CoreBanking
  alias Bank.CoreBanking.Account

  def create(conn, %{"id" => lead_id}) do
    lead2acc = CoreBanking.get_lead!(lead_id)
    render(conn, "show.html", lead2acc: lead2acc)
  end

  def gen_acc_num(conn, %{"name" => acc_id}) do
    CoreBanking.delete_lead(acc_id)
    case CoreBanking.create_account(acc_id) do
      {:ok, acc} ->
        conn
        |> render("index.html", acc: acc)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def accounthome(conn, _params) do
    render(conn, "home.html")
  end

  def statement(conn, _params) do
    case CoreBanking.get_account_statement(conn) do
      {:ok, stmt} ->
        conn
        |> render("statement.html", stmt: stmt)

      [] ->
        conn
        |> render("empty.html")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "statement.html", changeset: changeset)
    end
  end

end
