defmodule Ledger.Repo.Migrations.CreateTransacciones do
  use Ecto.Migration

  def change do
    create table(:transacciones) do
      add :tipo, :string, null: false
      add :moneda_origen_id, references(:monedas, on_delete: :restrict), null: false
      add :moneda_destino_id, references(:monedas, on_delete: :restrict)
      add :monto, :decimal, null: false
      timestamps(default: fragment("CURRENT_TIMESTAMP"))
    end

    create index(:transacciones, [:moneda_origen_id])
    create index(:transacciones, [:moneda_destino_id])
  end
end
