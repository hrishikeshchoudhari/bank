defmodule BankWeb.AccountController do
  use BankWeb, :controller

  alias Bank.CoreBanking
  alias Bank.CoreBanking.Account

  # def index(conn, _params) do
  #   leads = Marketing.list_leads()
  #   render(conn, "index.html", leads: leads)
  # end

  # def new(conn, _params) do
  #   changeset = Marketing.change_lead(%Lead{})
  #   render(conn, "new.html", changeset: changeset)
  # end

  def create(conn, %{"id" => lead_id}) do
    IO.inspect(lead_id)
    render(conn, "index.html", lead_id: lead_id)
  end

  # def thanks(conn, _params) do
  #   render(conn, :thanks)
  # end

end
