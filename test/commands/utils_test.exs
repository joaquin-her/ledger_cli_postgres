defmodule Ledger.Commands.UtilsTest do
  use ExUnit.Case, async: true
  alias Ledger.Commands.Utils

  test "format_errors should format errors correctly" do
    # Schema vacío con tipos
    changeset =
      {%{}, %{name: :string}}
      |> Ecto.Changeset.cast(%{}, [:name])
      |> Ecto.Changeset.validate_required([:name])

    formatted_errors = Utils.format_errors(changeset)
    assert formatted_errors == "name: can't be blank"
  end

  test "validate_id debe validar un entero correctamente" do
    assert Utils.validate_id(123) == {:ok, 123}
  end

  test "validate_id debe validar un id binario correctamente" do
    assert Utils.validate_id("456") == {:ok, 456}
  end

  test "validate_id debe no debe validar un id negativo correctamente" do
    assert Utils.validate_id("-789") == {:error, "no puede ser negativo"}
  end

  test "validate_id debe validar una cadena correctamente como invalida" do
    assert Utils.validate_id("abc") == {:error, "no puede ser una cadena"}
  end

  test "validate_id debe validar otros tipos de ingreso como invalidos" do
    assert Utils.validate_id(:invalid) == {:error, "ID invalido"}
  end

  test "validate_id debe mostrar como necesario un valor si el ingreso es vacio" do
    {:error, "es requerido"}
  end

  test "validate_id con flag debe devolver la flag y el error" do
    assert Utils.validate_id("123", :flag) == {:ok, 123}

    assert Utils.validate_id("-456", :flag) ==
             {:error, "id_invalido: argumento=flag no puede ser negativo"}

    assert Utils.validate_id("abc", :flag) ==
             {:error, "id_invalido: argumento=flag no puede ser una cadena"}

    assert Utils.validate_id(:invalid, :flag) ==
             {:error, "id_invalido: argumento=flag ID invalido"}
    assert Utils.validate_id(nil, :flag) ==
             {:error, "id_invalido: argumento=flag es requerido"}
  end
end
