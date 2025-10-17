defmodule Commands.TransaccionesCommandTest do
  use ExUnit.Case, async: true
  alias Ledger.Schemas.Transaccion
  alias Ledger.Commands.Transacciones
  alias Ledger.Commands.Cuentas
  alias Ledger.Commands.Monedas
  alias Ledger.Commands.Usuarios
  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
  end

  # Create transacciones
  test "se puede hacer una transaccion de tipo swap cuando un usuario tiene dos cuentas en esas monedas" do
    # Arrange
    args_usuario = %{"-n"=> "pepe", "-b" => "2001-11-01"}
    {_, usuario} = Usuarios.run(:crear, args_usuario)
    args_moneda_origen = %{"-n"=> "BTC", "-p"=>"10000"}
    args_moneda_destino = %{"-n"=> "PESO", "-p"=>"0.008"}
    {_, moneda_o} = Monedas.run(:crear, args_moneda_origen)
    {_, moneda_d} = Monedas.run(:crear, args_moneda_destino)
    {_, cuenta1} = Cuentas.run(:alta, %{"-id"=>"#{usuario.id}","-m"=>"#{moneda_o.id}"})
    {_, cuenta2} = Cuentas.run(:alta, %{"-id"=>"#{usuario.id}","-m"=>"#{moneda_d.id}"})

    args = %{"-u"=>"#{usuario.id}", "-mo"=>"#{moneda_o.id}", "-md"=>"#{moneda_d.id}", "-a"=> "100"}
    {:ok, transaccion} = Transacciones.run(:crear, "swap", args)
    assert transaccion.moneda_origen_id == moneda_o.id
    assert transaccion.moneda_destino_id == moneda_d.id
    assert transaccion.monto == Decimal.new(100)
    assert transaccion.cuenta_origen_id == cuenta1.id
    assert transaccion.cuenta_destino_id == cuenta2.id

  end

  test "se pude hacer un alta_cuenta de un usuario para una moneda" do
    # arrange
    args_usuario = %{"-n"=> "julio-20", "-b" => "2001-11-01"}
    {:ok, usuario} = Usuarios.run(:crear, args_usuario)
    args_moneda = %{"-n"=> "BTC", "-p"=>"10000"}
    {:ok, moneda} = Monedas.run(:crear, args_moneda)
    {:ok, cuenta} = Cuentas.run(:alta, %{"-id"=>"#{usuario.id}","-m"=>"#{moneda.id}"})

    #act
    args = %{"-u"=>"#{usuario.id}", "-m"=>"#{moneda.nombre}", "-a"=> "15"}
    {status, transaccion} = Transacciones.run(:crear, "alta_cuenta", args)
    #assert
    assert status == :ok
    transaccion_obtenida = Ledger.Repo.get(Transaccion, transaccion.id)
    assert transaccion_obtenida != nil
    assert transaccion.monto == Decimal.new("15")
  end

  test "se puede hacer un alta_cuenta en distintas monedas para un usuario" do
    args = %{"-n"=>Faker.Pokemon.En.name(), "-b"=> Faker.Date.date_of_birth() }
    {_, usuario} = Usuarios.run(:crear, args)
    args_moneda1 = %{"-n"=>"PAN", "-p"=> "200"}
    args_moneda2 = %{"-n"=>"FEO", "-p"=> "100"}
    {_, moned1} = Monedas.run(:crear, args_moneda1)
    {_, moned2} = Monedas.run(:crear, args_moneda2)

    args_cuenta_1 = %{"-u"=> "#{usuario.id}", "-m"=>"#{moned1.nombre}", "-a"=>"80"}
    args_cuenta_2 = %{"-u"=> "#{usuario.id}", "-m"=>"#{moned2.nombre}", "-a"=>"800"}
    args_transaccion3 = %{"-u"=> "#{usuario.id}", "-mo"=>"#{moned1.nombre}", "-md"=>"#{moned2.nombre}", "-a"=>"0.99"}

    {:ok, transaccion1} = Transacciones.run(:crear, "alta_cuenta", args_cuenta_1)
    {:ok, transaccion2} = Transacciones.run(:crear, "alta_cuenta", args_cuenta_2)
    {:ok, transaccion3} = Transacciones.run(:crear, "swap", args_transaccion3)

    query = from t in Transaccion, where: t.tipo == ^"alta_cuenta" , select: t
    cuentas_usuario = Ledger.Repo.all(query)
    assert Enum.count(cuentas_usuario) == 2
  end
  # Get transacciones

  # Update transacciones

  # Delete transacciones
end
