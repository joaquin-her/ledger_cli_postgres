import Config

config :ledger, Ledger.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  log: false
