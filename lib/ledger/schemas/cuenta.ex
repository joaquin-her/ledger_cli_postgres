defmodule Ledger.Schemas.Cuenta do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Ledger.Schemas.Moneda
  alias Ledger.Schemas.Usuario
  alias Ledger.Schemas.Transaccion

  schema "cuentas" do
    field :cantidad, :decimal
    belongs_to(:usuario, Usuario)
    belongs_to(:moneda, Moneda)
    has_many(:transacciones_origen, Transaccion, foreign_key: :cuenta_origen_id)
    has_many(:transacciones_destino, Transaccion, foreign_key: :cuenta_destino_id)
  end

  def changeset(cuenta, attrs) do
    cuenta
    |> Changeset.cast(attrs, [:usuario_id, :moneda_id])
    |> Changeset.validate_required([:usuario_id, :moneda_id])
    |> Changeset.foreign_key_constraint(:usuario_id)
    |> Changeset.foreign_key_constraint(:moneda_id)
  end
end
