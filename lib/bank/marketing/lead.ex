defmodule Bank.Marketing.Lead do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leads" do
    field :age, :integer
    field :name, :string
    field :email, :string

    timestamps()
  end

  @doc false
  def changeset(lead, attrs) do
    lead
    |> cast(attrs, [:name, :age, :email])
    |> validate_required([:name, :age, :email])
  end
end
