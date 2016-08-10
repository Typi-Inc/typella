defmodule Messaging.Session do
  use RethinkDB.Changefeed
  import Messaging.ConfigHelpers
  import RethinkDB.Query
  import RethinkDB.Lambda

  def start_link(opts, gen_server_opts \\ []) do
    RethinkDB.Changefeed.start_link(__MODULE__, opts, gen_server_opts)
  end

  def init([pid: pid, user_id: user_id, last_seen_event_ts: last_seen_event_ts]) do
    ref = Process.monitor(pid)

    q = table(user_events_table_name.(user_id))
      |> changes

    send self, {:after_spawn, pid, user_id, last_seen_event_ts}
    {:subscribe, q, Messaging.Database, %{pid: pid, ref: ref, last_seen_event_ts: last_seen_event_ts}}
  end

  def handle_update(data, %{pid: pid} = state) do
    Enum.each(data, fn
      %{"new_val" => event, "old_val" => nil} ->
        send pid, {:event, event}
      _ -> :ok
    end)
    send pid, {:event, data}
    {:next, state}
  end

  def handle_info({:after_spawn, pid, user_id, last_seen_event_ts}, state) do
    ensure_table_exists(user_id)
    send_recent_events(pid, user_id, last_seen_event_ts)
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, pid, _}, state) do
    {:stop, :shutdown, state}
  end

  def terminate(reason, state) do
    :ok
  end

  defp ensure_table_exists(user_id) do
    :poolboy.transaction(:rethinkdb_pool, fn conn ->
      user_events_table_name.(user_id)
      |> table_create
      |> RethinkDB.run(conn)
      |> IO.inspect
    end)
  end

  defp send_recent_events(pid, user_id, last_seen_event_ts) do
    :poolboy.transaction(:rethinkdb_pool, fn conn ->
      table(user_events_table_name.(user_id))
      |> filter(lambda fn event -> event["ts"] > last_seen_event_ts end)
    end)
  end
end
