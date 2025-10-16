defmodule Ledger.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:usuarios) do
      add :nombre_usuario, :string
      add :fecha_nacimiento, :date
      timestamps(inserted_at: :created_at)
    end

    create unique_index(:usuarios, [:nombre_usuario])
  end
end
