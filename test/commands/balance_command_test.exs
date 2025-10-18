defmodule Commands.BalanceCommandTest do
  use ExUnit.Case, async: true
  alias Ledger.Commands.Balance
  alias Ledger.Repo
  alias Ledger.TestHelpers

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    # Crear usuarios base
    {:ok, usuario1} = TestHelpers.crear_usuario_unico()
    {:ok, usuario2} = TestHelpers.crear_usuario_unico()

    # Crear monedas base
    {:ok, btc} = TestHelpers.crear_moneda_unica(100)
    {:ok, ghr} = TestHelpers.crear_moneda_unica(0.02)

    %{
      usuario1: usuario1,
      usuario2: usuario2,
      btc: btc,
      ghr: ghr
    }
  end

  # Tests
  test "se puede calcular el balance de un alta cuenta con varias transacciones en una misma moneda",
       %{usuario1: usuario1, usuario2: usuario2, btc: btc} do
    # Arrange
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario1.id, btc.nombre, 10)
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario2.id, btc.nombre, 0)
    {:ok, _} = TestHelpers.crear_transferencia(usuario1.id, usuario2.id, btc.id, 10)
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario1.id, btc.nombre, 15)

    # Act
    {:ok, balance} = Balance.get_balance(usuario1)

    # Assert
    esperado = [%{balance: Decimal.new("15.0"), moneda: btc.nombre}]
    assert balance == esperado
  end

  test "se pueden obtener el balance de varias cuentas de un usuario para monedas distintas",
       %{usuario1: usuario1, usuario2: usuario2, btc: btc, ghr: ghr} do
    # Arrange
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario1.id, btc.nombre, 10)
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario2.id, btc.nombre, 0)
    {:ok, _} = TestHelpers.crear_transferencia(usuario1.id, usuario2.id, btc.id, 10)
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario1.id, ghr.nombre, 10)
    {:ok, _} = TestHelpers.crear_swap(usuario1.id, ghr.id, btc.id, 2)

    # Act
    {:ok, balance} = Balance.get_balance(usuario1)

    # Assert
    balance_esperado = [
      %{balance: Decimal.new("0.0004"), moneda: "#{btc.nombre}"},
      %{balance: Decimal.new("8.0"), moneda: "#{ghr.nombre}"}
    ]

    assert balance == balance_esperado
  end

  test "se puede obtener el valor de un balance en una moneda determinada",
       %{usuario1: usuario1, usuario2: usuario2, btc: btc, ghr: ghr} do
    # Arrange
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario1.id, btc.nombre, 10)
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario2.id, btc.nombre, 0)
    {:ok, _} = TestHelpers.crear_transferencia(usuario1.id, usuario2.id, btc.id, 10)
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario1.id, ghr.nombre, 10)
    {:ok, _} = TestHelpers.crear_swap(usuario1.id, ghr.id, btc.id, 2)

    # Act
    {:ok, balance} = Balance.get_balance(usuario1, ghr.id)
    # Assert
    balance_esperado = [
      %{balance: Decimal.new("10.0"), moneda: "#{ghr.nombre}"}
    ]

    assert balance == balance_esperado
  end
end
