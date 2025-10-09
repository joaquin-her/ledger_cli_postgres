defmodule Ledger.Repo.Migrations.CreateMonedas do
  use Ecto.Migration

  def change do
    create table(:monedas) do
      add :nombre, :string, size: 4, unique: true, null: false
      add :precio_en_usd, :float, null: false
      timestamps(default: fragment("CURRENT_TIMESTAMP"))
    end

    create unique_index(:monedas, [:nombre])
  end
end
