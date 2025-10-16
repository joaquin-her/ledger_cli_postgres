defmodule Ledger.Repo.Migrations.CreateCuentas do
  use Ecto.Migration

  def change do

    create table("cuentas") do
      add :usuario_id, references(:usuarios, on_delete: :restrict), null: false
      add :moneda_id ,references(:monedas, on_delete: :restrict), null: false
      timestamps(default: fragment("CURRENT_TIMESTAMP"))
    end
    create index(:cuentas, [:usuario_id])
    create index(:cuentas, [:moneda_id])
    # Una cuenta única por usuario y moneda
    create unique_index(:cuentas, [:usuario_id, :moneda_id])
  end
end
