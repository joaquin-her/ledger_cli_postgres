defmodule Ledger.Commands.Usuario do

  def run(command, args) do
    IO.puts("Running usuario with command: #{command} and args: \n#{inspect(args)}")
  end

  # crea un usuario
  def run(:crear, args) do
  end

  # edita un usuario
  def run(:editar, args) do

  end

  # borra un usuario
  def run(:borrar, args) do

  end

  # lista un usuario
  def run(:ver, args) do

  end
end
