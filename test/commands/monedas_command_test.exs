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
    assert moneda_guardada.inserted_at != nil
  end

  test "ingresar moneda con nombre de mas de 4 letras da error " do
    args = %{"-n" => "dolar", "-p" => "1.0"}
    error = {:error, "crear_usuario: nombre: should be at most 4 character(s)"}
    assert Monedas.run(:crear, args)  == error
  end

  test "ingresar moneda con nombre de menos de 3 letras da error " do
    args = %{"-n" => "US", "-p" => "1.0"}
    error = {:error, "crear_usuario: nombre: should be at least 3 character(s)"}
    assert Monedas.run(:crear, args)  == error
  end

  test "ingresar moneda con precio negativo da error " do
    args = %{"-n" => "USDT", "-p" => "-1.0"}
    error = {:error, "crear_usuario: precio_en_usd: must be greater than 0"}
    assert Monedas.run(:crear, args)  == error
  end

  test "ingresar moneda con precio 0 da error " do
    args = %{"-n" => "USDT", "-p" => "0.0"}
    error = {:error, "crear_usuario: precio_en_usd: must be greater than 0"}
    assert Monedas.run(:crear, args)  == error
  end

  test "ingresar moneda con nombre repetido genera error" do
    args = %{"-n" => "BTC", "-p" => "3600.0"}
    Monedas.run(:crear, args)
    args = %{"-n" => "BTC", "-p" => "2500.0"}
    error = {:error, "crear_usuario: nombre: has already been taken"}
    assert Monedas.run(:crear, args) == error
  end

  test "ingresar moneda con nombre vacio genera error" do
    args = %{"-n" => "", "-p" => "3600.0"}
    error = {:error, "crear_usuario: nombre: can't be blank"}
    assert Monedas.run(:crear, args) == error
  end

  test "ingresar moneda con timestamp de creacion" do
    args = %{"-n" => "ETH", "-p" => "2000.0"}
    {status, moneda} = Monedas.run(:crear, args)
    resultado = Ledger.Repo.get( Moneda, moneda.id)
    assert not is_nil(resultado.inserted_at )
  end
end
