defmodule Bank.Marketing.Lead do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leads" do
    field :age, :integer
    field :name, :string
    field :secret, :string

    timestamps()
  end

  @doc false
  def changeset(lead, attrs) do
    lead
    |> cast(attrs, [:name, :age, :secret])
    |> validate_required([:name, :age, :secret])
  end
end
