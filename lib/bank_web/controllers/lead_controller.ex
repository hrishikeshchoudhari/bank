defmodule BankWeb.LeadController do
  use BankWeb, :controller

  alias Bank.Marketing
  alias Bank.Marketing.Lead

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    leads = Marketing.list_leads()
    render(conn, "index.html", leads: leads)
  end

  @spec new(Plug.Conn.t(), any) :: Plug.Conn.t()
  def new(conn, _params) do
    changeset = Marketing.change_lead(%Lead{})
    render(conn, "new.html", changeset: changeset)
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"lead" => lead_params}) do
    case Marketing.create_lead(lead_params) do
      {:ok, _lead} ->
        conn
        |> put_flash(:info, "Lead created successfully.")
        |> redirect(to: Routes.lead_path(conn, :thanks))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  @spec thanks(Plug.Conn.t(), any) :: Plug.Conn.t()
  def thanks(conn, _params) do
    render(conn, :thanks)
  end

end
