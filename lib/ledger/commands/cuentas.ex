defmodule Ledger.Commands.Cuentas do
  alias Ledger.Schemas.Cuenta
  alias Ledger.Commands.Utils
  alias Ledger.Commands.Monedas

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

  @doc """
  Obtiene la cuenta asociada al usuario y moneda especificados.

  ## Parámetros:
  \tid_usuario: integer (ID del usuario)
  \tid_moneda: integer (ID de la moneda)

  ## Retorna:
  \t{:ok, %Cuenta{}} en caso de éxito
  \t{:error, atom} en caso de error
  """

  def get_cuenta(id_usuario, id_moneda) do
    with {:ok, id_usuario_valido} <- Utils.validate_id(id_usuario),
         {:ok, id_moneda_valido} <- Utils.validate_id(id_moneda) do
      from(c in Cuenta,
        where: c.usuario_id == ^id_usuario_valido and c.moneda_id == ^id_moneda_valido,
        select: c
      )
      |> Ledger.Repo.one()
      |> case do
        nil ->
          {:error,
           "get_cuenta: cuenta de usuario #{id_usuario} no encontrada para moneda id #{id_moneda}"}

        buscada ->
          {:ok, buscada}
      end
    else
      {:error, mensaje} ->
        {:error, mensaje}
    end
  end

  def exists?(id_usuario, id_moneda) do
    with {:ok, _} <- Utils.validate_id(id_usuario),
         {:ok, _} <- Utils.validate_id(id_moneda) do
      case get_cuenta(id_usuario, id_moneda) do
        {:ok, _} -> true
        {:error, _} -> false
      end
    else
      {:error, _} -> false
    end
  end

  def update(transaccion) do
    case transaccion.tipo do
      "transferencia" ->
        restar_cantidad(transaccion.cuenta_origen_id, transaccion.monto)
        sumar_cantidad(transaccion.cuenta_destino_id, transaccion.monto)

      "swap" ->
        intercambiar_cantidad(transaccion)

      "alta_cuenta" ->
        sumar_cantidad(transaccion.cuenta_origen_id, transaccion.monto)
    end
  end

  def restar_cantidad(id_cuenta, monto) when monto >= 0 do
    sumar_cantidad(id_cuenta, Decimal.negate("#{monto}"))
  end

  def intercambiar_cantidad(transaccion) do
    cantidad_a_transferir =
      Decimal.to_float(transaccion.monto)
      |> Monedas.convertir(transaccion.moneda_origen_id, transaccion.moneda_destino_id)

    sumar_cantidad(transaccion.cuenta_destino_id, cantidad_a_transferir)
    restar_cantidad(transaccion.cuenta_origen_id, transaccion.monto)
  end

  def sumar_cantidad(id, cantidad) do
    query =
      from(c in Cuenta,
        where: c.id == ^id
      )

    {count, _} = Ledger.Repo.update_all(query, inc: [cantidad: cantidad])

    if count == 1 do
      # Usar Repo.get! es seguro aquí si el update_all devolvió 1
      cuenta = Ledger.Repo.get!(Cuenta, id)
      {:ok, cuenta}
    else
      {:error, "Cuenta no encontrada o modificaciones no realizadas"}
    end
  end
end
