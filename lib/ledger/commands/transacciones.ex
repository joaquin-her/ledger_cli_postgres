defmodule Ledger.Commands.Transacciones do
  alias Ledger.Commands.Cuentas
  alias Ledger.Schemas.Transaccion
  alias Ledger.Commands.Utils
  import Ecto.Query

  def run(:ver, _) do
    {:ok, :ok}
  end

  def run(_) do
    {:ok, :ok}
  end

  @doc """
  ## Crear
   "tipos validos: SWAP, TRANSACCION, ALTA_CUENTA"
  "ALTA_CUENTA" =
      nombre_moneda = args["-m"]
      id_usuario = args["-u"]

  -u: usuario_id
  -mo: moneda_origen_id
  -md: moneda_destino_id
  -a: monto
  """
  def run(:crear, tipo, args) do
    case tipo do
      "swap" ->
        swap(:crear, args)

      "transferencia" ->
        transferencia(:crear, args)

      "alta_cuenta" ->
        alta_cuenta(:crear, args)

      _ ->
        {:error, "subcommando no encontrado"}
    end
  end

  def run(_, _, _) do
    {:error, "subcommando no encontrado"}
  end

  defp swap(:crear, args) do
    {:ok, cuenta_origen} = Cuentas.run(:ver, %{"-u" => args["-u"], "-m" => args["-mo"]})
    {:ok, cuenta_destino} = Cuentas.run(:ver, %{"-u" => args["-u"], "-m" => args["-md"]})

    swap = %{
      tipo: "swap",
      moneda_origen_id: args["-mo"],
      moneda_destino_id: args["-md"],
      cuenta_origen_id: cuenta_origen.id,
      cuenta_destino_id: cuenta_destino.id,
      monto: args["-a"]
    }

    swap
    |> Transaccion.changeset_swap()
    |> insertar_transaccion("swap")
  end

  defp crear_cuenta(id_moneda, id_usuario) do
    args = %{"-id" => "#{id_usuario}", "-m" => "#{id_moneda}"}
    Cuentas.run(:alta, args)
  end

  defp insertar_transaccion_alta_cuenta(id_moneda, id_cuenta, monto) do
    transaccion = %{
      cuenta_origen_id: id_cuenta,
      cuenta_destino_id: id_cuenta,
      moneda_origen_id: id_moneda,
      moneda_destino_id: id_moneda,
      tipo: "alta_cuenta",
      monto: monto
    }
    Transaccion.changese_alta_cuenta(%Transaccion{}, transaccion)
    |> insertar_transaccion("alta_cuenta")
  end

  defp alta_cuenta(:crear, args) do
    with {:ok, id_moneda} <- Utils.validate_id(args["-m"], "-m"),
          {:ok, id_usuario} <- Utils.validate_id(args["-u"], "-u"),
          true <- Cuentas.exists?(id_usuario, id_moneda),
          {:ok, cuenta} <- Cuentas.run(:ver, args) do
            monto = args["-a"]
            insertar_transaccion_alta_cuenta(id_moneda, cuenta.id, monto)
    else
      false ->
        crear_cuenta(args["-m"], args["-u"])
        alta_cuenta(:crear, args)
      {:error, motivo} ->
        {:error, "alta_cuenta: #{motivo}"}
    end
  end

  defp transferencia(:crear, args) do
    with {:ok, moneda_o_id} <- Utils.validate_id(args["-m"], "-m"),
         {:ok, usuario_origen_id} <- Utils.validate_id(args["-o"], "-o"),
         {:ok, usuario_destino_id} <- Utils.validate_id(args["-d"], "-d"),
         {:ok, cuenta_origen} <-
           Cuentas.get_cuenta(usuario_origen_id, moneda_o_id),
         {:ok, cuenta_destino} <-
           Cuentas.get_cuenta(usuario_destino_id, moneda_o_id) do
      transferencia = %{
        tipo: "transferencia",
        monto: args["-a"],
        cuenta_origen_id: cuenta_origen.id,
        cuenta_destino_id: cuenta_destino.id,
        moneda_origen_id: moneda_o_id,
        moneda_destino_id: moneda_o_id
      }

      Transaccion.changeset_transferencia(%Transaccion{}, transferencia)
      |> insertar_transaccion("transferencia")
    else
      {:error, mensaje} ->
        {:error, "realizar_transferencia: #{mensaje}"}
    end
  end

  defp insertar_transaccion(transaccion, funcion) do
    case Ledger.Repo.insert(transaccion) do
      {:ok, transaccion} ->
        Cuentas.update(transaccion)
        {:ok, transaccion}

      {:error, changeset} ->
        {:error, "#{funcion}: #{Utils.format_errors(changeset)}"}
    end
  end

  def deshacer_transaccion(tipo, arguments) do
    case tipo do
      "swap" ->
        deshacer(arguments["-id"])

      "transferencia" ->
        deshacer(arguments["-id"])

      "alta_cuenta" ->
        deshacer(arguments["-id"])

      _ ->
        {:error, "deshacer: subcommando no encontrado"}
    end
  end

  @doc """
  Deshace la transaccion con el id proporcionado si es la ultima de los usuarios intervinientes agregando su inversa en la base de datos
  """
  def deshacer(id_transaccion) do
    with {:ok, id} <- Utils.validate_id(id_transaccion),
         {:ok, transaccion} <- ver_transaccion(id),
         # true <- es_la_ultima_transaccion?(transaccion, transaccion.cuenta_origen_id)
         true <- es_la_ultima_transaccion?(transaccion, transaccion.cuenta_destino_id) do
      transaccion = %Transaccion{
        moneda_origen_id: transaccion.moneda_origen_id,
        cuenta_origen_id: transaccion.cuenta_destino_id,
        cuenta_destino_id: transaccion.cuenta_origen_id,
        monto: transaccion.monto,
        tipo: transaccion.tipo
      }

      insertar_transaccion(transaccion, transaccion.tipo)
    else
      {:error, mensaje} ->
        {:error, "deshacer_transaccion: #{mensaje}"}

      false ->
        {:error,
         "deshacer_transaccion: No se puede deshacer la transaccion porque no es la ultima realizada por la cuenta de los usuarios"}
    end
  end

  def ver_transaccion(id_transaccion) do
    case Ledger.Repo.get(Transaccion, id_transaccion) do
      nil ->
        {:error, "Transaccion no encontrada"}

      transaccion ->
        {:ok, transaccion}
    end
  end

  def es_la_ultima_transaccion?(transaction, account_id) do
    query =
      from(t in Transaccion,
        where:
          (t.cuenta_origen_id == ^account_id or t.cuenta_destino_id == ^account_id) and
            t.id > ^transaction.id,
        limit: 1,
        select: t.id
      )

    case Ledger.Repo.one(query) do
      # No hay transacciones más recientes, ¡es la última!
      nil -> true
      # Se encontró una transacción más reciente.
      _ -> false
    end
  end
end
