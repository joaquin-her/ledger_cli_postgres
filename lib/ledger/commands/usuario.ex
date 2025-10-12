defmodule Ledger.Commands.Usuario do

  # crea un usuario
  def run(:crear, _) do
  end

  # edita un usuario
  def run(:editar, _) do

  end

  # borra un usuario
  def run(:borrar, _) do

  end

  # lista un usuario
  def run(:ver, _) do

  end

  def run(command, args) do
    IO.puts("Running usuario with command: #{command} and args: \n#{inspect(args)}")
  end

end
