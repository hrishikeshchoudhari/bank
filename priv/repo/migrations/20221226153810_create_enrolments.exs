defmodule Bank.Repo.Migrations.CreateEnrolments do
  use Ecto.Migration

  def change do
    create table(:enrolments) do
      add :fname, :string
      add :mname, :string
      add :lname, :string
      add :address, :text
      add :email, :string
      add :phone, :text
      add :branch, :string

      timestamps()
    end
  end
end
