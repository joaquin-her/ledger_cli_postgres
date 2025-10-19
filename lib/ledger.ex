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

      "transacciones" ->
        Commands.Transacciones.run(arguments)

      _ ->
        command = String.split(command, "_")

        case command do
          [verbo, "moneda"] ->
            case Commands.Monedas.run(String.to_atom(verbo), arguments) do
              {:ok, moneda} -> handle_moneda(verbo, moneda)
              {:error, error} -> IO.puts("error: #{error}")
            end

          [verbo, "usuario"] ->
            case Commands.Usuarios.run(String.to_atom(verbo), arguments) do
              {:ok, usuario} -> handle_usuario(verbo, usuario)
              {:error, error} -> IO.puts("error: #{error}")
            end

          [verbo, "cuenta"] ->
            Commands.Cuentas.run(String.to_atom(verbo), arguments)

          ["ver", "transaccion"] ->
            Commands.Transacciones.run(:ver, arguments)

          ["realizar", tipo] ->
            Commands.Transacciones.run(:crear, tipo, arguments)

          ["deshacer", tipo] ->
            Commands.Transacciones.deshacer_transaccion(tipo, arguments)

          _ ->
            {:error, "ledgerCLI: Commando desconocido"}
        end
    end
  end

  defp handle_moneda(verbo, moneda) when verbo == "ver" ,do: IO.puts("[info] moneda: id=#{moneda.id}, nombre=#{moneda.nombre}, precio_en_usd=#{moneda.precio_en_usd}")
  defp handle_moneda(verbo, moneda) when verbo == "editar" ,do: IO.puts("[info][updated] moneda: id=#{moneda.id}, nombre=#{moneda.nombre}, precio_en_usd=#{moneda.precio_en_usd}")
  defp handle_moneda(verbo, moneda) when verbo == "crear" ,do: IO.puts("[info][created] moneda: nombre=#{moneda.nombre}, precio_en_usd=#{moneda.precio_en_usd}, id=#{moneda.id}")
  defp handle_moneda(verbo, moneda) when verbo == "borrar" ,do: IO.puts("[info][deleted] moneda: nombre=#{moneda.nombre}, precio_en_usd=#{moneda.precio_en_usd}, id=#{moneda.id}")

  defp handle_usuario("crear", usuario) ,do: IO.puts("usuario creado correctamente: id=#{usuario.id}, nombre=#{usuario.nombre_usuario}")
  defp handle_usuario("editar", usuario) ,do: IO.puts("usuario editado correctamente: id=#{usuario.id}, nombre=#{usuario.nombre_usuario}")
  defp handle_usuario("borrar", usuario) ,do: IO.puts("usuario borrado correctamente: id=#{usuario.id}, nombre=#{usuario.nombre_usuario}")
  defp handle_usuario("ver", usuario) ,do: IO.puts("usuario: id: #{usuario.id}, nombre: #{usuario.nombre_usuario}, birthdate: #{usuario.fecha_nacimiento}")


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
