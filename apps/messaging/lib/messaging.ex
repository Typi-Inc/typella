defmodule Messaging do
  use Application

  def broadcast(event) do
    :poolboy.transaction(:event_saver_pool, fn worker ->
      Messaging.Worker.save_event(worker, event)
    end)
  end

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    rethinkdb_pool_options = [
      name: {:local, :rethinkdb_pool},
      worker_module: RethinkDB.Connection,
      size: 10,
      max_overflow: 0
    ]

    event_saver_pool = [
      name: {:local, :event_saver_pool},
      worker_module: Messaging.Worker,
      size: 5,
      max_overflow: 10
    ]

    children = [
      :poolboy.child_spec(:rethinkdb_pool, rethinkdb_pool_options, [port: config(:port), host: config(:host)]),
      :poolboy.child_spec(:event_saver_pool, event_saver_pool, [])
    ]

    opts = [strategy: :one_for_one, name: Messaging.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp config do
    Application.get_env(:messaging, :rethinkdb)
  end

  defp config(key) when is_atom(key) do
    Keyword.get(config, key)
  end
end
