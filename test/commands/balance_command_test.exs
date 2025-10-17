defmodule Commands.BalanceCommandTest do
  use ExUnit.Case, async: true
  alias Ledger.Commands.Balance
  alias Ledger.Commands.Transacciones
  alias Ledger.Commands.Monedas
  alias Ledger.Commands.Usuarios

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
  end

  test "se puede calcular el balance de un alta cuenta con varias transacciones en una misma moneda" do
    args_usuario1 = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    args_usuario2 = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    {:ok, usuario1} = Usuarios.run(:crear, args_usuario1)
    {:ok, usuario2} = Usuarios.run(:crear, args_usuario2)

    args_moneda = %{"-n" => "BTC", "-p" => "100.044"}
    {:ok, moneda} = Monedas.run(:crear, args_moneda)

    args_transaccion_1 = %{"-u" => "#{usuario1.id}", "-m" => "#{moneda.nombre}", "-a" => "10"}
    args_transaccion_2 = %{"-o" => "#{usuario1.id}", "-d" => "#{usuario2.id}", "-m" => "#{moneda.id}", "-a" => "10"}
    args_transaccion_3 = %{"-u" => "#{usuario1.id}", "-m" => "#{moneda.nombre}", "-a" => "10"}
    args_transaccion_auxiliar = %{"-u" => "#{usuario2.id}", "-m" => "#{moneda.nombre}", "-a" => "0"}
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_1)
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_auxiliar)

    {:ok, _} = Transacciones.run(:crear, "transferencia", args_transaccion_2)
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_3)

    monto_esperado = Decimal.new("10.0")
    # act
    {:ok, balance} = Balance.run(%{"-u1" => "#{usuario1.id}"})
    esperado = %{balance: monto_esperado, moneda: moneda.nombre}
    assert balance == [esperado]
  end

  test "" do

  end

end
