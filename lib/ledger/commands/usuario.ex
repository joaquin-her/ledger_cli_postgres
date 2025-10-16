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
            {:error, "editar_usuario: #{Utils.format_errors(changeset)}"}
        end
    end
  end

  # borra un usuario
  def run(:borrar, args) do
    case Integer.parse(args["-id"]) do
      :error -> {:error, "id no es un numero"}
      {id, _} ->
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
            {:error, "borrar_usuario: usuario no puede ser eliminado porque tiene transacciones asosciadas"}
          e ->
            {:error, "borrar_usuario: error al intentar eliminar al usuario #{inspect(e)}"}
        end
    end
  end

  # lista un usuario
  def run(:ver, args) do
    {id,_} = Integer.parse(args["-id"])
    case Ledger.Repo.get(Usuario, id) do
      nil -> {:error, "ver_usuario: usuario no encontrado"}
      usuario ->
        {:ok, usuario}
    end
  end

  def run(command, args) do
    IO.puts("Running usuario with command: #{command} and args: \n#{inspect(args)}")
  end

end
