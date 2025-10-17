ExUnit.start()
Faker.start()
# Ensure we're running tests in a sandbox which resets on every test run.
Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, :manual)
