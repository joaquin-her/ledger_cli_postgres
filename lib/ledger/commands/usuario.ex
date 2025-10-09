defmodule Ledger.Commands.Usuario do

  def run(command, args) do
    IO.puts("Running usuario with command: #{command} and args: \n#{inspect(args)}")
  end
end
