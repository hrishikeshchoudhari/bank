defmodule Bank.Marketing do
  @moduledoc """
  The Marketing context.
  """

  import Ecto.Query, warn: false
  alias Bank.Repo

  alias Bank.Marketing.Enrolment
  alias Bank.Marketing.Lead

  @doc """
  Returns the list of enrolments.
  """
  def list_enrolments do
    Repo.all(Enrolment)
  end

  @doc """
  Gets a single enrolment.
  """
  def get_enrolment!(id), do: Repo.get!(Enrolment, id)

  @doc """
  Creates a enrolment.
  """
  def create_enrolment(attrs \\ %{}) do
    %Enrolment{}
    |> Enrolment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a enrolment.
  """
  def update_enrolment(%Enrolment{} = enrolment, attrs) do
    enrolment
    |> Enrolment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a enrolment.
  """
  def delete_enrolment(%Enrolment{} = enrolment) do
    Repo.delete(enrolment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking enrolment changes.
  """
  def change_enrolment(%Enrolment{} = enrolment, attrs \\ %{}) do
    Enrolment.changeset(enrolment, attrs)
  end

  @spec list_leads :: any
  def list_leads do
    Repo.all(Lead)
  end

  def change_lead(%Lead{} = lead, attrs \\ %{}) do
    Lead.changeset(lead, attrs)
  end

  @spec create_lead(:invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}) ::
          any
  def create_lead(attrs \\ %{}) do
    %Lead{}
    |> Lead.changeset(attrs)
    |> Repo.insert()
  end
end
