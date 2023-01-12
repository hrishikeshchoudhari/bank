defmodule Bank.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :src_acn, :string
      add :dst_acn, :string
      add :txn_mode, :string
      add :amount, :integer

      timestamps()
    end
  end
end
