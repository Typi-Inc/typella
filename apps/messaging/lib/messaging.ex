defmodule Messaging do
  use Application
  import Messaging.ConfigHelpers

  def broadcast(event) do
    :poolboy.transaction(:event_manager_pool, fn em ->
      Messaging.EventManager.broadcast(em, event)
    end)
  end

  def connect(pid, user_id, last_seen_event_ts) do
    Messaging.SessionSupervisor.start_session([[pid: pid, user_id: user_id, last_seen_event_ts: last_seen_event_ts]])
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    rethinkdb_pool_options = [
      name: {:local, :rethinkdb_pool},
      worker_module: RethinkDB.Connection,
      size: 10,
      max_overflow: 0
    ]

    event_saver_pool_options = [
      name: {:local, :event_saver_pool},
      worker_module: Messaging.Worker,
      size: 5,
      max_overflow: 10
    ]

    event_manager_pool_options = [
      name: {:local, :event_manager_pool},
      worker_module: Messaging.EventManager,
      size: 128,
      max_overflow: 0
    ]

    children = [
      :poolboy.child_spec(:rethinkdb_pool, rethinkdb_pool_options, [port: conf(:port), host: conf(:host)]),
      :poolboy.child_spec(:event_saver_pool, event_saver_pool_options, []),
      :poolboy.child_spec(:event_manager_pool, event_manager_pool_options, []),
      worker(Messaging.Database, []),
      supervisor(Messaging.SessionSupervisor, [])
    ]

    opts = [strategy: :one_for_one, name: Messaging.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
