defmodule Ledger.Commands.Cuentas do
  alias Ledger.Commands.Transacciones
  alias Ledger.Schemas.Cuenta
  alias Ledger.Commands.Utils
  import Ecto.Query

  @doc """
  args:
  ["-id"]: str (id del usuario)
  ["-m"]:str (id de la moneda)
  """
  def run(:alta, args) do
    {id_moneda,_} = Integer.parse(args["-m"])
    {id_usuario,_} = Integer.parse(args["-id"])
    cuenta = %{
      moneda_id: id_moneda ,
      usuario_id: id_usuario
    }
    Cuenta.changeset(%Cuenta{}, cuenta)
    |> Ledger.Repo.insert()
    |> case do
      {:ok, cuenta} ->
        {:ok, cuenta}
      {:error, changeset} ->
        {:error, "crear_cuenta: #{Utils.format_errors(changeset)}"}
    end
  end

  def get_monto(id_cuenta) do
    # validate_id(id_cuenta)
    # obtener de :transacciones todas las operaciones con la cuenta de id: :id_cuenta y devolver el total
    query_ingreso = from( t in Ledger.Schemas.Transaccion,
      where: t.cuenta_origen_id == ^id_cuenta,
      select: sum(t.monto))

    query_salida = from( t in Ledger.Schemas.Transaccion,
      where: t.cuenta_destino_id == ^id_cuenta,
      select: sum(t.monto))

    entrada = Ledger.Repo.one(query_ingreso) || Decimal.new("0")
    salida = Ledger.Repo.one(query_salida) || Decimal.new("0")

    saldo = Decimal.sub(entrada,salida)
    {:ok, saldo}
#    {:ok, result} ->
#      {:ok, result}
#    {:error, error} ->
#      {:error, "get_monto: #{error}"}

  end


end
