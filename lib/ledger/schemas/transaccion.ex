defmodule Ledger.Schemas.Transaccion do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Ledger.Schemas.Moneda
  alias Ledger.Schemas.Cuenta

  schema "transacciones" do
    field(:tipo, :string)
    field(:monto, :decimal)
    field(:inserted_at, :naive_datetime)
    field(:updated_at, :naive_datetime)
    belongs_to(:moneda_origen, Moneda)
    belongs_to(:moneda_destino, Moneda)
    belongs_to(:cuenta_origen, Cuenta)
    belongs_to(:cuenta_destino, Cuenta)
  end

  def changeset(transaccion \\ %Ledger.Schemas.Transaccion{}, attrs) do
    transaccion
    |> Changeset.cast(attrs, [:tipo, :monto, :moneda_origen_id, :cuenta_origen_id])
    |> Changeset.validate_required([:tipo, :monto, :moneda_origen_id, :cuenta_origen_id])
    |> Changeset.validate_number(:monto, greater_than_or_equal_to: 0)
    |> Changeset.update_change(:tipo, fn tipo -> String.downcase(tipo) end)
    |> Changeset.foreign_key_constraint(:moneda_origen_id)
    |> Changeset.foreign_key_constraint(:cuenta_origen_id)
  end

  def changese_alta_cuenta(transaccion \\ %Ledger.Schemas.Transaccion{}, attrs) do
    transaccion
    |> changeset(attrs)
    |> Changeset.cast(attrs, [:moneda_destino_id, :cuenta_destino_id])
    # valida que la cuenta exista
    |> validate_valid_account(:cuenta_origen)
  end

  def changeset_swap(transaccion \\ %Ledger.Schemas.Transaccion{}, attrs) do
    transaccion
    |> changeset(attrs)
    |> Changeset.cast(attrs, [:moneda_destino_id, :cuenta_destino_id])
    |> Changeset.validate_required(:moneda_destino_id)
    |> validate_valid_account(:cuenta_origen)
    |> validate_valid_account(:cuenta_destino)
    |> Changeset.foreign_key_constraint(:moneda_destino)
  end

  def changeset_transferencia(transaccion, attrs) do
    transaccion
    |> changeset(attrs)
    |> Changeset.cast(attrs, [:moneda_destino_id, :cuenta_destino_id])
    |> Changeset.foreign_key_constraint(:moneda_destino_id)
    |> Changeset.foreign_key_constraint(:cuenta_destino_id)
  end

  def validate_valid_account(changeset, account_field) do
    changeset
    |> Changeset.assoc_constraint(account_field)
  end
end
