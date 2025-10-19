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
    with {:ok, id} <- Utils.validate_id(args["-id"], "-id"),
         {:ok, precio} <- Utils.validate_required(args["-p"], "-p"),
         {:ok, moneda} <- obtener_moneda(id) do
      editar_moneda(moneda, precio)
    else
      {:error, mensaje} ->
        {:error, "editar_moneda: #{mensaje}"}
    end
  end

  # borra una moneda
  def run(:borrar, args) do
    with {:ok, id} <- Utils.validate_id(args["-id"], "-id"),
         {:ok, moneda} <- obtener_moneda(id),
         {:ok, moneda} <- eliminar_moneda(moneda) do
      {:ok, moneda}
    else
      {:error, mensaje} ->
        {:error, "borrar_moneda: #{mensaje}"}
    end
  end

  # lista una moneda
  def run(:ver, args) do
    with {:ok, id} <- Utils.validate_id(args["-id"], "-id"),
        {:ok, moneda} <- obtener_moneda(id) do
          {:ok, moneda}
    else
      {:error, message} ->
        {:error, "ver_moneda: #{message}"}
    end
  end

  def run(operacion, _) do
    {:error, "monedas: #{operacion}: se desconoce como comando valido"}
  end

  defp eliminar_moneda(moneda) do
    try do
      moneda
      |> Ledger.Repo.delete()
      |> case do
        {:ok, moneda_eliminada} ->
          {:ok, moneda_eliminada}

        {:error, changeset} ->
          {:error, "#{Utils.format_errors(changeset)}"}
      end
    rescue
      Ecto.ConstraintError ->
        {:error, "no se puede borrar una moneda asociada a una/varias transacciones"}

      e ->
        {:error, "error al intentar eliminar al moneda #{inspect(e)}"}
    end
  end

  defp obtener_moneda(id) do
    case Ledger.Repo.get(Moneda, id) do
      nil ->
        {:error, "moneda no encontrada"}

      moneda ->
        {:ok, moneda}
    end
  end

  @spec convertir(number(), any(), any()) :: float()
  @doc """
  Convierte una cantidad de una moneda a otra acorde a sus valores en dolares en el instante de la conversion.
  """
  def convertir(cantidad, id_origen, id_destino) do
    moneda_origen = Ledger.Repo.get(Moneda, id_origen)
    moneda_destino = Ledger.Repo.get(Moneda, id_destino)
    cantidad_resultante = cantidad * moneda_origen.precio_en_usd / moneda_destino.precio_en_usd
    cantidad_resultante
  end

  defp editar_moneda(moneda, precio_nuevo) do
    with changeset <- Moneda.changeset(moneda, %{precio_en_usd: precio_nuevo}),
         {:ok, moneda_actualizada} <- Repo.update(changeset) do
      {:ok, moneda_actualizada}
    else
      {:error, changeset} ->
        {:error, "editar_moneda: #{Utils.format_errors(changeset)}"}
    end
  end
end
