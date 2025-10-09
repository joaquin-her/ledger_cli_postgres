defmodule Ledger.Commands.Transacciones do

  def run(args) do
    IO.puts("Running transacciones command with args: \n#{inspect(args)}")
  end

  def run(command, args) do
    IO.puts("Running transacciones with command: #{command} and args: \n#{inspect(args)}")
  end
end
