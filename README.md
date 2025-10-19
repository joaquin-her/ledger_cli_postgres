# Ledger

## Table of Contents

- [Installation](#installation)
- [Running](#running)

## Installation

To get started with this project, follow these steps:

1. **Install Dependencies:**
   Ensure you have Erl installed (Erl 1.16 or higher). Then install the required packages:
   ```sh
   mix deps.get
   ```

## Running

Once your environment is set up, you can run the project using the following commands:

1. **Docker Compose Postgres:**
   ```sh
   docker compose up
   ```

2. **Compile the project:**
   ```sh
   mix build
   ```

3. **Run Binary:**
   ```sh
   ./ledger <command> <args>


## Consideraciones de implementacion 
- Considerando que el valor de las monedas es modificable y los usuarios pueden tener cuentas en varias de ellas y conseguir balances de ellas, se realizó:
   - una tabla de cuentas que contiene informacion de usuario, moneda y cantidad de esa moneda en esa cuenta
   - metodo para deshacer transacciones solo si fue la ultima realizada (independiente del valor de las monedas)
   - un metodo para acumular las cantidades de todos los activos del usuario y poder verlos en cuanto representarian en una moneda determinada
   - que el calculo de balance se haga con los valores de la tabla de cuentas mas que la de transacciones. 

- Otra consideracion es las cantidades que se pueden almacenar en las cuentas. Esta es indistinta. Los usuarios pueden tener cantidades negativas en sus cuentas irrestrictamente
- Contenerizacion: 
   - en el docker compose se incluyen servicios comentados como:
      - pgadmin: para conectarse a la base de datos del entorno de pruebas en caso de requerir hacer pruebas manuales
      - ngnix: para poder revisar los html de coverage generados por mix test --cover en la carpeta .volumes/cover de manera navegable. Para eso re requiere mover la carpeta _nginx_ con su contenido a .volumes/ , y que quede el path ".volumes/nginx/default.conf"
- Scripting:
   - En el repositorio se incluyen comandos adiciones es Powershell en caso de estar en windows. Contienen comportamientos extras y algunos convenientes, se recomienda revisar.
   - Se generaron aliases de mix para simplificar secuencias de comandos. Estos son "remake-db" y "build". Remake-db dropea y ejecuta las migraciones para levantar una base de datos de desarrollo limpia y build utiliza este anterior en conjunto con escript.build para generar el binario.

## Algunas mejoras realizables:
- Se podrian generar mas modulos para dividir mejor las  responsabilidades de Create, Read, Delete and update de los comandos.
- Se podrian crear mas structs y schemas para abstraer aun mas capas de CLI | model | persistencia. 
- Se podrian refactorizar todos los tests para compartir secuencias de casos de "setup de db" mas limpia y ordenadamente con scripts de seeds.
- Se podrian ejecutar mas seguros los tests con async para mayor velocidad haciendo que en una abstraccion de instanciado se creen siempre entidades con valores distintos asi no se bloquean los workers (problema de concurrencia)
