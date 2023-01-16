defmodule Bank.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :acn, :string
      add :fname, :string
      add :balance, :integer
      add :secret, :string
      add :customer, references(:customers, on_delete: :nothing)
      add :transaction, references(:transactions, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:accounts, [:acn])
  end
end
