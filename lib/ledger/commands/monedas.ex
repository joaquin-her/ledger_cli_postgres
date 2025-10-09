defmodule Ledger.Commands.Monedas do
  alias Ledger.Repo
  alias Ledger.Schemas.Moneda

  # crea una moneda
  def run(:crear, args) do
    moneda = %{
      nombre: args["-n"],
      precio_en_usd: String.to_float(args["-p"])
    }
    changeset = Moneda.changeset(%Moneda{}, moneda)
    changeset
    |> Ledger.Repo.insert()
  end

  # edita una moneda
  def run(:editar, _) do

  end

  # borra una moneda
  def run(:borrar, _) do

  end

  # lista una moneda
  def run(:ver, args) do
    case args["-id"] do
      "all" ->
        Repo.all(Moneda)
      id ->
        Repo.get!(Moneda, String.to_integer(id))
    end
  end

  def run(operation, args) do
    IO.puts("Running monedas with operation: #{operation} args: \n#{inspect(args)}")
  end

end
