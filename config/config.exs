import Config

config :ledger, Ledger.Repo,
  database: "ledger_db",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :ledger, ecto_repos: [Ledger.Repo]
import_config "#{config_env()}.exs"
