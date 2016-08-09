defmodule Messaging.Worker do
  use GenServer
  import RethinkDB.Query

  def start_link(_options) do
    GenServer.start(__MODULE__, :ok, [])
  end

  def save_event(server, event) do
    GenServer.cast(server, {:save, event})
  end

  def init(_options) do
    {:ok, []}
  end

  def handle_cast({:save, event}, state) do
    :poolboy.transaction(:rethinkdb_pool, fn conn ->
      save_to_main_table(event, conn)
      save_to_channel_participants(event, conn)
    end)
    {:noreply, state}
  end

  def save_to_main_table(event, conn) do
      conf(:events_table_name)
      |> table
      |> insert(event)
      |> RethinkDB.run(conn)
  end

  def save_to_channel_participants(event, conn) do
    if Map.has_key?(event, "channel") do
      channel = get_channel(event["channel"], conn)
      user_ids = get_channel_user_ids(channel)

      for user_id <- user_ids do
        conf(:user_events_table_name).(user_id)
        |> table
        |> insert(event)
        |> RethinkDB.run(conn)
      end
    end
  end

  defp get_channel(channel_id, conn) do
    conf(:channels_table_name)
    |> table
    |> get(channel_id)
    |> RethinkDB.run(conn)
  end

  defp get_channel_user_ids(channel) do
    channel
    |> Map.get(:data)
    |> case do
      nil -> []
      data -> Map.get(data, "user_ids")
    end
    |> case do
      nil -> []
      user_ids -> user_ids
    end
  end

  defp conf do
    Application.get_env(:messaging, :rethinkdb)
  end

  defp conf(key) do
    Keyword.get(conf, key)
  end
end
