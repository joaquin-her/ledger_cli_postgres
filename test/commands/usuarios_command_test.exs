defmodule Commands.UsuariosCommandTest do
  use ExUnit.Case, async: true

  alias Ledger.Schemas.Usuarios
  alias Ledger.Commands.Usuarios

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
  end

  test "Se puede crear un usuario correctamente" do
    args = %{"-n"=> "pepe_el_pollo", "-b"=> "2004-06-20" }
    {status, usuario} = Usuarios.run(:crear, args)
    assert status == :ok
    assert usuario.nombre_usuario == "pepe_el_pollo"
    assert usuario.fecha_nacimiento == ~D[2004-06-20]
    assert usuario.id != nil
  end

  test "el usuario para crearse debe ser mayor de 18 años" do
    args = %{"-n"=> "sandro_lagarto", "-b"=> "2018-06-20" }
    {status, mensaje} = Usuarios.run(:crear, args)
    assert status == :error
    assert mensaje == "crear_usuario: fecha_nacimiento: Debe ser mayor de edad"
  end

  test "el nombre de usuario no puede repetirse para poder crearse un usuario" do
    args1 = %{"-n"=> "santiago_cocodrilo", "-b"=> "2005-10-20" }
    {status, _usuario} = Usuarios.run(:crear, args1)
    assert status == :ok
    args2 = %{"-n"=> "santiago_cocodrilo", "-b"=> "1998-01-02" }
    {status, mensaje} = Usuarios.run(:crear, args2)
    assert status == :error
    assert mensaje == "crear_usuario: nombre_usuario: has already been taken"
  end

  test "el campo nombre_usuario es obligatorio para poder crear el usuario" do
    args = %{"-b"=> "2005-10-20" }
    {status, mensaje} = Usuarios.run(:crear, args)
    assert status == :error
    assert mensaje == "crear_usuario: nombre_usuario: can't be blank"
  end

  test "la fecha de nacimiento es obligatoria para poder crear la cuenta" do
    args = %{"-n"=> "nereo_leon"}
    {status, mensaje} = Usuarios.run(:crear, args)
    assert status == :error
    assert mensaje == "crear_usuario: fecha_nacimiento: can't be blank"
  end

  test "el formato de la fecha de nacimiento debe ser ISO 8601" do
    args = %{"-n"=> "nicolas_perro", "-b"=> "2005/10/20"}
    {status, mensaje} = Usuarios.run(:crear, args)
    assert status == :error
    assert mensaje == "crear_usuario: fecha_nacimiento: is invalid"
  end

  test "el nombre de usuario puede ser modificado" do
    args = %{"-n"=> "nicolas_perro", "-b" => "2005-10-20"}
    {_, usuario} = Usuarios.run(:crear, args)
    assert usuario.nombre_usuario == "nicolas_perro"
    nuevos_args = %{"-n"=> "nicolas-gato", "-id"=> "#{usuario.id}"}
    {status, usuario_modificado} = Usuarios.run(:editar, nuevos_args)
    assert status == :ok
    assert usuario_modificado.nombre_usuario == "nicolas-gato"
  end

  test "el nombre de usuario no puede ser modificado con uno ya utilizado" do
    args = %{"-n"=> "nicolas_perro", "-b" => "2005-10-20"}
    {status, _} = Usuarios.run(:crear, args)
    assert status == :ok

    args2 = %{"-n"=> "nicolas_gato", "-b" => "2005-10-22"}
    {_, usuario_a_modificar} = Usuarios.run(:crear, args2)
    nuevos_args = %{"-n"=> "nicolas_perro", "-id"=> "#{usuario_a_modificar.id}"}
    {status, mensaje} = Usuarios.run(:editar, nuevos_args)
    assert status == :error
    assert mensaje == "editar_usuario: nombre_usuario: has already been taken"
  end

end
