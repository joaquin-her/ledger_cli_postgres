defmodule Ledger.Commands.Utils do
  # Helper para formatear errores
  def format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  @spec validate_id(any()) :: {:error, <<_::64, _::_*8>>} | {:ok, non_neg_integer()}
  def validate_id(id) when is_integer(id) and id >= 0, do: {:ok, id}

  def validate_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {num, ""} when num > 0 ->
        {:ok, num}

      {_, ""} ->
        {:error, "no puede ser negativo"}

      _ ->
        {:error, "no puede ser una cadena"}
    end
  end

  def validate_id(not_an_id) do
    case not_an_id do
      nil ->
        {:error, "es requerido"}
      _ ->
        {:error, "ID invalido"}

    end
  end

  def validate_id(id, flag) do
    case validate_id(id) do
      {:ok, id} -> {:ok, id}
      {:error, error} -> {:error, "id_invalido: argumento=#{flag} #{error}"}
    end
  end
end
