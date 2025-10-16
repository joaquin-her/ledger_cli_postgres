defmodule Ledger.Commands.Usuarios do
  alias Ledger.Schemas.Usuario

  # crea un usuario
  def run(:crear, args) do
    usuario = %{
      nombre_usuario: args["-n"],
      fecha_nacimiento: args["-b"]
    }
    Usuario.changeset(%Usuario{}, usuario)
    |> Ledger.Repo.insert()
    |> case do
      {:ok, usuario} ->
        {:ok, usuario}
      {:error, changeset} ->
        {:error, "crear_usuario: #{format_errors(changeset)}"}
    end
  end

  # edita un usuario
  def run(:editar, args) do
    usuario = %{
      nombre_usuario: args["-n"],
    }
    case Integer.parse(args["-id"]) do
      :error -> {:error, "id no es un numero"}
      {id, _} ->
        usuario_a_modificar = Ledger.Repo.get!(Usuario, id)
        Usuario.changeset(usuario_a_modificar, usuario)
        |> Ledger.Repo.update()
        |> case  do
          {:ok, usuario_modificado} ->
            {:ok, usuario_modificado}
          {:error, changeset} ->
            {:error, "editar_usuario: #{format_errors(changeset)}"}
        end
    end
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
