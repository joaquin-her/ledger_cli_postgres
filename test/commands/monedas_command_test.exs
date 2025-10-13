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
    assert status == :ok
    assert not is_nil(resultado.inserted_at )
  end

  # Modificar moneda
  test "modificar precio de moneda = :ok" do
    argumentos_creacion = %{"-n" => "ETH", "-p" => "3600.0"}
    {_, moneda} = Monedas.run(:crear, argumentos_creacion)
    argumentos_modificacion  = %{"-id" => "#{moneda.id}", "-p" => "2000.0"}
    {status, moneda} = Monedas.run(:editar, argumentos_modificacion)
    assert status == :ok
    assert moneda.precio_en_usd == 2000.0
  end

  test "modificar id de moneda no existe = :error,msg" do
    argumentos_modificacion  = %{"-id" => "999", "-p" => "3.0"}
    {status, error} = Monedas.run(:editar, argumentos_modificacion)
    assert status == :error
    assert error == "editar_moneda: moneda no encontrada"
  end

  test "modificar precio de moneda con valor invalido = :error" do
    argumentos_creacion = %{"-n" => "ETH", "-p" => "3600.0"}
    {_, moneda} = Monedas.run(:crear, argumentos_creacion)
    argumentos_modificacion  = %{"-id" => "#{moneda.id}", "-p" => "invalid_value"}
    {status, error} = Monedas.run(:editar, argumentos_modificacion)
    assert status == :error
    assert error == "editar_moneda: precio_en_usd: is invalid"
  end

  test "modificar precio de una moneda con un id invalido = :error" do
    argumentos_modificacion  = %{"-id" => "invalid_value", "-p" => "10.0"}
    {status, error} = Monedas.run(:editar, argumentos_modificacion)
    assert status == :error
    assert error == "editar_moneda: id: is invalid"
  end
end
