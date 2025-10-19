defmodule Ledger.Commands.Balance do
  # alias Ledger.Commands.Transacciones
  alias Ledger.Commands.Monedas
  alias Ledger.Schemas.Usuario
  alias Ledger.Schemas.Cuenta
  alias Ledger.Schemas.Moneda
  alias Ledger.Commands.Utils

  import Ecto.Query

  @doc """
  Devuelve el monto de todas las cuentas de un usuario segun las transferencias que tenga asociada en Transacciones
  """
  def get_balance(args) do
    with {:ok, id_usuario} <- Utils.validate_id(args["-id"], "-id") do
      balance = get_balances_totales(id_usuario)
      case Utils.validate_id(args["-m"], "-m") do
        # tengo id usuario y id moneda
        {:ok, id_moneda_conversion} ->
          moneda = Ledger.Repo.get(Moneda, id_moneda_conversion)
          balance =
            balance
            |> convertir_balance_a_precio_id_moneda_conversion(moneda)
            |> reduce_balances()
            |> Map.put(:moneda, moneda.nombre)
          {:ok, [balance]}

        # tengo id usuario y id moneda es invalido
        {:error, mensaje} ->
          if args["-m"] do
            {:error, "balance: #{mensaje}"}
          else
            balance =
              Enum.map(balance, fn b ->
                %{
                  balance: b.balance,
                  moneda: b.moneda
                }
              end)
            {:ok, balance}
          end
      end
    end
  end

  defp get_balances_totales(id_usuario) do
    Cuenta
    |> join(:inner, [c], u in Usuario, on: c.usuario_id == u.id)
    |> where([c, u], u.id == ^id_usuario)
    |> join(:inner, [c, u], m in Moneda, on: c.moneda_id == m.id)
    |> select([c, u, m], %{
      id: m.id,
      moneda: m.nombre,
      balance: c.cantidad
    })
    |> Ledger.Repo.all()
  end

  def convertir_balance_a_precio_id_moneda_conversion(balances, moneda) do
    Enum.map(balances, fn b ->
      convertido = Monedas.convertir(Decimal.to_float(b.balance), b.id, moneda.id)
      %{balance: convertido}
    end)
  end

  defp reduce_balances(balances_convertidos) do
    balances_convertidos =
      Enum.reduce(balances_convertidos, 0, fn item, acc ->
        Decimal.add(acc, Decimal.from_float(item.balance))
      end)

    # Devuelve el resultado en el formato esperado por el Enum.map final
    %{balance: balances_convertidos}
  end
end
