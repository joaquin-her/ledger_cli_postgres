defmodule TestCommandMonedas do
  use ExUnit.Case, async: true
  alias Ledger.Commands.Monedas
  alias Ledger.Schemas.Moneda

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
  end

  test "crear moneda" do
    args = %{"-n" => "USDT", "-p" => "1.0"}
    {status, resultado} = Monedas.run(:crear, args)

    # Verifica el resultado inmediato
    assert resultado.nombre == "USDT"
    assert resultado.precio_en_usd == 1.0
    assert status == :ok
    # Verifica que se persistió correctamente
    moneda_guardada = Ledger.Repo.get(Moneda, resultado.id)
    assert moneda_guardada.nombre == "USDT"
    assert moneda_guardada.precio_en_usd == 1.0
  end

  test "ingresar moneda con nombre de mas de 4 letras da error " do
    args = %{"-n" => "dolar", "-p" => "1.0"}
    error = {:error, "crear_usuario: nombre: should be at most 4 character(s)"}
    assert Monedas.run(:crear, args)  == error
  end
end
