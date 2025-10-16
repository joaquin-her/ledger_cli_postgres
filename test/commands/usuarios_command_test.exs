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

  test "el cambio de nombre de usuario no puede ser el mismo que ya tenia antes" do
    args = %{"-n"=> "pedro_loro", "-b" => "2005-10-20"}
    {status, usuario} = Usuarios.run(:crear, args)
    assert status == :ok

    args2 = %{"-n"=> "pedro_loro", "-id"=> "#{usuario.id}"}
    {status, mensaje} = Usuarios.run(:editar, args2)
    assert status == :error
    assert mensaje == "editar_usuario: nombre_usuario: El nombre de usuario debe ser diferente al actual"
  end

  test "se puede eliminar a un usuario" do
    args = %{"-n"=> "santiago_cocodrilo2", "-b"=> "2005-12-20" }
    {status, usuario} = Usuarios.run(:crear, args)
    assert status == :ok

    {status, usuario_eliminado} = Usuarios.run(:borrar, %{"-id" => "#{usuario.id}"})
    assert status == :ok
    assert usuario_eliminado != nil
  end

  test "no se puede eliminar a un usuario con una cuenta y transacciones asociadas" do
    args = %{"-n"=> "roberto_zapato", "-b"=> "1990-12-02" }
    {status, usuario} = Usuarios.run(:crear, args)
    assert status == :ok

    {_, moneda} = Ledger.Commands.Monedas.run(:crear, %{"-n"=>"BTC", "-p"=>"3000.0"})
    # una alta cuenta es una transaccion porque agrega un monto a una cuenta del usuario en una monea determinada
    {status, _} = Ledger.Commands.Cuentas.run(:alta, %{"-id" => "#{usuario.id}", "-m"=>"#{moneda.id}", "-a"=>"2.0"})
    assert status == :ok

    args = %{"-id" => "#{usuario.id}"}
    {status, mensaje} = Usuarios.run(:borrar, args)
    assert status == :error
    assert mensaje == "borrar_usuario: usuario no puede ser eliminado porque tiene transacciones asosciadas"
  end

  test "se puede obtener un usuario correctamente" do
    args = %{"-n"=> "santiago_cocodrilo2", "-b"=> "2005-12-20" }
    {status, usuario} = Usuarios.run(:crear, args)
    assert status == :ok

    args_necesarios = %{"-id"=> "#{usuario.id}"}
    {status, usuario_obtenido} = Usuarios.run(:ver, args_necesarios)
    assert status == :ok
    assert usuario_obtenido.id == usuario.id
    assert usuario_obtenido.nombre_usuario == usuario.nombre_usuario
    assert usuario_obtenido.fecha_nacimiento == usuario.fecha_nacimiento
  end

  test "no se puede obtener un usuario que no existe" do
    args = %{"-id" => "1000000000"}
    {status, mensaje} = Usuarios.run(:ver, args)
    assert status == :error
    assert mensaje == "ver_usuario: usuario no encontrado"
  end

  test "un id negativo no permite ver a un usuario" do
    args = %{"-id" => "-1"}
    {status, mensaje} = Usuarios.run(:ver, args)
    assert status == :error
    assert mensaje == "ver_usuario: :id no puede ser negativo"
  end
end
