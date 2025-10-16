defmodule Ledger.Schemas.Transaccion do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Ledger.Schemas.Moneda

  schema "transacciones" do
    field :tipo, :string
    field :monto, :decimal
    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
    #belongs_to :moneda_origen_id, Moneda
    #belongs_to :moneda_destino_id, Moneda
    #belongs_to :usuario_origen_id, Usuario
    #belongs_to :usuario_destino_id, Usuario
  end

  def changeset(transaccion \\ %Ledger.Schemas.Transaccion{}, attrs) do
    transaccion
    |> Changeset.cast(attrs, [:tipo, :monto, :moneda_origen_id, :moneda_destino_id])
    |> Changeset.validate_required([:tipo, :monto, :moneda_origen_id])
    |> Changeset.validate_number(:monto, greater_than: 0)
    |> Changeset.update_change(:tipo, fn tipo -> String.downcase(tipo) end)
    |> Changeset.foreign_key_constraint(:moneda_origen_id)
  end
end
