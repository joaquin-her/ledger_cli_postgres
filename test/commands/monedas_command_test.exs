defmodule TestCommandMonedas do
  use ExUnit.Case, async: true
  alias Ledger.Commands.Monedas
  alias Ledger.Schemas.Moneda

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
  end

  test "crear moneda" do
    args = %{"-n" => "USDT", "-p" => "1.0"}
    resultado = Monedas.run(:crear, args)

    # Verifica el resultado inmediato
    assert resultado.nombre == "USDT"
    assert resultado.precio_en_usd == 1.0

    # Verifica que se persistió correctamente
    moneda_guardada = Ledger.Repo.get(Moneda, resultado.id)
    assert moneda_guardada.nombre == "USDT"
    assert moneda_guardada.precio_en_usd == 1.0
  end

end
