defmodule Commands.TransaccionesCommandTest do
  use ExUnit.Case, async: true
  alias Ledger.Schemas.Transaccion
  alias Ledger.Commands.Transacciones
  alias Ledger.Commands.Cuentas
  alias Ledger.Schemas.Cuenta
  alias Ledger.Commands.Monedas
  alias Ledger.Commands.Usuarios
  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
  end

  # Create transacciones
  test "se puede hacer una transaccion de tipo swap cuando un usuario tiene dos cuentas en esas monedas" do
    # Arrange
    args_usuario = %{"-n" => "pepe", "-b" => "2001-11-01"}
    {_, usuario} = Usuarios.run(:crear, args_usuario)
    args_moneda_origen = %{"-n" => "BTC", "-p" => "1000.0"}
    args_moneda_destino = %{"-n" => "PESO", "-p" => "0.05"}
    {_, moneda_o} = Monedas.run(:crear, args_moneda_origen)
    {_, moneda_d} = Monedas.run(:crear, args_moneda_destino)
    {_, alta_cuenta1} = Transacciones.run(:crear,"alta_cuenta", %{"-u" => "#{usuario.id}", "-m" => "#{moneda_o.nombre}", "-a"=>"10"})
    {_, alta_cuenta2} = Transacciones.run(:crear,"alta_cuenta", %{"-u" => "#{usuario.id}", "-m" => "#{moneda_d.nombre}", "-a"=>"0.0"})

    args = %{
      "-u" => "#{usuario.id}",
      "-mo" => "#{moneda_o.id}",
      "-md" => "#{moneda_d.id}",
      "-a" => "1.5"
    }
    {:ok, transaccion} = Transacciones.run(:crear, "swap", args)
    cuenta_origen = Ledger.Repo.get(Cuenta, alta_cuenta1.cuenta_origen_id)
    cuenta_destino = Ledger.Repo.get(Cuenta, alta_cuenta2.cuenta_origen_id)

    monto_esperado_en_origen = "8.5"
    monto_esperado_en_destino = "30000.0"
    assert transaccion.tipo == "swap"
    assert transaccion.moneda_origen_id == moneda_o.id
    assert transaccion.moneda_destino_id == moneda_d.id
    assert transaccion.monto == Decimal.new("1.5")
    assert transaccion.cuenta_origen_id == alta_cuenta1.cuenta_origen_id
    assert transaccion.cuenta_destino_id == alta_cuenta2.cuenta_origen_id
    assert Decimal.new(cuenta_origen.cantidad) == Decimal.new("#{monto_esperado_en_origen}")
    assert Decimal.new(cuenta_destino.cantidad) == Decimal.new("#{monto_esperado_en_destino}")

  end

  test "se pude hacer un alta_cuenta de un usuario para una moneda" do
    # arrange
    args_usuario = %{"-n" => "julio-20", "-b" => "2001-11-01"}
    {:ok, usuario} = Usuarios.run(:crear, args_usuario)
    args_moneda = %{"-n" => "BTC", "-p" => "10000"}
    {:ok, moneda} = Monedas.run(:crear, args_moneda)
    {:ok, cuenta} = Cuentas.run(:alta, %{"-id" => "#{usuario.id}", "-m" => "#{moneda.id}"})

    # act
    args = %{"-u" => "#{usuario.id}", "-m" => "#{moneda.nombre}", "-a" => "15"}
    {status, transaccion} = Transacciones.run(:crear, "alta_cuenta", args)
    # assert
    assert status == :ok
    transaccion = Ledger.Repo.get(Transaccion, transaccion.id)
    assert transaccion.tipo == "alta_cuenta"
    assert transaccion.moneda_origen_id == moneda.id
    assert transaccion.moneda_destino_id == moneda.id
    assert transaccion.cuenta_origen_id == cuenta.id
    assert transaccion.cuenta_destino_id == cuenta.id
    assert transaccion.monto == Decimal.new("15")
  end

  test "se puede hacer un alta_cuenta en distintas monedas para un usuario" do
    args = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    {_, usuario} = Usuarios.run(:crear, args)
    args_moneda1 = %{"-n" => "PAN", "-p" => "200"}
    args_moneda2 = %{"-n" => "FEO", "-p" => "100"}
    {_, moned1} = Monedas.run(:crear, args_moneda1)
    {_, moned2} = Monedas.run(:crear, args_moneda2)

    args_cuenta_1 = %{"-u" => "#{usuario.id}", "-m" => "#{moned1.nombre}", "-a" => "80"}
    args_cuenta_2 = %{"-u" => "#{usuario.id}", "-m" => "#{moned2.nombre}", "-a" => "800"}

    args_transaccion3 = %{
      "-u" => "#{usuario.id}",
      "-mo" => "#{moned1.id}",
      "-md" => "#{moned2.id}",
      "-a" => "0.99"
    }

    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_cuenta_1)
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_cuenta_2)
    {:ok, _} = Transacciones.run(:crear, "swap", args_transaccion3)

    query = from(t in Transaccion, where: t.tipo == ^"alta_cuenta", select: t)
    cuentas_usuario = Ledger.Repo.all(query)
    assert Enum.count(cuentas_usuario) == 2
  end

  test "se puede realizar una transaccion entre dos usuarios" do
    args = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    {_, usuario1} = Usuarios.run(:crear, args)
    args = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    {_, usuario2} = Usuarios.run(:crear, args)
    args_moneda = %{"-n" => "BTC", "-p" => "200"}
    {_, moneda} = Monedas.run(:crear, args_moneda)
    args_cuenta_1 = %{"-u" => "#{usuario1.id}", "-m" => "#{moneda.nombre}", "-a" => "500"}
    args_cuenta_2 = %{"-u" => "#{usuario2.id}", "-m" => "#{moneda.nombre}", "-a" => "1.05"}
    {:ok, cuenta1} = Transacciones.run(:crear, "alta_cuenta", args_cuenta_1)
    {:ok, cuenta2} = Transacciones.run(:crear, "alta_cuenta", args_cuenta_2)

    args_transacciones = %{
      "-o" => "#{usuario1.id}",
      "-d" => "#{usuario2.id}",
      "-m" => "#{moneda.id}",
      "-a" => "100"
    }

    {:ok, t} = Transacciones.run(:crear, "transferencia", args_transacciones)

    transaccion = Ledger.Repo.get(Transaccion, t.id)
    assert transaccion != nil
    assert transaccion.monto == Decimal.new(100)
    assert transaccion.tipo == "transferencia"
    assert transaccion.moneda_origen_id == moneda.id
    assert transaccion.moneda_destino_id == moneda.id
    assert transaccion.cuenta_origen_id == cuenta1.cuenta_origen_id
    assert transaccion.cuenta_destino_id == cuenta2.cuenta_origen_id
  end

  # Get transacciones

  # Update transacciones

  # Delete transacciones
end
