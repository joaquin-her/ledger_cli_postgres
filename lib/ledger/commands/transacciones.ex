defmodule Ledger.Commands.Transacciones do

  def run( :crear, tipo, args) do
    case tipo do
      "swap" ->
        swap( :crear, args)
      "transaccion" ->
        transaccion( :crear, args)
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

  defp swap( :crear, _) do

  end
  defp swap( :borrar, _) do

  end
  defp swap( _, _) do
    {:error, "subcommando no encontrado"}
  end

  defp transaccion( :crear, _) do

  end

  defp transaccion( :borrar, _) do

  end
  defp transaccion( _, _) do
    {:error, "subcommando no encontrado"}
  end

end
