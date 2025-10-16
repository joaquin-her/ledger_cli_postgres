# Moneda Schema Documentation
This schema represents a currency with a name and a price in USD.
## Usage
To use this schema, you'll need to have Ecto installed and set up in your project. You'll also need a Repo module that is configured to connect to your database.
## Inserting Data
You can insert data into the Moneda table using the `insert/2` function from Ecto.Repo. Here's an example:
#Ledger.Commands.Usuario.run( :crear, %{"-n"=>"Fabrizzio_el_maestro_de_maestros@gmail", "-b"=>"2004-04-20"})

## Updating Data
To update data in the Moneda table, you can use the `update/2` function from Ecto.Repo. Here's an example:

```elixir
moneda = Ledger.Schemas.Moneda |> Repo.get(1)
changeset = Ledger.Schemas.Moneda.changeset(moneda, %{nombre: "New Name", precio_en_usd: 10.5})
updated_moneda = Repo.update!(changeset)
```

## Deleting Data
To delete data from the Moneda table, you can use the `delete/2` function from Ecto.Repo. Here's an example:

```elixir
moneda = Ledger.Schemas.Moneda |> Repo.get(1)
deleted_moneda = Repo.delete!(moneda)
```

## Querying Data
To query data in the Moneda table, you can use Ecto.Query or direct queries from Ecto.Repo. Here's an example using a direct query:

```elixir
query = from m in Ledger.Schemas.Moneda, where: m.precio_en_usd > 10
monedas = Repo.all(query)
```

For more information on how to use Ecto, you can refer to the [Ecto documentation](https://hexdocs.pm/ecto/Ecto.html).