defmodule Commands.BalanceCommandTest do
  use ExUnit.Case, async: true
  alias Ledger.Commands.Balance
  alias Ledger.Commands.Transacciones
  alias Ledger.Commands.Monedas
  alias Ledger.Commands.Usuarios

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)

    # Crear usuarios base
    {:ok, usuario1} = crear_usuario_random()
    {:ok, usuario2} = crear_usuario_random()

    # Crear monedas base
    {:ok, btc} = Monedas.run(:crear, %{"-n" => "BTC", "-p" => "100"})
    {:ok, ghr} = Monedas.run(:crear, %{"-n" => "GHR", "-p" => "0.02"})

    %{
      usuario1: usuario1,
      usuario2: usuario2,
      btc: btc,
      ghr: ghr
    }
  end
  # Helpers
  defp crear_usuario_random do
    args = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    Usuarios.run(:crear, args)
  end

  defp crear_alta_cuenta(usuario_id, moneda_nombre, monto) do
    Transacciones.run(:crear, "alta_cuenta", %{
      "-u" => "#{usuario_id}",
      "-m" => "#{moneda_nombre}",
      "-a" => "#{monto}"
    })
  end

  defp crear_transferencia(origen_id, destino_id, moneda_id, monto) do
    Transacciones.run(:crear, "transferencia", %{
      "-o" => "#{origen_id}",
      "-d" => "#{destino_id}",
      "-m" => "#{moneda_id}",
      "-a" => "#{monto}"
    })
  end

  defp crear_swap(usuario_id, moneda_origen_id, moneda_destino_id, monto) do
    Transacciones.run(:crear, "swap", %{
      "-u" => "#{usuario_id}",
      "-mo" => "#{moneda_origen_id}",
      "-md" => "#{moneda_destino_id}",
      "-a" => "#{monto}"
    })
  end
  # Tests
  test "se puede calcular el balance de un alta cuenta con varias transacciones en una misma moneda",
       %{usuario1: usuario1, usuario2: usuario2, btc: btc} do
    # Arrange
    {:ok, _} = crear_alta_cuenta(usuario1.id, btc.nombre, 10)
    {:ok, _} = crear_alta_cuenta(usuario2.id, btc.nombre, 0)
    {:ok, _} = crear_transferencia(usuario1.id, usuario2.id, btc.id, 10)
    {:ok, _} = crear_alta_cuenta(usuario1.id, btc.nombre, 10)

    # Act
    {:ok, balance} = Balance.get_balance(usuario1)

    # Assert
    esperado = [%{balance: Decimal.new("10.0"), moneda: btc.nombre}]
    assert balance == esperado
  end

  test "se pueden obtener el balance de varias cuentas de un usuario para monedas distintas",
       %{usuario1: usuario1, usuario2: usuario2, btc: btc, ghr: ghr} do
    # Arrange
    {:ok, _} = crear_alta_cuenta(usuario1.id, btc.nombre, 10)
    {:ok, _} = crear_alta_cuenta(usuario2.id, btc.nombre, 0)
    {:ok, _} = crear_transferencia(usuario1.id, usuario2.id, btc.id, 10)
    {:ok, _} = crear_alta_cuenta(usuario1.id, ghr.nombre, 10)
    {:ok, _} = crear_swap(usuario1.id, ghr.id, btc.id, 2)

    # Act
    {:ok, balance} = Balance.get_balance(usuario1)

    # Assert
    balance_esperado = [
      %{balance: Decimal.new("0.0004"), moneda: "BTC"},
      %{balance: Decimal.new("8.0"), moneda: "GHR"}
    ]
    assert balance == balance_esperado
  end

  test "se puede obtener el valor de un balance en una moneda determinada",
       %{usuario1: usuario1, usuario2: usuario2, btc: btc, ghr: ghr} do
    # Arrange
    {:ok, _} = crear_alta_cuenta(usuario1.id, btc.nombre, 10)
    {:ok, _} = crear_alta_cuenta(usuario2.id, btc.nombre, 0)
    {:ok, _} = crear_transferencia(usuario1.id, usuario2.id, btc.id, 10)
    {:ok, _} = crear_alta_cuenta(usuario1.id, ghr.nombre, 10)
    {:ok, _} = crear_swap(usuario1.id, ghr.id, btc.id, 2)

    # Act
    {:ok, balance} = Balance.get_balance(usuario1, btc.id)

    # Assert
    balance_esperado = [
      %{balance: Decimal.new("0.0020"), moneda: "BTC"}
    ]
    assert balance == balance_esperado
  end
end
