defmodule Ledger.Commands.Monedas do

  def run(_, args) do
    IO.puts("Running monedas with args: \n#{inspect(args)}")
  end

  # defp create_moneda(attrs) do
  #   Ledger.Schemas.Moneda.changeset(%Ledger.Schemas.Moneda{}, attrs[])
  # end
end
