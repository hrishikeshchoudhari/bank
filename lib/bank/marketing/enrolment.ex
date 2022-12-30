defmodule Bank.Marketing.Enrolment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "enrolments" do
    field :address, :string
    field :branch, :string
    field :email, :string
    field :fname, :string
    field :lname, :string
    field :mname, :string
    field :phone, :string

    timestamps()
  end

  @doc false
  def changeset(enrolment, attrs) do
    enrolment
    |> cast(attrs, [:fname, :mname, :lname, :address, :email, :phone, :branch])
    |> validate_required([:fname, :mname, :lname, :address, :email, :phone, :branch])
  end
end
