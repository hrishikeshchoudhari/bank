defmodule Bank.Repo.Migrations.NameToCustomer do
  use Ecto.Migration

  def change do
    alter table("customers") do
      add :name, :string
    end
  end
end
