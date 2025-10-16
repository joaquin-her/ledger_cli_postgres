defmodule Commands.TransaccionesCommandTest do
  use ExUnit.Case, async: true
  alias Ledger.Schemas.Transaccion
  alias Ledger.Commands.Transacciones
  alias Ledger.Commands.Monedas
  alias Ledger.Commands.Usuarios

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
  end

  # Create transacciones
  # test "se puede hacer una transaccion de tipo swap cuando un usuario tiene dos cuentas en esas monedas" do
  #   # Arrange
  #   args_usuario = %{"-n"=> "pepe", "-b" => "2001-11-01"}
  #   {_, usuario} = Usuarios.run(:crear, args_usuario)
  #   args_moneda_origen = %{"-n"=> "BTC", "-p"=>"10000"}
  #   args_moneda_destino = %{"-n"=> "PESO", "-p"=>"0.008"}
  #   {_, moneda_o} = Monedas.run(:crear, args_moneda_origen)
  #   {_, moneda_d} = Monedas.run(:crear, args_moneda_destino)

  #   args = %{"-u"=>"#{usuario.id}", "-mo"=>"#{moneda_o.nombre}", "-md"=>"#{moneda_d.nombre}", "-a"=> "100"}
  #   {status, transaccion} = Transacciones.run(:crear, "swap", args)
  #   assert status == :ok
  #   assert transaccion.moneda_origen == moneda_o.nombre
  #   assert transaccion.moneda_destino == moneda_d.nombre
  # end

  test "se pude hacer un alta_cuenta de un usuario para una moneda" do
    # arrange
    args_usuario = %{"-n"=> "julio-20", "-b" => "2001-11-01"}
    {_, usuario} = Usuarios.run(:crear, args_usuario)
    args_moneda = %{"-n"=> "BTC", "-p"=>"10000"}
    {_, moneda} = Monedas.run(:crear, args_moneda)
    {_, cuenta} = Ledger.Commands.Cuentas.run(:alta, %{"-id"=>"#{usuario.id}","-m"=>"#{moneda.id}"})


    #act
    args = %{"-u"=>"#{usuario.id}", "-m"=>"#{moneda.nombre}", "-a"=> "15"}
    {status, transaccion} = Transacciones.run(:crear, "alta_cuenta", args)
    #assert
    assert status == :ok
    transaccion_obtenida = Ledger.Repo.get(Transaccion, transaccion.id)
    assert transaccion_obtenida != nil
    assert transaccion.monto == Decimal.new("15")
  end

  # Get transacciones

  # Update transacciones

  # Delete transacciones
end
