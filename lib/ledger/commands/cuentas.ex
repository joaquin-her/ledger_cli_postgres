defmodule Ledger.Commands.Cuentas do
  alias Ledger.Schemas.Cuenta
  alias Ledger.Commands.Utils

  def run(:alta, args) do
    {id_moneda,_} = Integer.parse(args["-m"])
    {id_usuario,_} = Integer.parse(args["-id"])
    cuenta = %{
      moneda_id: id_moneda ,
      monto: args["-a"],
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



end
