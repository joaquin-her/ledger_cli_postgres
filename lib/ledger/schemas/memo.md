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

## Associations

USUARIO
  has_many :cuentas

CUENTA
  belongs_to :usuario
  belongs_to :moneda
  has_many :transacciones_origen
  has_many :transacciones_destino

MONEDA
  has_many :cuentas
  has_many :transacciones_origen
  has_many :transacciones_destino

TRANSACCION
  belongs_to :usuario
  belongs_to :cuenta_origen (Cuenta)
  belongs_to :cuenta_destino (Cuenta)
  belongs_to :moneda_origen (Moneda)
  belongs_to :moneda_destino (Moneda)

## swap
- pide argumentos
- valida si usuario tiene cuentas con los nombres "moneda_o" y "moneda_d
    - "error, no se puede hacer swap entre monedas de usuarios distintos"
- valida si el monto es valido
- valida que la cuenta tenga la cantidad suficiente (monto <= cuenta_origen.monto)
- calcula el valor en dolares del monto :monto_en_dolares
- hace la conversion de :monto_en_dolares a :moneda_destino segun su valor en :monedas
- 

ALMOST DONE:
/ledger balance -u1=<id-usuario> -m=<id-moneda> 
/ledger realizar_transferencia -o=<id-usuario-origen> -d=<id-usuario-destino> - m=<id-moneda> -a=<monto>
STARTED:

DOING: 
/ledger deshacer_transaccion -id=<id-transaccion> 

PENDING:
/ledger ver_transaccion -id=<id-transaccion>
. transacciones entre cuentas sin monedas comun 
. transacciones con monto insuficiente