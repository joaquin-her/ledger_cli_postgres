defmodule Ledger.Schemas.Moneda do
  use Ecto.Schema
  alias Ecto.Changeset

  schema "monedas" do
    field :nombre, :string
    field :precio_en_usd, :float
    field :inserted_at, :string
    field :updated_at, :string
  end

  def changeset(moneda \\ %Ledger.Schemas.Moneda{}, attrs) do
    moneda
    |> Changeset.cast(attrs, [:nombre, :precio_en_usd])
    |> Changeset.validate_required([:nombre, :precio_en_usd])
  end
end
