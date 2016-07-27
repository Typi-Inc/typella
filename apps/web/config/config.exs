# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :web, Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qIJqKuqluAM5e6Aa8ciFMiu+UhZFEd9d2EvzeQzB0NUNKHP81N1nvRt2LzY7aHz8",
  render_errors: [view: Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Web.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :guardian, Guardian,
  allowed_algos: ["ES512"],
  issuer: "Typi",
  verify_issuer: true,
  ttl: {36530, :days},
  secret_key: %{
    "alg" => "ES512",
    "crv" => "P-521",
    "d" => "AYGjuosjZcjJxQvsSzeX6FQPOGeIXpAwcQJ81iEukfdGX0ipMzgAJ5piep_muegLE1b8L5V50sydWyoWysTBuJSV",
    "kty" => "EC",
    "use" => "sig",
    "x" => "AL3ihPKSymhrCk4Gde0iOr4ZqfXVLXwRV7nATk_KQDMez_uste1YoYpb4yDudE1PXhIMOmb1rE3lQ0469NGHocea",
    "y" => "AX1Kls2KK6GAtGnD9KoNYEvdcba212zMTsGUj39KdmyyCWvXxJUGA1OUhuuGKXM5RyjFiKBqdflLW0RY1wW72g19"
  },
  serializer: Web.GuardianSerializer


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
