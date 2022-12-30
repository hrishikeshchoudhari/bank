defmodule BankWeb.LeadController do
  use BankWeb, :controller

  alias Bank.Marketing
  alias Bank.Marketing.Lead

  def index(conn, _params) do
    leads = Marketing.list_leads()
    render(conn, "index.html", leads: leads)
  end

  def new(conn, _params) do
    changeset = Marketing.change_lead(%Lead{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"lead" => lead_params}) do
    case Marketing.create_lead(lead_params) do
      {:ok, lead} ->
        conn
        |> put_flash(:info, "Lead created successfully.")
        |> redirect(to: Routes.lead_path(conn, :thanks))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def thanks(conn, _params) do
    render(conn, :thanks)
  end

end
