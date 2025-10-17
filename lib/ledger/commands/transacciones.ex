defmodule Ledger.Commands.Transacciones do
  alias Ledger.Commands.Cuentas
  alias Ledger.Schemas.Moneda
  alias Ledger.Schemas.Cuenta
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

  def run(:borrar, tipo, args) do
    case tipo do
      "swap" ->
        swap(:borrar, args)

      "transferencia" ->
        transferencia(:borrar, args)

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

  defp swap(:borrar, _) do
  end

  defp alta_cuenta(:crear, args) do
    with nombre_moneda <- args["-m"],
         {:ok, id_usuario} <- Utils.validate_id(args["-u"], "-u") do
      monto = args["-a"]
      query_id_moneda = from(m in Moneda, where: m.nombre == ^nombre_moneda, select: m.id)
      id_moneda = Ledger.Repo.one(query_id_moneda)

      query_cuenta_origen =
        from(c in Cuenta,
          where: c.usuario_id == ^id_usuario and c.moneda_id == ^id_moneda,
          select: c
        )

      cuenta = Ledger.Repo.one(query_cuenta_origen)

      case cuenta do
        nil ->
          args = %{"-id" => "#{id_usuario}", "-m" => "#{id_moneda}"}

          Cuentas.run(:alta, args)
          |> case do
            {:ok, _} ->
              alta_cuenta(:crear, %{
                "-m" => "#{nombre_moneda}",
                "-u" => "#{id_usuario}",
                "-a" => monto
              })

            {:error, error} ->
              {:error, error}

            _ ->
              {:error, "error"}
          end

        _ ->
          transaccion = %{
            cuenta_origen_id: cuenta.id,
            cuenta_destino_id: cuenta.id,
            moneda_origen_id: id_moneda,
            moneda_destino_id: id_moneda,
            tipo: "alta_cuenta",
            monto: monto
          }

          Transaccion.changese_alta_cuenta(%Transaccion{}, transaccion)
          |> insertar_transaccion("alta_cuenta")
      end
    else
      {:error, mensaje} ->
        {:error, mensaje}
    end
  end

  defp transferencia(:crear, args) do
    with {:ok, moneda_o_id} <- Utils.validate_id(args["-m"], "-m"),
         {:ok, usuario_origen_id} <- Utils.validate_id(args["-o"], "-o"),
         {:ok, usuario_destino_id} <- Utils.validate_id(args["-d"], "-d"),
         {:ok, cuenta_origen} <-
           Cuentas.run(:ver, %{"-u" => "#{usuario_origen_id}", "-m" => "#{moneda_o_id}"}),
         {:ok, cuenta_destino} <-
           Cuentas.run(:ver, %{"-u" => "#{usuario_destino_id}", "-m" => "#{moneda_o_id}"}) do
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
        {:error, mensaje}
    end
  end

  defp transferencia(:borrar, _) do
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

end
