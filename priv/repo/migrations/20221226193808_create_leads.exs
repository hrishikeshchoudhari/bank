defmodule Bank.Repo.Migrations.CreateLeads do
  use Ecto.Migration

  def change do
    create table(:leads) do
      add :name, :string
      add :age, :integer
      add :secret, :string

      timestamps()
    end
  end
end
