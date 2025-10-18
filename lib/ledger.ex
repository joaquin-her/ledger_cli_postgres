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
        Commands.Balance.run(arguments)

      "transacciones" ->
        Commands.Transacciones.run(arguments)

      _ ->
        command = String.split(command, "_")

        case command do
          [verbo, "moneda"] ->
            Commands.Monedas.run(String.to_atom(verbo), arguments)

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

  defp handle_usuario(verbo, usuario) do
    case verbo do
      "ver" ->
        IO.puts(
          "usuario: id: #{usuario.id}, nombre: #{usuario.nombre_usuario}, birthdate: #{usuario.fecha_nacimiento}"
        )

      "crear" ->
        IO.puts(
          "usuario creado correctamente: id=#{usuario.id}, nombre=#{usuario.nombre_usuario}"
        )
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
