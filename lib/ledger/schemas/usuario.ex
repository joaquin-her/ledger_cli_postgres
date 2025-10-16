defmodule Ledger.Schemas.Usuario do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Ledger.Schemas.Transaccion

  schema "usuarios" do
    field :nombre_usuario , :string
    field :fecha_nacimiento, :date
    has_many :transacciones_origen, Transaccion, foreign_key: :usuario_origen_id
    has_many :transacciones_destino, Transaccion, foreign_key: :usuario_destino_id
    timestamps(inserted_at: :created_at)
  end

  def changeset(usuario, attrs) do
    usuario
    |> Changeset.cast(attrs, [:nombre_usuario, :fecha_nacimiento])
    |> Changeset.validate_required([:nombre_usuario, :fecha_nacimiento])
    |> validar_es_mayor_de_edad()
    |> Changeset.unique_constraint(:nombre_usuario)
    |> Changeset.validate_length(:nombre_usuario, min: 1)
  end

  defp validar_es_mayor_de_edad(changeset) do
    fecha_nacimiento = Changeset.get_field(changeset, :fecha_nacimiento)
    edad_minima = 18*365
    if fecha_nacimiento && Date.diff(Date.utc_today(), fecha_nacimiento) < edad_minima do
      Changeset.add_error(changeset, :fecha_nacimiento, "Debe ser mayor de edad")
    else
      changeset
    end
  end
end
# 20 abril 2004
