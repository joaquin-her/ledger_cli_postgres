defmodule TestCommandMonedas do
  use ExUnit.Case, async: true
  alias Ledger.Commands.Usuarios
  alias Ledger.Commands.Transacciones
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

  test "obtener moneda existente = :ok" do
    args = %{"-n" => "USDT", "-p" => "1.0"}
    {_, resultado} = Monedas.run(:crear, args)
    {status, moneda} = Monedas.run(:ver, %{"-id" => "#{resultado.id}"})
    assert status == :ok
    assert moneda.nombre == "USDT"
    assert moneda.precio_en_usd == 1.0
  end

  test "obtener moneda inexistente = :error" do
    {status, mensaje} = Monedas.run(:ver, %{"-id" => "999"})
    esperado = "ver_moneda: moneda no encontrada"
    assert status == :error
    assert mensaje == esperado
  end

  test "ingresar moneda con nombre de mas de 4 letras da error " do
    args = %{"-n" => "dolar", "-p" => "1.0"}
    error = {:error, "crear_usuario: nombre: should be at most 4 character(s)"}
    assert Monedas.run(:crear, args) == error
  end

  test "ingresar moneda con nombre de menos de 3 letras da error " do
    args = %{"-n" => "US", "-p" => "1.0"}
    error = {:error, "crear_usuario: nombre: should be at least 3 character(s)"}
    assert Monedas.run(:crear, args) == error
  end

  test "ingresar moneda con precio negativo da error " do
    args = %{"-n" => "USDT", "-p" => "-1.0"}
    error = {:error, "crear_usuario: precio_en_usd: must be greater than 0"}
    assert Monedas.run(:crear, args) == error
  end

  test "ingresar moneda con precio 0 da error " do
    args = %{"-n" => "USDT", "-p" => "0.0"}
    error = {:error, "crear_usuario: precio_en_usd: must be greater than 0"}
    assert Monedas.run(:crear, args) == error
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
    resultado = Ledger.Repo.get(Moneda, moneda.id)
    assert status == :ok
    assert not is_nil(resultado.inserted_at)
  end

  # Modificar moneda
  test "modificar precio de moneda = :ok" do
    argumentos_creacion = %{"-n" => "ETH", "-p" => "3600.0"}
    {_, moneda} = Monedas.run(:crear, argumentos_creacion)
    argumentos_modificacion = %{"-id" => "#{moneda.id}", "-p" => "2000.0"}
    {status, moneda} = Monedas.run(:editar, argumentos_modificacion)
    moneda_modificada = Ledger.Repo.get(Moneda, moneda.id)
    assert status == :ok
    assert moneda_modificada.precio_en_usd == 2000.0
  end

  test "modificar id de moneda no existe = :error,msg" do
    argumentos_modificacion = %{"-id" => "999", "-p" => "3.0"}
    {status, error} = Monedas.run(:editar, argumentos_modificacion)
    assert status == :error
    assert error == "editar_moneda: moneda no encontrada"
  end

  test "modificar precio de moneda con valor negativo = :error" do
    argumentos_creacion = %{"-n" => "ETH", "-p" => "3600.0"}
    {_, moneda} = Monedas.run(:crear, argumentos_creacion)
    argumentos_modificacion = %{"-id" => "#{moneda.id}", "-p" => "-20"}
    {status, error} = Monedas.run(:editar, argumentos_modificacion)
    assert status == :error
    assert error == "editar_moneda: precio_en_usd: must be greater than 0"
  end

  test "modificar precio de moneda con valor invalido = :error" do
    argumentos_creacion = %{"-n" => "ETH", "-p" => "3600.0"}
    {_, moneda} = Monedas.run(:crear, argumentos_creacion)
    argumentos_modificacion = %{"-id" => "#{moneda.id}", "-p" => "invalid_value"}
    {status, error} = Monedas.run(:editar, argumentos_modificacion)
    assert status == :error
    assert error == "editar_moneda: precio_en_usd: is invalid"
  end

  test "modificar precio de una moneda con un id invalido = :error" do
    argumentos_modificacion = %{"-id" => "invalid_value", "-p" => "10.0"}
    {status, error} = Monedas.run(:editar, argumentos_modificacion)
    assert status == :error
    assert error == "editar_moneda: id_invalido: argumento=-id no puede ser una cadena"
  end

  test "modificar una moneda cambia su campo updated_at" do
    # inicial
    argumentos_creacion = %{"-n" => "ETH", "-p" => "3600.0"}
    {_, moneda} = Monedas.run(:crear, argumentos_creacion)
    updated_at_before = moneda.updated_at
    # modifica la moneda
    argumentos_modificacion = %{"-id" => "#{moneda.id}", "-p" => "2500.0"}
    {status, moneda} = Monedas.run(:editar, argumentos_modificacion)
    assert status == :ok
    assert updated_at_before < moneda.updated_at
  end

  # borrado de monedas
  test "borrar una moneda existente" do
    # Crear moneda
    argumentos_creacion = %{"-n" => "ETH", "-p" => "3600.0"}
    {:ok, moneda} = Monedas.run(:crear, argumentos_creacion)

    # borrar
    argumentos_eliminacion = %{"-id" => "#{moneda.id}"}
    {:ok, moneda_eliminada} = Monedas.run(:borrar, argumentos_eliminacion)

    # Verificar que se eliminó
    assert moneda_eliminada.id == moneda.id
    assert Ledger.Repo.get(Moneda, moneda.id) == nil
  end

  test "borrar una moneda que no existe retorna error" do
    argumentos_eliminacion = %{"-id" => "99999"}
    esperado = "borrar_moneda: moneda no encontrada"
    {status, mensaje} = Monedas.run(:borrar, argumentos_eliminacion)
    assert status == :error
    assert mensaje == esperado
  end

  # Test con refetch para confirmar
  test "borrar una moneda la remueve de la base de datos" do
    {:ok, moneda} = Monedas.run(:crear, %{"-n" => "BTC", "-p" => "50000.0"})
    id = moneda.id

    # Confirmar que existe
    assert Ledger.Repo.get(Moneda, id) != nil

    # borrar
    {:ok, _} = Monedas.run(:borrar, %{"-id" => "#{id}"})

    # Confirmar que ya no existe
    refute Ledger.Repo.get(Moneda, id)
  end

  # Test con conteo de registros
  test "borrar reduce el conteo de monedas" do
    {:ok, moneda} = Monedas.run(:crear, %{"-n" => "ADA", "-p" => "1.50"})

    count_before = Ledger.Repo.aggregate(Moneda, :count, :id)
    {:ok, _} = Monedas.run(:borrar, %{"-id" => "#{moneda.id}"})
    count_after = Ledger.Repo.aggregate(Moneda, :count, :id)

    assert count_after == count_before - 1
  end

  test "no se puede borrar una moneda asociada a una transaccion en transferencias " do
    {:ok, moneda} = Monedas.run(:crear, %{"-n" => "ADA", "-p" => "1.50"})
    {:ok, usuario} = Usuarios.run(:crear, %{"-n" => "pepe_22", "-b" => "2001-01-11"})

    {:ok, _} =
      Transacciones.run(:crear, "alta_cuenta", %{
        "-m" => "#{moneda.id}",
        "-u" => "#{usuario.id}",
        "-a" => "10"
      })

    {status, mensaje} = Monedas.run(:borrar, %{"-id" => "#{moneda.id}"})
    assert status == :error

    assert mensaje ==
             "borrar_moneda: no se puede borrar una moneda asociada a una/varias transacciones"
  end

  test "un comando desconocido devuelve un mensaje de error" do
    {:error, mensaje} = Monedas.run(:incrementar, %{"-n" => "ADA", "-p" => "1.50"})

    esperado = "monedas: incrementar: se desconoce como comando valido"
    assert esperado == mensaje
  end
end
