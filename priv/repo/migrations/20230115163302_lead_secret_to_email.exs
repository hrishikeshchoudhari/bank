defmodule Bank.Repo.Migrations.LeadSecretToEmail do
  use Ecto.Migration

  def change do
    rename table("leads"), :secret, to: :email
  end
end
