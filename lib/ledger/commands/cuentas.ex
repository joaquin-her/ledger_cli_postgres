defmodule Ledger.Commands.Cuentas do
  alias Ledger.Schemas.Transaccion
  alias Ledger.Schemas.Cuenta
  alias Ledger.Commands.Utils
  import Ecto.Query

  @doc """
  ## Alta de cuenta:
  args:\n
  \t["-id"]: str (id del usuario)\n
  \t["-m"]:str (id de la moneda)\n
  """
  def run(:alta, args) do
    {id_moneda, _} = Integer.parse(args["-m"])
    {id_usuario, _} = Integer.parse(args["-id"])

    cuenta = %{
      moneda_id: id_moneda,
      usuario_id: id_usuario
    }

    try do
      Cuenta.changeset(%Cuenta{}, cuenta)
      |> Ledger.Repo.insert()
      |> case do
        {:ok, cuenta} ->
          {:ok, cuenta}

        {:error, changeset} ->
          {:error, "crear_cuenta: #{Utils.format_errors(changeset)}"}
      end
    rescue
      Ecto.ConstraintError ->
        {:error, "alta_cuenta: el usuario ya tiene una cuenta en esa moneda"}

      e ->
        {:error, "alta_cuenta: error al intentar crear la cuenta #{inspect(e)}"}
    end
  end

  def run(:ver, args) do
    with {:ok, id_usuario} <- Utils.validate_id(args["-u"], "-u"),
         {:ok, id_moneda} <- Utils.validate_id(args["-m"], "-m"),
         {:ok, cuenta} <- get_cuenta(id_usuario, id_moneda) do
      {:ok, cuenta}
    else
      {:error, mensaje} ->
        {:error, mensaje}
    end
  end

  defp get_cuenta(id_usuario, id_moneda) do
    query =
      from(c in Cuenta,
        where: c.usuario_id == ^id_usuario and c.moneda_id == ^id_moneda,
        select: c
      )

    case Ledger.Repo.one(query) do
      nil ->
        {:error, "cuenta no encontrada"}

      buscada ->
        {:ok, buscada}
    end
  end
end
