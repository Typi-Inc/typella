use Mix.Config

# Print only warnings and errors during test
config :logger, level: :warn

config :messaging, :rethinkdb,
  host: "localhost",
  port: 28015,
  events_table_name: "events_test",
  channels_table_name: "channels_test",
  user_events_table_name: fn id -> "user_" <> to_string(id) <> "_events_test" end
