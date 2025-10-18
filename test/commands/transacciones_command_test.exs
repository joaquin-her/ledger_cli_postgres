defmodule Commands.TransaccionesCommandTest do
  use ExUnit.Case, async: true
  alias Ledger.Schemas.Transaccion
  alias Ledger.Commands.Transacciones
  alias Ledger.Commands.Cuentas
  alias Ledger.Schemas.Cuenta
  alias Ledger.Commands.Monedas
  alias Ledger.Commands.Usuarios
  alias Ledger.TestHelpers
  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
    {_, usuario} = TestHelpers.crear_usuario_unico()
    {_, moneda1} = TestHelpers.crear_moneda_unica(1000.0)
    {_, moneda2} = TestHelpers.crear_moneda_unica(0.05)

    {_, alta_cuenta1} = TestHelpers.crear_alta_cuenta(usuario.id, moneda1.nombre, 10)

    {_, alta_cuenta2} = TestHelpers.crear_alta_cuenta(usuario.id, moneda2.nombre, 0)

    %{
      usuario1: usuario,
      moneda1: moneda1,
      moneda2: moneda2,
      alta_cuenta1: alta_cuenta1,
      alta_cuenta2: alta_cuenta2
    }
  end

  # Create transacciones
  test "se puede hacer una transaccion de tipo swap cuando un usuario tiene dos cuentas en esas monedas",
  %{usuario1: usuario, moneda1: moneda1, moneda2: moneda2, alta_cuenta1: alta_cuenta1, alta_cuenta2: alta_cuenta2} do
    args = %{
      "-u" => "#{usuario.id}",
      "-mo" => "#{moneda1.id}",
      "-md" => "#{moneda2.id}",
      "-a" => "1.5"
    }

    {:ok, transaccion} = Transacciones.run(:crear, "swap", args)
    cuenta_origen = Ledger.Repo.get(Cuenta, alta_cuenta1.cuenta_origen_id)
    cuenta_destino = Ledger.Repo.get(Cuenta, alta_cuenta2.cuenta_origen_id)

    monto_esperado_en_origen = "8.5"
    monto_esperado_en_destino = "30000.0"
    assert transaccion.tipo == "swap"
    assert transaccion.moneda_origen_id == moneda1.id
    assert transaccion.moneda_destino_id == moneda2.id
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

  test "se puede hacer un alta_cuenta en distintas monedas para un usuario",
    %{usuario1: usuario} do
    # usuario1 ya tiene 2 cuentas

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
    assert Enum.count(cuentas_usuario) == 4
  end

  test "se puede realizar una transaccion entre dos usuarios" do

    {_, usuario1} = TestHelpers.crear_usuario_unico()
    {_, usuario2} = TestHelpers.crear_usuario_unico()
    {_, moneda} = TestHelpers.crear_moneda_unica(500)
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
    cuenta_origen = Ledger.Repo.get(Cuenta, t.cuenta_origen_id)
    cuenta_destino = Ledger.Repo.get(Cuenta, t.cuenta_destino_id)
    assert transaccion.monto == Decimal.new(100)
    assert transaccion.tipo == "transferencia"

    assert cuenta_origen.cantidad == Decimal.new("400.0")
    assert cuenta_destino.cantidad == Decimal.new("101.05")
    assert transaccion.moneda_origen_id == moneda.id
    assert transaccion.moneda_destino_id == moneda.id
    assert transaccion.cuenta_origen_id == cuenta1.cuenta_origen_id
    assert transaccion.cuenta_destino_id == cuenta2.cuenta_origen_id
  end

  test "se puede deshacer una transaccion si es la ultima de ambos usuarios asociados",
    %{usuario1: usuario, moneda1: moneda1} do
    args = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    {_, usuario2} = Usuarios.run(:crear, args)

    args_alta_cuenta = %{
      "-u" => "#{usuario2.id}",
      "-m" => "#{moneda1.nombre}",
      "-a" => "100"
    }

    args_transacciones = %{
      "-o" => "#{usuario.id}",
      "-d" => "#{usuario2.id}",
      "-m" => "#{moneda1.id}",
      "-a" => "10"
    }
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_alta_cuenta)
    # usuario1: 10 * moneda1 , 0* moneda2
    # usuario2: 100 * moneda1
    {:ok, t} = Transacciones.run(:crear, "transferencia", args_transacciones)
    # usuario1: 10 * moneda1 , 0* moneda2
    # usuario2: 110 * moneda1

    cuenta_origen = Ledger.Repo.get(Cuenta, t.cuenta_origen_id)
    cuenta_destino = Ledger.Repo.get(Cuenta, t.cuenta_destino_id)

    assert cuenta_origen.cantidad == Decimal.new("0.0")
    assert cuenta_destino.cantidad == Decimal.new("110.0")

    #act
    {:ok, _} = Transacciones.deshacer(t.id)

    cuenta_origen = Ledger.Repo.get(Cuenta, t.cuenta_origen_id)
    cuenta_destino = Ledger.Repo.get(Cuenta, t.cuenta_destino_id)

    assert cuenta_origen.cantidad == Decimal.new("10.0")
    assert cuenta_destino.cantidad == Decimal.new("100.0")
  end

  test "no se puede deshacer una transaccion si no es la ultima de ambos usuarios asociados" do
    args = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    {_, usuario1} = Usuarios.run(:crear, args)
    args = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    {_, usuario2} = Usuarios.run(:crear, args)
    args_moneda = %{"-n" => "BTC", "-p" => "200"}
    {_, moneda} = Monedas.run(:crear, args_moneda)
    args_cuenta_1 = %{"-u" => "#{usuario1.id}", "-m" => "#{moneda.nombre}", "-a" => "500"}
    args_cuenta_2 = %{"-u" => "#{usuario2.id}", "-m" => "#{moneda.nombre}", "-a" => "1.05"}
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_cuenta_1)
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_cuenta_2)

    args_transacciones = %{
      "-o" => "#{usuario1.id}",
      "-d" => "#{usuario2.id}",
      "-m" => "#{moneda.id}",
      "-a" => "100"
    }

    {:ok, t} = Transacciones.run(:crear, "transferencia", args_transacciones)

    args_transaccion_extra = %{
      "-o" => "#{usuario1.id}",
      "-d" => "#{usuario2.id}",
      "-m" => "#{moneda.id}",
      "-a" => "10"
    }

    {:ok, _} = Transacciones.run(:crear, "transferencia", args_transaccion_extra)
    # act
    {:error, mensaje} = Transacciones.deshacer(t.id)
    # assert
    cuenta_origen = Ledger.Repo.get(Cuenta, t.cuenta_origen_id)
    cuenta_destino = Ledger.Repo.get(Cuenta, t.cuenta_destino_id)

    assert mensaje ==
             "deshacer_transaccion: No se puede deshacer la transaccion porque no es la ultima realizada por la cuenta de los usuarios"

    assert cuenta_origen.cantidad == Decimal.new("390.0")
    assert cuenta_destino.cantidad == Decimal.new("111.05")
  end

  test "no se puede realizar una transaccion entre dos usuarios si el origen no tiene " do

  end
  # Get transacciones

  # Update transacciones

  # Delete transacciones
end
