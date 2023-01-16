defmodule Bank.Repo.Migrations.CreateCustomersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:customers) do
      add :name, :string
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :account, references(:account, on_delete: :nothing)
      timestamps()
    end

    create unique_index(:customers, [:email])

    create table(:customers_tokens) do
      add :customer_id, references(:customers, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:customers_tokens, [:customer_id])
    create unique_index(:customers_tokens, [:context, :token])
  end
end
