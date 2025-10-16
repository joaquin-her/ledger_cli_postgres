defmodule Ledger.Repo.Migrations.AsocTransactionsCuentas do
  use Ecto.Migration

  def change do
    alter table "transacciones" do
      add :cuenta_origen_id, references(:cuentas, on_delete: :restrict), null: false
      add :cuenta_destino_id, references(:cuentas, on_delete: :restrict)
    end
    create index(:transacciones, [:cuenta_origen_id])
    create index(:transacciones, [:cuenta_destino_id])
  end
end
