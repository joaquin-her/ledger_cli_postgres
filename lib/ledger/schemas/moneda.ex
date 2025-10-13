defmodule Ledger.Schemas.Moneda do
  use Ecto.Schema
  alias Ecto.Changeset

  schema "monedas" do
    field :nombre, :string
    field :precio_en_usd, :float
    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
    has_many :transacciones, Ledger.Schemas.Transaccion
  end

  def changeset(moneda \\ %Ledger.Schemas.Moneda{}, attrs) do
    moneda
    |> Changeset.cast(attrs, [:nombre, :precio_en_usd])
    |> Changeset.validate_required([:nombre, :precio_en_usd])
    |> Changeset.validate_length(:nombre, min: 3, max: 4)
    |> Changeset.validate_number(:precio_en_usd, greater_than: 0)
    |> Changeset.unique_constraint(:nombre)
    |> Changeset.update_change(:nombre, fn nombre -> String.upcase(nombre) end)
  end
end
