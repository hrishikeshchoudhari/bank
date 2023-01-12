defmodule Bank.CoreBanking.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :amount, :integer
    field :dst_acn, :string
    field :src_acn, :string
    field :txn_mode, :string

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:src_acn, :dst_acn, :txn_mode, :amount])
    |> validate_required([:src_acn, :dst_acn, :txn_mode, :amount])
  end
end
