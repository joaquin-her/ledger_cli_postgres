defmodule Ledger.TestHelpers do
  alias Ledger.Commands.{Usuarios, Monedas, Transacciones}

  def crear_usuario_unico(suffix \\ nil) do
    suffix = suffix || System.unique_integer([:positive])

    Usuarios.run(:crear, %{
      "-n" => "#{Faker.Pokemon.En.name()}_#{suffix}",
      "-b" => Faker.Date.date_of_birth()
    })
  end

  def crear_moneda_unica(precio) do
    nombre = String.slice(Faker.Pokemon.En.name(), 0, 4)

    Monedas.run(:crear, %{
      "-n" => "#{nombre}",
      "-p" => precio
    })
  end

  def crear_alta_cuenta(usuario_id, moneda_nombre, monto) do
    Transacciones.run(:crear, "alta_cuenta", %{
      "-u" => "#{usuario_id}",
      "-m" => "#{moneda_nombre}",
      "-a" => "#{monto}"
    })
  end

  def crear_transferencia(origen_id, destino_id, moneda_id, monto) do
    Transacciones.run(:crear, "transferencia", %{
      "-o" => "#{origen_id}",
      "-d" => "#{destino_id}",
      "-m" => "#{moneda_id}",
      "-a" => "#{monto}"
    })
  end

  def crear_swap(usuario_id, moneda_origen_id, moneda_destino_id, monto) do
    Transacciones.run(:crear, "swap", %{
      "-u" => "#{usuario_id}",
      "-mo" => "#{moneda_origen_id}",
      "-md" => "#{moneda_destino_id}",
      "-a" => "#{monto}"
    })
  end
end
