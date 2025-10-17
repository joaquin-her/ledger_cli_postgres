defmodule Commands.BalanceCommandTest do
  use ExUnit.Case, async: true
  alias Ledger.Commands.Balance
  alias Ledger.Commands.Transacciones
  alias Ledger.Commands.Monedas
  alias Ledger.Commands.Usuarios

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
  end

  test "se puede calcular el balance de un alta cuenta" do
    args_usuario = %{"-n" => Faker.Pokemon.En.name(), "-b" => Faker.Date.date_of_birth()}
    {:ok, usuario} = Usuarios.run(:crear, args_usuario)
    args_moneda = %{"-n" => "BTC", "-p" => "100.044"}
    {:ok, moneda} = Monedas.run(:crear, args_moneda)
    args = %{"-u" => "#{usuario.id}", "-m" => "#{moneda.nombre}", "-a" => "15"}
    {:ok, _} = Transacciones.run(:crear, "alta_cuenta", args)
    esperado = moneda.precio_en_usd * 15
    # act
    {:ok, balance} = Balance.run(%{"-u1" => "#{usuario.id}"})
    assert balance == esperado
  end
end
