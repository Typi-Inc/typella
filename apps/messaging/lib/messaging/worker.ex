defmodule Messaging.Worker do
  use GenServer
  import Messaging.ConfigHelpers
  import RethinkDB.Query
  alias RethinkDB.Record
  require Logger

  def start_link(_options) do
    GenServer.start(__MODULE__, :ok, [])
  end

  def save_event(server, event) do
    GenServer.cast(server, {:save, event})
  end

  def init(_options) do
    {:ok, []}
  end

  def handle_cast({:save, %{"type" => "create_channel"} = event}, state) do
    :poolboy.transaction(:rethinkdb_pool, fn conn ->
      %Record{data: %{"generated_keys" => [channel_id]}} = create_channel(event, conn)
      %Record{data: channel} = get_channel(channel_id, conn)

      Messaging.process(%{
        "type" => "channel_created",
        "channel" => channel
      })
    end)
    {:noreply, state}
  end

  def handle_cast({:save, %{"type" => "user_created"} = event}, state) do
    :poolboy.transaction(:rethinkdb_pool, fn conn ->
      create_user_table(event, conn)
      save_to_users_who_has_his_contact(event, conn)
    end)
    {:noreply, state}
  end

  def handle_cast({:save, %{"type" => type} = event}, state) when type in ["message", "channel_created"] do
    :poolboy.transaction(:rethinkdb_pool, fn conn ->
      save_to_main_table(event, conn)
      save_to_channel_participants(event, conn)
    end)
    {:noreply, state}
  end

  def handle_cast({:save, event}, state) do
    Logger.error "unknown even type in #{inspect event}"
    {:noreply, state}
  end

  defp create_channel(event, conn) do
    conf(:channels_table_name)
    |> table
    |> insert(event["channel"])
    |> RethinkDB.run(conn)
  end

  defp create_user_table(event, conn) do
    user_id = event["user"]["id"]
    table_create(user_events_table_name.(user_id))
    |> RethinkDB.run(conn)
  end

  defp save_to_users_who_has_his_contact(event, conn) do
    for user_id <- event["contact_of"] do
      conf(:user_events_table_name).(user_id)
      |> table
      |> insert(Map.delete(event, "contact_of"))
      |> RethinkDB.run(conn)
    end
  end

  defp save_to_main_table(event, conn) do
      conf(:events_table_name)
      |> table
      |> insert(Map.put(event, "ts", :os.system_time(:milli_seconds)))
      |> RethinkDB.run(conn)
  end

  defp save_to_channel_participants(event, conn) do
    channel =
      if Map.has_key?(event, "channel_id") do
        get_channel(event["channel_id"], conn)
      else
        get_channel(event["channel"]["id"], conn)
      end
    participants = get_channel_user_ids(channel)

    for user_id <- participants do
      conf(:user_events_table_name).(user_id)
      |> table
      |> insert(event)
      |> RethinkDB.run(conn)
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
      data -> Map.get(data, "participants")
    end
    |> case do
      nil -> []
      participants -> participants
    end
  end
end
