defmodule Ledger.CLI do
  alias Ledger.Commands

  @moduledoc """
  Module to handle command line interface for Ledger application.
  """
  def main(args) do
    [command | arguments] = args
    arguments = parse_args(arguments)

    case command do
      "balance" ->
        Commands.Balance.get_balance(arguments)
        |> print_balance()

      "transacciones" ->
        case Commands.Transacciones.run(arguments) do
          {:ok, transaccion} -> handle_transacciones(transaccion)
          {:error, error} -> IO.puts("[error] #{error}")
        end

      _ ->
        command = String.split(command, "_")

        case command do
          [verbo, "moneda"] ->
            case Commands.Monedas.run(String.to_atom(verbo), arguments) do
              {:ok, moneda} -> handle_moneda(verbo, moneda)
              {:error, error} -> IO.puts("[error] #{error}")
            end

          [verbo, "usuario"] ->
            case Commands.Usuarios.run(String.to_atom(verbo), arguments) do
              {:ok, usuario} -> handle_usuario(verbo, usuario)
              {:error, error} -> IO.puts("[error] #{error}")
            end

          ["alta", "cuenta"] ->
            case Commands.Transacciones.run(:crear, "alta_cuenta", arguments) do
              {:ok, transaccion} ->
                IO.puts(
                  "[info][created] #{transaccion.tipo}: id_moneda:#{transaccion.moneda_origen_id}, id_transaccion:#{transaccion.id}"
                )

              {:error, error} ->
                IO.puts("[error] #{error}")
            end

          ["ver", "transaccion"] ->
            case Commands.Transacciones.run(:ver, arguments) do
              {:ok, transaccion} -> print_transaccion(transaccion)
              {:error, error} -> IO.puts("[error] #{error}")
            end

          ["realizar", tipo] ->
            case Commands.Transacciones.run(:crear, tipo, arguments) do
              {:ok, transaccion} ->
                print_transaccion(transaccion)

              {:error, error} ->
                IO.puts("[error] #{error}")
            end

          ["deshacer", "transaccion"] ->
            case Commands.Transacciones.deshacer_transaccion(arguments) do
              {:ok, transaccion} ->
                t = format_raw(transaccion)
                IO.puts("[info][undo] transaccion #{t.tipo}: id=#{t.id}")

              {:error, error} ->
                IO.puts("[error] #{error}")
            end

          _ ->
            IO.puts("[error] ledgerCLI: Commando desconocido")
        end
    end
  end

  defp handle_moneda(verbo, moneda) when verbo == "ver",
    do:
      IO.puts(
        "[info] moneda: id=#{moneda.id}, nombre=#{moneda.nombre}, precio_en_usd=#{moneda.precio_en_usd}"
      )

  defp handle_moneda(verbo, moneda) when verbo == "editar",
    do:
      IO.puts(
        "[info][updated] moneda: id=#{moneda.id}, nombre=#{moneda.nombre}, precio_en_usd=#{moneda.precio_en_usd}"
      )

  defp handle_moneda(verbo, moneda) when verbo == "crear",
    do:
      IO.puts(
        "[info][created] moneda: nombre=#{moneda.nombre}, precio_en_usd=#{moneda.precio_en_usd}, id=#{moneda.id}"
      )

  defp handle_moneda(verbo, moneda) when verbo == "borrar",
    do:
      IO.puts(
        "[info][deleted] moneda: nombre=#{moneda.nombre}, precio_en_usd=#{moneda.precio_en_usd}, id=#{moneda.id}"
      )

  defp handle_usuario("crear", usuario),
    do:
      IO.puts("usuario creado correctamente: id=#{usuario.id}, nombre=#{usuario.nombre_usuario}")

  defp handle_usuario("editar", usuario),
    do:
      IO.puts("usuario editado correctamente: id=#{usuario.id}, nombre=#{usuario.nombre_usuario}")

  defp handle_usuario("borrar", usuario),
    do:
      IO.puts("usuario borrado correctamente: id=#{usuario.id}, nombre=#{usuario.nombre_usuario}")

  defp handle_usuario("ver", usuario),
    do:
      IO.puts(
        "usuario: id: #{usuario.id}, nombre: #{usuario.nombre_usuario}, birthdate: #{usuario.fecha_nacimiento}"
      )

  defp handle_transacciones(transacciones) do
    transacciones
    |> Enum.each(fn t ->
      t
      |> print_transaccion()
    end)
  end

  defp format_transaccion(t) do
    %{
      id: t.id,
      tipo: t.tipo,
      monto: t.monto,
      moneda_origen: t.moneda_origen.nombre,
      moneda_destino: t.moneda_destino.nombre,
      titular_origen: t.cuenta_origen.usuario.nombre_usuario,
      titular_destino: t.cuenta_destino.usuario.nombre_usuario
    }
  end

  defp preload_transaccion(transaccion) do
    transaccion
    |> Ledger.Repo.preload([
      :moneda_destino,
      :moneda_origen,
      cuenta_origen: [:usuario],
      cuenta_destino: [:usuario]
    ])
  end

  defp format_raw(transaccion) do
    preload_transaccion(transaccion)
    |> format_transaccion()
  end

  defp print_transaccion(transaccion) do
    t =
      preload_transaccion(transaccion)
      |> format_transaccion()

    IO.puts(
      "#{t.id} | #{t.tipo} | #{t.monto} | #{t.moneda_origen} | #{t.moneda_destino} | #{t.titular_origen} | #{t.titular_destino}"
    )
  end

  defp print_balance(tupla) do
    case tupla do
      {:ok, balances} ->
        Enum.each(balances, fn b ->
          IO.puts("#{b.moneda} | #{b.balance}")
        end)

      {:error, mensaje} ->
        IO.puts("[error] #{mensaje}")
    end
  end

  # returns a map with the parsed arguments as key-value pairs.
  def parse_args(args) do
    args
    |> Enum.reduce(%{}, fn arg, acc ->
      case String.split(arg, "=") do
        [key, value] -> Map.put(acc, key, value)
        _ -> acc
      end
    end)
  end
end
