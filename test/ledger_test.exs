defmodule LedgerTest do
  alias Ledger.TestHelpers
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
      Transacciones.run(:crear, "alta_cuenta", %{"-u" => 1, "-m" => "1", "-a" => 1000.0})

    {:ok, vhs_usuario_2} =
      Transacciones.run(:crear, "alta_cuenta", %{"-u" => 1, "-m" => "2", "-a" => 1000.0})

    {:ok, dolares_usuario_2} =
      Transacciones.run(:crear, "alta_cuenta", %{"-u" => 2, "-m" => "1", "-a" => 500.0})

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
    esperado = "[error] crear_usuario: nombre_usuario: has already been taken\n"
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
    esperado = "[error] ver_usuario: id_invalido: argumento=-id no puede ser negativo\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "una operacion desconocida para un usuario devuelve error" do
    input = ["limpiar_usuario", "-id=1"]
    esperado = "[error] usuario: comando limpiar: no reconocido\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "no usar el flag id en ver usuario imprime error" do
    input = ["ver_usuario", "-d=1"]
    esperado = "[error] ver_usuario: id_invalido: argumento=-id es requerido\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "no se puede crear un usuario menor de 18 años" do
    input = ["crear_usuario", "-n=username", "-b=2014-04-20"]
    esperado = "[error] crear_usuario: fecha_nacimiento: Debe ser mayor de edad\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "-n es necesario para crear un usuario" do
    input = ["crear_usuario", "-b=2004-04-20"]
    esperado = "[error] crear_usuario: nombre_usuario: can't be blank\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "completar mal los 2 campos de crear usuario devuelve ambos errores" do
    input = ["crear_usuario", "-n=", "-b=2014-04-20"]

    esperado =
      "[error] crear_usuario: nombre_usuario: can't be blank; fecha_nacimiento: Debe ser mayor de edad\n"

    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "editar un usuario devuelve la informacion con los campos modificados" do
    input = ["editar_usuario", "-id=1", "-n=joaquin2"]
    esperado = "usuario editado correctamente: id=1, nombre=joaquin2\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "borrar a un usuario devuelve informacion sobre el usuario eliminado" do
    {:ok, usuario3} = TestHelpers.crear_usuario_unico()
    input = ["borrar_usuario", "-id=#{usuario3.id}"]

    esperado =
      "usuario borrado correctamente: id=#{usuario3.id}, nombre=#{usuario3.nombre_usuario}\n"

    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "se notifica cuando no se puede borrar a un usuario" do
    input = ["borrar_usuario", "-id=1"]

    esperado =
      "[error] borrar_usuario: usuario no puede ser eliminado porque tiene transacciones asosciadas\n"

    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "se puede ver la informacion de una moneda correctamente" do
    input = String.split("ver_moneda -id=2")
    esperado = "[info] moneda: id=2, nombre=VHS, precio_en_usd=3.5e3\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "una moneda que no existe muestra un error" do
    input = String.split("ver_moneda -id=12")
    esperado = "[error] ver_moneda: moneda no encontrada\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "se puede crear una moneda y ver su informacion" do
    input = String.split("crear_moneda -n=ABC -p=123.00")
    esperado = "[info][created] moneda: nombre=ABC, precio_en_usd=123.0, id="
    assert capture_io(fn -> CLI.main(input) end) =~ esperado
  end

  test "se puede modificar el valor de una moneda" do
    input = String.split("editar_moneda -id=2 -p=100.0")
    esperado = "[info][updated] moneda: id=2, nombre=VHS, precio_en_usd=100.0\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "se puede borrar una moneda que no tiene cuentas asociadas" do
    {:ok, moneda} = TestHelpers.crear_moneda_unica(100.0)
    input = String.split("borrar_moneda -id=#{moneda.id}")

    esperado =
      "[info][deleted] moneda: nombre=#{moneda.nombre}, precio_en_usd=#{moneda.precio_en_usd}, id=#{moneda.id}"

    assert capture_io(fn -> CLI.main(input) end) =~ esperado
  end

  test "otro comando para moneda devuelve error" do
    input = String.split("aumentar_moneda -id=2")
    esperado = "[error] monedas: aumentar: se desconoce como comando valido\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "alta_cuenta muestra informacion de la cuenta creada" do
    input = String.split("alta_cuenta -u=2 -m=3 -a=110.20")
    esperado = "[info][created] alta_cuenta: id_moneda:3, id_transaccion:"
    assert capture_io(fn -> CLI.main(input) end) =~ esperado
  end

  test "alta_cuenta muestra informacion de un error si surge uno creandose" do
    input = String.split("alta_cuenta -u=2 -m=-10 -a=110.20")
    esperado = "[error] alta_cuenta: id_invalido: argumento=-m no puede ser negativo\n"
    assert capture_io(fn -> CLI.main(input) end) =~ esperado
  end

  test "transacciones subcommand puede mostrar todas las transacciones",
       %{
         dolares_usuario_1: t1,
         vhs_usuario_2: t2,
         dolares_usuario_2: t3,
         transferencia_dolares: t4,
         swap_usuario1: t5
       } do
    input = String.split("transacciones")

    esperado =
      "#{t1.id} | alta_cuenta | 1000 | USDT | USDT | joaquin | joaquin\n#{t2.id} | alta_cuenta | 1000 | VHS | VHS | joaquin | joaquin\n#{t3.id} | alta_cuenta | 500.0 | USDT | USDT | francisco | francisco\n#{t4.id} | transferencia | 100 | USDT | USDT | joaquin | francisco\n#{t5.id} | swap | 50 | USDT | VHS | joaquin | joaquin\n"

    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "transacciones subcommand puede mostrar varias transacciones de un usuario" do
    {:ok, usuario} = TestHelpers.crear_usuario_unico()
    {:ok, t1} = TestHelpers.crear_alta_cuenta(usuario.id, 1, 1000)
    input = String.split("transacciones -id=#{usuario.id}")

    esperado =
      "#{t1.id} | alta_cuenta | 1000 | USDT | USDT | #{usuario.nombre_usuario} | #{usuario.nombre_usuario}\n"

    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "transacciones subcommand puede mostrar errores de ejecucion" do
    {:ok, usuario} = TestHelpers.crear_usuario_unico()
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario.id, 1, 1000)
    input = String.split("transacciones -id=joa")
    esperado = "[error] transacciones: id_invalido: argumento=-id no puede ser una cadena\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "transacciones subcommand puede mostrar una transaccion especifica" do
    {:ok, usuario} = TestHelpers.crear_usuario_unico()
    {:ok, transaccion} = TestHelpers.crear_alta_cuenta(usuario.id, 1, 0)
    input = String.split("ver_transaccion -id=#{transaccion.id}")

    esperado =
      "#{transaccion.id} | alta_cuenta | 0 | USDT | USDT | #{usuario.nombre_usuario} | #{usuario.nombre_usuario}\n"

    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "transacciones subcommand puede mostrar un error al intentar mostrar una transaccion especifica" do
    {:ok, _} = TestHelpers.crear_usuario_unico()
    input = String.split("ver_transaccion -id=-1")
    esperado = "[error] ver_transaccion: id_invalido: argumento=-id no puede ser negativo\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "realizar una transferencia devuelve informacion sobre la transaccion realizada",
       %{usuario1: usuario, usuario2: usuario2} do
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario.id, 1, 0)
    input = String.split("realizar_transferencia -o=#{usuario.id} -d=#{usuario2.id} -m=1 -a=0.5")
    # +1 porque es la que le sigue
    esperado = "| transferencia | 0.5 | USDT | USDT | joaquin | francisco\n"
    assert capture_io(fn -> CLI.main(input) end) =~ esperado
  end

  test "realizar una transferencia con algun error devuelve informacion sobre la equivocacion",
       %{usuario1: usuario, usuario2: usuario2} do
    {:ok, _} = TestHelpers.crear_alta_cuenta(usuario.id, 1, 0)
    input = String.split("realizar_transferencia -o=#{usuario.id} -d=#{usuario2.id} -m=4 -a=0.5")

    esperado =
      "[error] realizar_transferencia: get_cuenta: cuenta de usuario 1 no encontrada para moneda id 4\n"

    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "realizar un comando desconocido muestra un error" do
    input = String.split("bancar_a_boca -o=1 -d=2 -m=4 -a=0.5")
    esperado = "[error] ledgerCLI: Commando desconocido\n"
    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  test "deshacer una transaccion muestra informacion sobre la transaccion realizada",
       %{usuario1: usuario} do
    {:ok, transaccion} = TestHelpers.crear_swap(usuario.id, 1, 2, 0.5)
    input = String.split("deshacer_transaccion -id=#{transaccion.id}")
    esperado = "[info][undo] transaccion swap: id="
    assert capture_io(fn -> CLI.main(input) end) =~ esperado
  end

  test "deshacer una transaccion con un error muestra informacion sobre el error",
       %{dolares_usuario_1: dolares_usuario_1} do
    input = String.split("deshacer_transaccion -id=#{dolares_usuario_1.id}")

    esperado =
      "[error] deshacer_transaccion: No se puede deshacer la transaccion porque no es la ultima realizada por la cuenta de los usuarios\n"

    assert capture_io(fn -> CLI.main(input) end) == esperado
  end

  describe "balance" do
    test "balance en varias monedas se imprime correctamente",
         %{usuario1: usuario} do
      {:ok, _} = TestHelpers.crear_alta_cuenta(usuario.id, 3, 1200)
      input = String.split("balance -id=#{usuario.id}")
      esperado = "USDT | 850.0\nVHS | 1000.014285714285714285\nJOA | 1200.0\n"
      assert capture_io(fn -> CLI.main(input) end) == esperado
    end

    test "balance en una monedas se imprime correctamente",
         %{usuario1: usuario} do
      input = String.split("balance -id=#{usuario.id} -m=4")
      esperado = "PESO | 700180000\n"
      assert capture_io(fn -> CLI.main(input) end) == esperado
    end

    test "balance puede imprimir errores",
         %{usuario1: usuario} do
      input = String.split("balance -id=#{usuario.id} -m=peso")
      esperado = "[error] balance: id_invalido: argumento=-m no puede ser una cadena\n"
      assert capture_io(fn -> CLI.main(input) end) == esperado
    end
  end
end
