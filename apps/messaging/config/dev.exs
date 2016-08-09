use Mix.Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Configure your database
config :messaging, :rethinkdb,
  host: "localhost",
  port: 28015,
  events_table_name: "events_dev",
  channels_table_name: "channels_dev",
  user_events_table_name: fn id -> "user_" <> to_string(id) <> "_events_dev" end
