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
    Ledger.Repo.insert!(%Moneda{id: 2, nombre: "VHS", precio_en_usd: 3500.0})
    Ledger.Repo.insert!(%Moneda{id: 3, nombre: "JOA", precio_en_usd: 1500.0})
    Ledger.Repo.insert!(%Moneda{id: 4, nombre: "PESO", precio_en_usd: 0.005})

    # Insertar usuarios
    usuario1 =
      Ledger.Repo.insert!(%Ledger.Schemas.Usuario{
        id: 1,
        nombre_usuario: "joaquin",
        fecha_nacimiento: ~D[2001-11-01]
      })

    usuario2 =
      Ledger.Repo.insert!(%Ledger.Schemas.Usuario{
        id: 2,
        nombre_usuario: "francisco",
        fecha_nacimiento: ~D[1999-05-01]
      })

    # Crear cuentas para los usuarios
    {:ok, dolares_usuario_1} =
      Transacciones.run(:crear, "alta_cuenta", %{"-u" => 1, "-m" => "USDT", "-a" => 1000.0})

    {:ok, vhs_usuario_2} =
      Transacciones.run(:crear, "alta_cuenta", %{"-u" => 1, "-m" => "VHS", "-a" => 1000.0})

    {:ok, dolares_usuario_2} =
      Transacciones.run(:crear, "alta_cuenta", %{"-u" => 2, "-m" => "USDT", "-a" => 500.0})

    # Crear transacciones
    {:ok, transferencia_dolares} =
      Transacciones.run(:crear, "transferencia", %{"-o" => 1, "-d" => 2, "-m" => 1, "-a" => 100})

    {:ok, swap_usuario1} =
      Transacciones.run(:crear, "swap", %{"-u" => 1, "-mo" => 1, "-md" => 2, "-a" => 50})

    %{
      usuario1: usuario1,
      usuario2: usuario2,
      transferencia_dolares: transferencia_dolares,
      swap_usuario1: swap_usuario1,
      dolares_usuario_1: dolares_usuario_1,
      dolares_usuario_2: dolares_usuario_2,
      vhs_usuario_2: vhs_usuario_2
    }
  end

  # ============== Usuarios ================
  test "un usuario nuevo se crea correctamente" do
    input = ["crear_usuario", "-n=roberto", "-b=2001-11-01"]
    esperado = "usuario creado correctamente: id="
    assert capture_io(fn -> CLI.main(input) end) =~ esperado
  end

  test "un usuario existente no se puede crear nuevamente" do
    input = ["crear_usuario", "-n=joaquin", "-b=2002-11-01"]
    esperado = "error: crear_usuario: nombre_usuario: has already been taken\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "un usuario existente se puede ver",
       %{usuario1: usuario1} do
    input = ["ver_usuario", "-id=#{usuario1.id}"]

    esperado =
      "usuario: id: #{usuario1.id}, nombre: #{usuario1.nombre_usuario}, birthdate: #{usuario1.fecha_nacimiento}\n"

    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "un usuario existente no se puede ver si se pasa mal el id" do
    input = ["ver_usuario", "-id=-1"]
    esperado = "error: ver_usuario: id_invalido: argumento=-id no puede ser negativo\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "una operacion desconocida para un usuario devuelve error" do
    input = ["limpiar_usuario", "-id=1"]
    esperado = "error: usuario: comando limpiar: no reconocido\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "no usar el flag id en ver usuario imprime error" do
    input = ["ver_usuario", "-d=1"]
    esperado = "error: ver_usuario: id_invalido: argumento=-id es requerido\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "no se puede crear un usuario menor de 18 años" do
    input = ["crear_usuario", "-n=username", "-b=2014-04-20"]
    esperado = "error: crear_usuario: fecha_nacimiento: Debe ser mayor de edad\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "-n es necesario para crear un usuario" do
    input = ["crear_usuario", "-b=2004-04-20"]
    esperado = "error: crear_usuario: nombre_usuario: can't be blank\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "completar mal los 2 campos de crear usuario devuelve ambos errores" do
    input = ["crear_usuario", "-n=", "-b=2014-04-20"]

    esperado =
      "error: crear_usuario: nombre_usuario: can't be blank; fecha_nacimiento: Debe ser mayor de edad\n"

    assert capture_io(fn -> CLI.main(input) end) == esperado
  end
end
