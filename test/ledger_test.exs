defmodule LedgerTest do
  alias Ledger.Commands.Transacciones
  alias Ledger.Schemas.Moneda
  alias Ledger.Schemas.Transaccion
  alias Ledger.Schemas.Usuario
  alias Ledger.Schemas.Cuenta
  alias Ledger.CLI

  use ExUnit.Case
  import ExUnit.CaptureIO

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})

    # Limpiar base
    Ledger.Repo.delete_all(Transaccion)
    Ledger.Repo.delete_all(Usuario)
    Ledger.Repo.delete_all(Moneda)
    Ledger.Repo.delete_all(Cuenta)

    # Insertar monedas
    Ledger.Repo.insert!(%Moneda{id: 1, nombre: "USDT", precio_en_usd: 1.0})
    Ledger.Repo.insert!(%Moneda{id: 2, nombre: "BTC", precio_en_usd: 3500.0})
    Ledger.Repo.insert!(%Moneda{id: 3, nombre: "ETH", precio_en_usd: 1500.0})
    Ledger.Repo.insert!(%Moneda{id: 4, nombre: "PESO", precio_en_usd: 0.005})

    # Insertar usuarios
    Ledger.Repo.insert!(%Ledger.Schemas.Usuario{
      id: 1,
      nombre_usuario: "joaquin",
      fecha_nacimiento: ~D[2001-11-01]
    })

    Ledger.Repo.insert!(%Ledger.Schemas.Usuario{
      id: 2,
      nombre_usuario: "francisco",
      fecha_nacimiento: ~D[1999-05-01]
    })

    # Crear cuentas para los usuarios
    {:ok, _} =
      Transacciones.run(:crear, "alta_cuenta", %{"-u" => 1, "-m" => "USDT", "-a" => 1000.0})

    {:ok, _} =
      Transacciones.run(:crear, "alta_cuenta", %{"-u" => 1, "-m" => "BTC", "-a" => 1000.0})

    {:ok, _} =
      Transacciones.run(:crear, "alta_cuenta", %{"-u" => 2, "-m" => "USDT", "-a" => 500.0})

    # Crear transacciones
    {:ok, _} =
      Transacciones.run(:crear, "transferencia", %{"-o" => 1, "-d" => 2, "-m" => 1, "-a" => 100})

    {:ok, _} = Transacciones.run(:crear, "swap", %{"-u" => 1, "-mo" => 1, "-md" => 2, "-a" => 50})

    :ok
  end

  test "un usuario nuevo se crea correctamente" do
    input = ["crear_usuario", "-n=roberto", "-b=2001-11-01"]
    esperado = "usuario creado correctamente: id="
    assert capture_io(fn -> CLI.main(input) end) =~ esperado
  end

  test "un usuario existente no se puede crear nuevamente" do
    input = ["crear_usuario", "-n=joaquin", "-b=2002-11-01"]
    esperado = "error: crear_usuario: nombre_usuario: has already been taken\n"
    assert capture_io(fn -> CLI.main(input) end) =~ esperado
  end

  test "un usuario existente se puede ver" do
    input = ["ver_usuario", "-id=1"]
    esperado = "usuario: id: 1, nombre: joaquin, birthdate: 2001-11-01\n"
    assert capture_io(fn -> CLI.main(input) end) =~ esperado
  end
end
