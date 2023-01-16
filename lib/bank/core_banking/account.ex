defmodule Bank.CoreBanking.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :acn, :string
    field :balance, :integer
    field :fname, :string
    field :email, :string
    belongs_to :customer, Customer
    has_many :transactions, Transaction

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:acn, :fname, :balance, :email])
    |> validate_required([:acn, :fname, :balance, :email])
    |> unique_constraint(:acn)
  end
end
