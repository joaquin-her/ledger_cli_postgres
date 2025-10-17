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

    args_transaccion_2 = %{
      "-o" => "#{usuario1.id}",
      "-d" => "#{usuario2.id}",
      "-m" => "#{moneda.id}",
      "-a" => "10"
    }

    args_transaccion_3 = %{"-u" => "#{usuario1.id}", "-m" => "#{moneda.nombre}", "-a" => "10"}

    args_transaccion_auxiliar = %{
      "-u" => "#{usuario2.id}",
      "-m" => "#{moneda.nombre}",
      "-a" => "0"
    }

    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_1)
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_auxiliar)

    {:ok, _} = Transacciones.run(:crear, "transferencia", args_transaccion_2)
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_3)

    monto_esperado = Decimal.new("10.0")
    # act
    {:ok, balance} = Balance.get_balance(usuario1)
    esperado = %{balance: monto_esperado, moneda: moneda.nombre}
    assert balance == [esperado]
  end

  test "se pueden obtener el balance de varias cuentas de un usuario para monedas distintas" do
    args_usuario1 = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    args_usuario_aux = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    {:ok, usuario1} = Usuarios.run(:crear, args_usuario1)
    {:ok, usuario_aux} = Usuarios.run(:crear, args_usuario_aux)
    args_moneda1 = %{"-n" => "BTC", "-p" => "100"}
    args_moneda2 = %{"-n" => "GHR", "-p" => "0.02"}
    {:ok, moneda1} = Monedas.run(:crear, args_moneda1)
    {:ok, moneda2} = Monedas.run(:crear, args_moneda2)

    args_transaccion_1 = %{"-u" => "#{usuario1.id}", "-m" => "#{moneda1.nombre}", "-a" => "10"}

    args_transaccion_2 = %{
      "-o" => "#{usuario1.id}",
      "-d" => "#{usuario_aux.id}",
      "-m" => "#{moneda1.id}",
      "-a" => "10"
    }

    args_transaccion_3 = %{"-u" => "#{usuario1.id}", "-m" => "#{moneda2.nombre}", "-a" => "10"}

    args_swap = %{
      "-u" => "#{usuario1.id}",
      "-mo" => "#{moneda2.id}",
      "-md" => "#{moneda1.id}",
      "-a" => "2"
    }

    args_transaccion_auxiliar = %{
      "-u" => "#{usuario_aux.id}",
      "-m" => "#{moneda1.nombre}",
      "-a" => "0"
    }

    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_1)
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_auxiliar)
    {:ok, _} = Transacciones.run(:crear, "transferencia", args_transaccion_2)
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_3)
    {:ok, _} = Transacciones.run(:crear, "swap", args_swap)

    balance_esperado = [
      %{
        # 2* 0.02 /100
        balance: Decimal.new("0.0004"),
        moneda: "BTC"
      },
      %{
        balance: Decimal.new("8.0"),
        moneda: "GHR"
      }
    ]

    IO.inspect(usuario1)
    {:ok, balance} = Balance.get_balance(usuario1)
    assert balance == balance_esperado
  end

  test "se puede obtener el valor de un balance en una moneda determinada" do
    # misma secuencia que la anterior
    args_usuario1 = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    args_usuario_aux = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    {:ok, usuario1} = Usuarios.run(:crear, args_usuario1)
    {:ok, usuario_aux} = Usuarios.run(:crear, args_usuario_aux)
    args_moneda1 = %{"-n" => "BTC", "-p" => "100"}
    args_moneda2 = %{"-n" => "GHR", "-p" => "0.02"}
    {:ok, moneda1} = Monedas.run(:crear, args_moneda1)
    {:ok, moneda2} = Monedas.run(:crear, args_moneda2)

    args_transaccion_1 = %{"-u" => "#{usuario1.id}", "-m" => "#{moneda1.nombre}", "-a" => "10"}

    args_transaccion_2 = %{
      "-o" => "#{usuario1.id}",
      "-d" => "#{usuario_aux.id}",
      "-m" => "#{moneda1.id}",
      "-a" => "10"
    }

    args_transaccion_3 = %{"-u" => "#{usuario1.id}", "-m" => "#{moneda2.nombre}", "-a" => "10"}

    args_swap = %{
      "-u" => "#{usuario1.id}",
      "-mo" => "#{moneda2.id}",
      "-md" => "#{moneda1.id}",
      "-a" => "2"
    }

    args_transaccion_auxiliar = %{
      "-u" => "#{usuario_aux.id}",
      "-m" => "#{moneda1.nombre}",
      "-a" => "0"
    }

    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_1)
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_auxiliar)
    {:ok, _} = Transacciones.run(:crear, "transferencia", args_transaccion_2)
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args_transaccion_3)
    {:ok, _} = Transacciones.run(:crear, "swap", args_swap)

    balance_esperado = [
      %{
        # 2* 0.02 /100 + 8* 0.02 / 100
        balance: Decimal.new("0.0020"),
        moneda: "BTC"
      }
    ]

    IO.inspect(usuario1)
    {:ok, balance} = Balance.get_balance(usuario1, moneda1.id)
    assert balance == balance_esperado
  end
end
