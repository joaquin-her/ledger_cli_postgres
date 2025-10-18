defmodule Commands.CuentasCommandTest do
  use ExUnit.Case, async: true
  alias Ledger.Commands.Monedas
  alias Ledger.Commands.Cuentas
  alias Ledger.Commands.Usuarios
  alias Ledger.Schemas.Cuenta
  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
  end

  test "se puede crear una cuenta a un Usuario con una moneda y una cantidad" do
    args = %{"-n" => "roberto_sapo", "-b" => "1990-12-02"}
    {status, usuario} = Usuarios.run(:crear, args)
    assert status == :ok
    {_, moneda} = Monedas.run(:crear, %{"-n" => "ETH", "-p" => "3000.0"})

    # una alta cuenta es una transaccion porque agrega un monto a una cuenta del usuario en una monea determinada
    {status, cuenta} = Cuentas.run(:alta, %{"-id" => "#{usuario.id}", "-m" => "#{moneda.id}"})
    assert status == :ok
    cuenta = Ledger.Repo.get(Ledger.Schemas.Cuenta, cuenta.id)
    assert cuenta != nil
    assert cuenta.moneda_id == moneda.id
    assert cuenta.cantidad == Decimal.new("0.0")
  end

  test "se pueden crear varias cuentas para un mismo usuario con monedas distintas" do
    args = %{"-n" => "roberto_sapo", "-b" => "1990-12-02"}
    {_, usuario} = Usuarios.run(:crear, args)
    {_, moneda1} = Monedas.run(:crear, %{"-n" => "ETH", "-p" => "30.0"})
    {_, moneda2} = Monedas.run(:crear, %{"-n" => "BTC", "-p" => "50.0"})

    # alta cuenta 1
    {:ok, _} = Cuentas.run(:alta, %{"-id" => "#{usuario.id}", "-m" => "#{moneda1.id}"})
    # alta cuenta 2
    {:ok, _} = Cuentas.run(:alta, %{"-id" => "#{usuario.id}", "-m" => "#{moneda2.id}"})

    # assert
    query = from(c in Ledger.Schemas.Cuenta, where: c.usuario_id == ^usuario.id, select: c)
    result = Ledger.Repo.all(query)
    assert length(result) == 2
    cuenta1 = Enum.at(result, 0)
    cuenta2 = Enum.at(result, 1)
    assert cuenta1 != cuenta2
  end

  test "no se puede crear dos cuentas de la misma moneda para un mismo usuario" do
    args = %{"-n" => "roberto_sapo", "-b" => "1990-12-02"}
    {_, usuario} = Usuarios.run(:crear, args)
    {_, moneda} = Monedas.run(:crear, %{"-n" => "ETH", "-p" => "30.0"})

    # alta cuenta 1
    {:ok, _} = Cuentas.run(:alta, %{"-id" => "#{usuario.id}", "-m" => "#{moneda.id}"})
    # alta cuenta 2
    {status, mensaje} = Cuentas.run(:alta, %{"-id" => "#{usuario.id}", "-m" => "#{moneda.id}"})
    assert status == :error
    assert mensaje == "alta_cuenta: el usuario ya tiene una cuenta en esa moneda"
  end

  test "se puede incrementar la cantidad de una cuenta" do
    args = %{"-n" => "roberto_sapo", "-b" => "1990-12-02"}
    {_, usuario} = Usuarios.run(:crear, args)
    {_, moneda} = Monedas.run(:crear, %{"-n" => "ETH", "-p" => "30.0"})
    {:ok, cuenta} = Cuentas.run(:alta, %{"-id" => "#{usuario.id}", "-m" => "#{moneda.id}"})

    {:ok, _} = Cuentas.sumar_cantidad(cuenta.id, 10.0)
    cuenta_actualizada = Ledger.Repo.get(Cuenta, cuenta.id)
    assert cuenta_actualizada.cantidad == Decimal.new("10.0")
    assert cuenta_actualizada.id == cuenta.id
    assert cuenta_actualizada.usuario_id == usuario.id
  end

  test "se puede decrementar la cantidad de una cuenta" do
    args = %{"-n" => "roberto_sapo", "-b" => "1990-12-02"}
    {_, usuario} = Usuarios.run(:crear, args)
    {_, moneda} = Monedas.run(:crear, %{"-n" => "ETH", "-p" => "30.0"})
    {:ok, cuenta} = Cuentas.run(:alta, %{"-id" => "#{usuario.id}", "-m" => "#{moneda.id}"})
    {:ok, _} = Cuentas.sumar_cantidad(cuenta.id, 110.0)

    {:ok, _} = Cuentas.restar_cantidad(cuenta.id, 10.0)
    cuenta_actualizada = Ledger.Repo.get(Cuenta, cuenta.id)
    assert cuenta_actualizada.cantidad == Decimal.new("100.0")
    assert cuenta_actualizada.id == cuenta.id
    assert cuenta_actualizada.usuario_id == usuario.id
  end
end
