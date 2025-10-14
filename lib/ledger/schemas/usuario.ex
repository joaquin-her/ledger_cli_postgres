defmodule Ledger.Schemas.Usuario do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Ledger.Schemas.Transaccion

  schema "usuarios" do
    field :username , :string
    field :birth_date, :date
    has_many :transacciones_origen, Transaccion, foreign_key: :usuario_origen_id
    has_many :transacciones_destino, Transaccion, foreign_key: :usuario_destino_id
    timestamps(inserted_at: :created_at)
  end

  def changeset(usuario, attrs) do
    usuario
    |> Changeset.cast(attrs, [:username, :birth_date])
    |> Changeset.validate_required([:username, :birth_date])
    #|> validate_is_date()
    |> validar_es_mayor_de_edad()
    |> Changeset.unique_constraint(:username)
    |> Changeset.validate_length(:username, min: 1)
  end

  defp validar_es_mayor_de_edad(changeset) do
    fecha_nacimiento = Changeset.get_field(changeset, :birth_date)
    edad_minima = 18*365
    if fecha_nacimiento && Date.diff(Date.utc_today(), fecha_nacimiento) >= edad_minima do
      changeset
    else
      Changeset.add_error(changeset, :birth_date, "Debe ser mayor de edad")
    end
  end

  defp validate_is_date(changeset) do
    fecha_nacimiento = Changeset.get_field(changeset, :birth_date)
    case Date.from_iso8601(fecha_nacimiento) do
      {:error, :invalid_format} ->
        Changeset.add_error(changeset, :birth_date, "Formato de fecha no válido (ISO 8601)")
      {:ok, date} ->
        changeset
        |> Changeset.put_change(:birth_date, date)
      _ ->
        Changeset.add_error(changeset, :birth_date, "Formato de fecha no válido (ISO 8601)")

    end
  end
end
# 20 abril 2004
#Ledger.Commands.Usuario.run( :crear, %{"-n"=>"Fabrizzio_el_maestro_de_maestros@gmail", "-b"=>"2004-04-20"})
