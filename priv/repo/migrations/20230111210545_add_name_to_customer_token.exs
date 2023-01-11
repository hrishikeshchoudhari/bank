defmodule Bank.Repo.Migrations.AddNameToCustomerToken do
  use Ecto.Migration

  def change do
    alter table("customers_tokens") do
      add :name, :string
    end
  end
end
