FROM elixir:1.18-alpine

# Instalar dependencias necesarias
RUN apk add --no-cache \
    git \
    build-base \
    postgresql-client

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos del proyecto
COPY . .

# Instalar dependencias de Elixir
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

# Compilar el escript
RUN mix escript.build

# El escript compilado estará disponible para ejecutar
CMD ["/bin/sh"]