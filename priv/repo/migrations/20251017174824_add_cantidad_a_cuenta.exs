defmodule Ledger.Repo.Migrations.AddCantidadACuenta do
  use Ecto.Migration

  def change do
    alter table "cuentas" do
      add :cantidad, :decimal, default: 0.0
    end

  end
end
