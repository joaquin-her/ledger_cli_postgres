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
            Commands.Monedas.run(verbo, arguments)
          [verbo, "usuario"] ->
            Commands.Usuario.run(verbo, arguments)
          _ ->
            Commands.Transacciones.run(command, arguments)
        end
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
