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

  def validate_id(id) when is_integer(id) and id > 0, do: {:ok, id}

  def validate_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {num, ""} when num > 0 -> {:ok, num}
      _ -> {:error, "ID inválido"}
    end
  end

  def validate_id(_), do: {:error, "ID inválido"}

  def validate_id(id, flag) do
    case validate_id(id) do
      {:ok, id} -> {:ok, id}
      {:error, _} -> {:error, "id_invalido: #{flag}"}
    end
  end
end
