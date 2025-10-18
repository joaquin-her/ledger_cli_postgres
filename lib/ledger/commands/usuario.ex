defmodule Ledger.Commands.Usuarios do
  alias Ledger.Schemas.Usuario
  alias Ledger.Commands.Utils
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
        {:error, "crear_usuario: #{Utils.format_errors(changeset)}"}
    end
  end

  def run(:editar, args) do
    with {:ok, id} <- Utils.validate_id(args["-id"], "-id") do
      editar_usuario(id, args["-n"])
    else
      {:error, motivo} ->
        {:error, "editar_usuario: #{motivo}"}
    end
  end

  # borra un usuario
  def run(:borrar, args) do
    with {:ok, id} <- Utils.validate_id(args["-id"], "-id") do
      borrar_usuario(id)
    else
      {:error, mensaje} ->
        {:error, "borrar_usuario: #{mensaje}"}
    end
  end

  # lista un usuario
  def run(:ver, args) do
    with {:ok, id} <- Utils.validate_id(args["-id"], "-id") do
      case get_usuario(id) do
        nil ->
          {:error, "ver_usuario: usuario no encontrado"}

        usuario ->
          {:ok, usuario}
      end
    else
      {:error, mensaje} ->
        {:error, "ver_usuario: #{mensaje}"}
    end
  end

  @doc """
    usuario = %{\n
      nombre_usuario: args["-n"],\n
      fecha_nacimiento: args["-b"]\n
    }
  """
  def run(command, _) do
    {:error, "usuario: comando #{command}: no reconocido"}
  end

  defp borrar_usuario(id) do
    try do
      Ledger.Repo.get!(Usuario, id)
      |> Ledger.Repo.delete()
      |> case do
        {:ok, _usuario} ->
          {:ok, "borrar_usuario: usuario eliminado correctamente"}

        {:error, changeset} ->
          {:error, "borrar_usuario: #{Utils.format_errors(changeset)}"}
      end
    rescue
      Ecto.ConstraintError ->
        {:error,
         "borrar_usuario: usuario no puede ser eliminado porque tiene transacciones asosciadas"}

      e ->
        {:error, "borrar_usuario: error al intentar eliminar al usuario #{inspect(e)}"}
    end
  end

  defp editar_usuario(id, nuevo_nombre) do
    usuario = %{
      nombre_usuario: nuevo_nombre
    }

    usuario_a_modificar = Ledger.Repo.get!(Usuario, id)

    Usuario.changeset(usuario_a_modificar, usuario)
    |> Ledger.Repo.update()
    |> case do
      {:ok, usuario_modificado} ->
        {:ok, usuario_modificado}

      {:error, changeset} ->
        {:error, "editar_usuario: #{Utils.format_errors(changeset)}"}
    end
  end

  defp get_usuario(id_usuario) do
    Ledger.Repo.get(Usuario, id_usuario)
  end
end
