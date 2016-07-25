use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or you later on).

# Configure your database
config :typi, Typi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "typi_prod",
  pool_size: 20

config :typi, :pot,
  secret: "PLFGGRDDFZRUR1LY",
  expiration: 3600,
  token_length: 4

config :ex_twilio, account_sid: "AC29406b48a13099dda8f666fa8e001ea0",
  Typi_token: "900e2f465257eafd676b78d452904332",
  phone_number: "+12014312173"

config :typi, :twilio_api, ExTwilio
