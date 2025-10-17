defmodule Ledger.Commands.Balance do
  def run(args) do
    IO.puts("Running balance command with args: \n#{inspect(args)}")
  end
end
