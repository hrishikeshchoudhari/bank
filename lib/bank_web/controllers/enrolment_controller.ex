defmodule BankWeb.EnrolmentController do
  use BankWeb, :controller

  alias Bank.Marketing
  alias Bank.Marketing.Enrolment

  def index(conn, _params) do
    enrolments = Marketing.list_enrolments()
    render(conn, "index.html", enrolments: enrolments)
  end

  def new(conn, _params) do
    changeset = Marketing.change_enrolment(%Enrolment{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"enrolment" => enrolment_params}) do
    IO.inspect(enrolment_params)
    case Marketing.create_enrolment(enrolment_params) do
      {:ok, enrolment} ->
        conn
        |> put_flash(:info, "Enrolment created successfully.")
        |> redirect(to: Routes.enrolment_path(conn, :show, enrolment))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    enrolment = Marketing.get_enrolment!(id)
    render(conn, "show.html", enrolment: enrolment)
  end

  def edit(conn, %{"id" => id}) do
    enrolment = Marketing.get_enrolment!(id)
    changeset = Marketing.change_enrolment(enrolment)
    render(conn, "edit.html", enrolment: enrolment, changeset: changeset)
  end

  def update(conn, %{"id" => id, "enrolment" => enrolment_params}) do
    enrolment = Marketing.get_enrolment!(id)

    case Marketing.update_enrolment(enrolment, enrolment_params) do
      {:ok, enrolment} ->
        conn
        |> put_flash(:info, "Enrolment updated successfully.")
        |> redirect(to: Routes.enrolment_path(conn, :show, enrolment))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", enrolment: enrolment, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    enrolment = Marketing.get_enrolment!(id)
    {:ok, _enrolment} = Marketing.delete_enrolment(enrolment)

    conn
    |> put_flash(:info, "Enrolment deleted successfully.")
    |> redirect(to: Routes.enrolment_path(conn, :index))
  end
end
