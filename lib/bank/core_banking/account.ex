defmodule Bank.CoreBanking.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :acn, :string
    field :balance, :integer
    field :fname, :string
    field :secret, :string

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:acn, :fname, :balance, :secret])
    |> validate_required([:acn, :fname, :balance, :secret])
    |> unique_constraint(:acn)
  end
end
