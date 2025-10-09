defmodule Ledger.CLI do
  alias Ledger.Commands

  @moduledoc """
  Module to handle command line interface for Ledger application.
  """
  def main(args) do
    {status, config} = parse_args(args)
    case {status, config} do
      {:ok, arguments} ->
        case arguments.subcommand do
          "balance" ->
            Commands.Balance.run(arguments)
          "transacciones" ->
            Commands.Transacciones.run(arguments)
          _ -> IO.puts("Comando no reconocido")
        end
      {:error, reason} ->
        IO.puts("#{reason}")
    end
  end

  defp parse_args(args) do
    [command | arguments] = args
    processed_args = preprocess_account_flags(arguments)
    {options, remaining_args, errors} =
      processed_args
      |> OptionParser.parse(
        aliases: [
          t: :path_transacciones_data,
          o: :output_path,
          m: :moneda
        ],
        strict: [
          subcommand: :string,
          cuenta_origen: :string,
          path_transacciones_data: :string,
          cuenta_destino: :string,
          output_path: :string,
          moneda: :string
        ]
      )

    case {options, remaining_args, errors} do
      {opts, [], []} ->
        opts =
          default_args()
          |> Map.merge(Map.new(opts))
          |> Map.put(:subcommand, command)
        {:ok, opts}

      {_opts, remaining, []} ->
        remaining
        |> Enum.join(", ")
        |> then(fn msg -> {:error, "#{msg} no se reconoce como opcion valida"} end)

      {_opts, _remaining, errors} ->
        errors
        |> Enum.map(fn {key, val} -> "#{key}#{val}" end)
        |> Enum.join(", ")
        |> then(fn msg -> {:error, "#{msg} no se reconoce como opcion valida"} end)
    end
  end

  # Helper function to convert -c1 and -c2 to full option names
  defp preprocess_account_flags(args) do
    args
    |> Enum.flat_map(fn
      "-c1" -> ["--cuenta-origen"]
      "-c2" -> ["--cuenta-destino"]
      arg -> [arg]
    end)
  end

  defp default_args() do
    %{
      subcommand: "transacciones",
      cuenta_origen: "all",
      path_transacciones_data: "data/transacciones.csv",
      path_currencies_data: "data/monedas.csv",
      cuenta_destino: "all",
      output_path: "console",
      moneda: "all",
    }
  end
end
