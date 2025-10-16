defmodule Ledger.Schemas.Cuenta do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Ledger.Schemas.Moneda
  alias Ledger.Schemas.Usuario

  schema "cuentas" do
    field :monto, :decimal
    belongs_to :usuario, Usuario
    belongs_to :moneda, Moneda
  end

  def changeset(cuenta, attrs) do
    cuenta
    |> Changeset.cast(attrs, [:monto, :usuario_id, :moneda_id])
    |> Changeset.validate_required([:monto, :usuario_id, :moneda_id])
    |> Changeset.validate_number(:monto, greater_than_or_equal_to: 0)
    |> Changeset.foreign_key_constraint(:usuario_id)
    |> Changeset.foreign_key_constraint(:moneda_id)
  end
end
