defmodule Bank.Repo.Migrations.AccountSecretToEmail do
  use Ecto.Migration

  def change do
    rename table("accounts"), :secret, to: :email
  end
end
