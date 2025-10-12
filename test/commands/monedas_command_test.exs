defmodule TestCommandMonedas do
  use ExUnit.Case, async: true
  alias Ledger.Commands.Monedas
  alias Ledger.Schemas.Moneda

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
  end

  test "crear moneda" do
    esperado = %Moneda{nombre: "USDT", precio_en_usd: 1.0}
    args = %{"-n" => "USDT", "-p" => "1.0"}
    resultado = Monedas.run( :crear, args )
    assert esperado == resultado
  end

end
