defmodule Ledger.Commands.Transacciones do
  alias Ledger.Commands.Cuentas
  alias Ledger.Schemas.Moneda
  alias Ledger.Schemas.Cuenta
  alias Ledger.Schemas.Transaccion
  alias Ledger.Commands.Utils
  import Ecto.Query

  @doc """
  ## Crear
   "tipos validos: SWAP, TRANSACCION, ALTA_CUENTA"
  "ALTA_CUENTA" =
      nombre_moneda = args["-m"]
      id_usuario = args["-u"]
  args:

  """
  def run( :crear, tipo, args) do
    case tipo do
      "swap" ->
        swap( :crear, args)
      "transaccion" ->
        transaccion( :crear, args)
      "alta_cuenta" ->
        alta_cuenta(:crear, args)
      _ ->
        {:error, "subcommando no encontrado"}
    end
  end

  def run( :borrar, tipo, args) do
    case tipo do
      "swap" ->
        swap( :borrar, args)
      "transaccion" ->
        transaccion( :borrar, args)
      _ ->
        {:error, "subcommando no encontrado"}
    end
  end

  def run(_,_,_) do
    {:error, "subcommando no encontrado"}
  end
  @doc """
  ## :Crear
  -u: usuario_id
  -mo: moneda_origen_id
  -md: moneda_destino_id
  -a: monto
  """
  defp swap( :crear, args) do
    {:ok, cuenta_origen} = Cuentas.run(:ver, %{"-u" => args["-u"], "-m"=>args["-mo"]})
    {:ok, cuenta_destino} = Cuentas.run(:ver, %{"-u" => args["-u"], "-m"=>args["-md"]})
    swap = %{
      tipo: "swap",
      moneda_origen_id: args["-mo"],
      moneda_destino_id: args["-md"],
      cuenta_origen_id: cuenta_origen.id,
      cuenta_destino_id: cuenta_destino.id,
      monto: args["-a"]
    }
    IO.inspect(swap)
    swap
    |> Transaccion.changeset_swap()
    |> insertar_transaccion("swap")
  end
  defp swap( :borrar, _) do

  end
  defp swap( _, _) do
    {:error, "subcommando no encontrado"}
  end

  defp alta_cuenta(:crear, args) do
    nombre_moneda = args["-m"]
    id_usuario = args["-u"]
    monto = args["-a"]
    # si ya existe la cuenta (ya haya en Cuentas una con [:id_usuario, :id_moneda] donde :id_moneda in :monedas and :mismo_nombre):
    # agregamos solo la transaccion alta_cuenta con los campos requeridos
    # si hay match, entonces significa que existe cuenta en esa moneda
    query_id_moneda = from m in Moneda, where: m.nombre == ^nombre_moneda, select: m.id
    id_moneda = Ledger.Repo.one(query_id_moneda)
    #IO.inspect(id_moneda)
    query_cuenta_origen = from c in Cuenta, where: c.usuario_id == ^id_usuario and c.moneda_id == ^id_moneda, select: c
    cuenta = Ledger.Repo.one(query_cuenta_origen)
    case cuenta do
      nil ->
      args = %{"-id"=>"#{id_usuario}" , "-m"=>"#{id_moneda}" }
      Cuentas.run(:alta, args)
      |> case do
        {:ok, _} ->
          alta_cuenta(:crear, %{"-m" =>"#{nombre_moneda}", "-u"=>"#{id_usuario}", "-a"=>monto})
        {:error, error} ->
          {:error, error}
        _ ->
          {:error, "error"}
      end
      _ ->
      transaccion = %{
        cuenta_origen_id: cuenta.id,
        moneda_origen_id: id_moneda,
        tipo: "alta_cuenta",
        monto: monto
      }
      Transaccion.changese_alta_cuenta( %Transaccion{} , transaccion)
      |> insertar_transaccion( "alta_cuenta")

    end

    #IO.puts("Cuenta matcheada: ")
    # si no existe: llamamos a Cuentas.run(:alta, args) y con lo que nos devuelve, hacemos la transaccion alta_cuenta con los campos requeridos
  end

  defp transaccion( :crear, _) do

  end

  defp transaccion( :borrar, _) do

  end
  defp transaccion( _, _) do
    {:error, "subcommando no encontrado"}
  end

  defp insertar_transaccion(transaccion, funcion) do
    case Ledger.Repo.insert( transaccion) do
      {:ok, transaccion} ->
        {:ok, transaccion}
      {:error, changeset} ->
        {:error, "#{funcion}: #{Utils.format_errors(changeset)}"}
    end
  end

end
