defmodule Ledger.Commands.Balance do
  #alias Ledger.Commands.Transacciones
  alias Ledger.Commands.Usuarios
  alias Ledger.Schemas.Usuario
  alias Ledger.Schemas.Cuenta
  alias Ledger.Schemas.Moneda
#

  import Ecto.Query

  def run(args) do
    parsed = %{
      usuario_origen: args["-u1"]
    }
    with {:ok, usuario} <- Usuarios.run(:ver, %{"-id" => parsed.usuario_origen}),
         {:ok, balance} <- get_balance(usuario) do
      {:ok, balance}
    else
      {:error, mensaje} ->
        {:error, mensaje}
    end
  end

  @doc """
  Devuelve el monto de todas las cuentas de un usuario segun las transferencias que tenga asociada en Transacciones
  """
  def get_balance(usuario) do
    # obtener de :transacciones todas las operaciones con la cuenta de id: :id_cuenta y devolver el total
    balance = Cuenta
      |> join(:inner, [c], u in Usuario, on: c.usuario_id == u.id)
      |> where([c, u], u.id == ^usuario.id)
      |> join(:inner, [c, u], m in Moneda, on: c.moneda_id == m.id)
      |> select([c, u, m], %{
        moneda: m.nombre,
        balance: c.cantidad
      })
      |> Ledger.Repo.all()
      |> IO.inspect()
      {:ok, balance}
  end

end
