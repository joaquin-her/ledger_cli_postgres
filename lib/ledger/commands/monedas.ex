defmodule Ledger.Commands.Monedas do
  alias Ledger.Repo
  alias Ledger.Schemas.Moneda

  # crea una moneda
  def run(:crear, args) do
    moneda = %{
      nombre: args["-n"],
      precio_en_usd: String.to_float(args["-p"])
    }
    Moneda.changeset(%Moneda{}, moneda)
    |> Ledger.Repo.insert()
    |> case do
      {:ok, moneda} ->
        {:ok, moneda}
      {:error, changeset} ->
        {:error, "crear_usuario: #{format_errors(changeset)}"}
    end
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

  # Helper para formatear errores
  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

end
