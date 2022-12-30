defmodule Bank.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :acn, :string
      add :fname, :string
      add :balance, :integer
      add :secret, :string

      timestamps()
    end

    create unique_index(:accounts, [:acn])
  end
end
