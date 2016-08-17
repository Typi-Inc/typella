defmodule Messaging.EventManager do
  use GenServer
  import RethinkDB.Query
  import Messaging.ConfigHelpers

  def start_link(_options) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def process(server, event) do
    GenServer.cast(server, {:process, event})
  end

  def init(_options) do
    :poolboy.transaction(:rethinkdb_pool, fn conn ->
      table_create(events_table_name)
      |> RethinkDB.run(conn)

      table_create(channels_table_name)
      |> RethinkDB.run(conn)
    end)
    {:ok, []}
  end

  def handle_cast({:process, event}, state) do
    :poolboy.transaction(:event_saver_pool, fn worker ->
      Messaging.Worker.save_event(worker, event)
    end)
    {:noreply, state}
  end
end
