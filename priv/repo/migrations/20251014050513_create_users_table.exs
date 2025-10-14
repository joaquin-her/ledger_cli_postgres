defmodule Ledger.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:usuarios) do
      add :username, :string
      add :birth_date, :date
      timestamps(inserted_at: :created_at)
    end

    create unique_index(:usuarios, [:username])
  end
end
