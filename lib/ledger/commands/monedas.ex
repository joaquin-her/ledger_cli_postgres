defmodule Ledger.Commands.Monedas do
  alias Ledger.Repo
  alias Ledger.Schemas.Moneda
  alias Ledger.Commands.Utils

  # crea una moneda
  @doc """
  ## Crear
  moneda = %{\n
    nombre: args["-n"],\n
    precio_en_usd: args["-p"]\n
  }
  ## Editar
  moneda = %{\n
    id: args["-id"] ,\n
    nombre: args["-n"],\n
    precio_en_usd: args["-p"]\n
  }
  ## Borarr
  moneda = %{\n
    id: args["-id"] ,\n
  }
  ## Ver
  moneda = %{\n
    id: args["-id"] ,\n
  }
  """
  def run(:crear, args) do
    moneda = %{
      nombre: args["-n"],
      precio_en_usd: args["-p"]
    }

    Moneda.changeset(%Moneda{}, moneda)
    |> Ledger.Repo.insert()
    |> case do
      {:ok, moneda} ->
        {:ok, moneda}

      {:error, changeset} ->
        {:error, "crear_usuario: #{Utils.format_errors(changeset)}"}
    end
  end

  # edita una moneda
  def run(:editar, args) do
    case Integer.parse(args["-id"]) do
      :error ->
        {:error, "editar_moneda: id: is invalid"}

      {id, _} ->
        with %Moneda{} = moneda <- Repo.get(Moneda, id),
             changeset <- Moneda.changeset(moneda, %{precio_en_usd: args["-p"]}),
             {:ok, moneda_actualizada} <- Repo.update(changeset) do
          {:ok, moneda_actualizada}
        else
          {:error, changeset} ->
            {:error, "editar_moneda: #{Utils.format_errors(changeset)}"}

          nil ->
            {:error, "editar_moneda: moneda no encontrada"}
        end
    end
  end

  # borra una moneda
  def run(:borrar, args) do
    Utils.validate_id(args["-id"])
    |> case do
      {:ok, id} ->
        Ledger.Repo.get(Moneda, id)
        |> case do
          nil ->
            {:error, "borrar_moneda: Moneda no encontrada con el ID proporcionado"}

          moneda_a_eliminar ->
            eliminar_moneda(moneda_a_eliminar)
        end

      {:error, mensaje} ->
        {:error, mensaje}
    end
  end

  # lista una moneda
  def run(:ver, args) do
    case args["-id"] do
      "all" ->
        {:ok, Repo.all(Moneda)}

      id ->
        case Repo.get(Moneda, String.to_integer(id)) do
          nil ->
            {:error, "ver_moneda: Moneda no encontrada"}

          moneda ->
            {:ok, moneda}
        end
    end
  end

  def run(operation, args) do
    IO.puts("Running monedas with operation: #{operation} args: \n#{inspect(args)}")
  end

  defp eliminar_moneda(moneda) do
    try do
      moneda
      |> Ledger.Repo.delete()
      |> case do
        {:ok, moneda_eliminada} ->
          {:ok, moneda_eliminada}

        {:error, changeset} ->
          {:error, "borrar_moneda: #{Utils.format_errors(changeset)}"}
      end
    rescue
      Ecto.ConstraintError ->
        {:error,
         "borrar_moneda: no se puede borrar una moneda asociada a una/varias transacciones"}

      e ->
        {:error, "borrar_moneda: error al intentar eliminar al moneda #{inspect(e)}"}
    end
  end
end
