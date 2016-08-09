defmodule MessagingTest do
  use ExUnit.Case
  import RethinkDB.Query
  alias RethinkDB.Collection
  alias RethinkDB.Record

  @event %{
    "type" => "message",
    "channel" => 123,
    "user" => 1,
    "text" => "Hello, World!"
  }

  setup_all do
    conn = :poolboy.checkout(:rethinkdb_pool)

    table_create(events_table_name)
    |> RethinkDB.run(conn)

    table_create(channels_table_name)
    |> RethinkDB.run(conn)

    for user_id <- 1..3 do
      table_create(user_events_table_name.(user_id))
      |> RethinkDB.run(conn)
    end

    on_exit fn ->
      conn = :poolboy.checkout(:rethinkdb_pool)

      table_drop(events_table_name)
      |> RethinkDB.run(conn)

      table_drop(channels_table_name)
      |> RethinkDB.run(conn)

      for user_id <- 1..3 do
        table_drop(user_events_table_name.(user_id))
        |> RethinkDB.run(conn)
      end
    end
    :ok
  end

  setup do
    conn = :poolboy.checkout(:rethinkdb_pool)
    on_exit fn ->
      table(events_table_name)
      |> delete
      |> RethinkDB.run(conn)

      table("channels")
      |> delete
      |> RethinkDB.run(conn)

      for user_id <- 1..3 do
        table(user_events_table_name.(user_id))
        |> delete
        |> RethinkDB.run(conn)
      end
    end
    {:ok, %{conn: conn}}
  end

  test "when event is injected into the system, it is stored into the main table", %{conn: conn} do
    Messaging.broadcast @event
    :timer.sleep 100
    assert %Collection{data: [@event]} = table(events_table_name)
      |> RethinkDB.run(conn)
  end

  test "when event is injected into the system and event is message, it is stored to channel participants' table", %{conn: conn} do
    user_ids = 1..3 |> Enum.to_list
    %Record{data: %{"generated_keys" => [id]}} = table(channels_table_name)
      |> insert(%{
        user_ids: user_ids
      })
      |> RethinkDB.run(conn)

    event = Map.put(@event, "channel", id)
    Messaging.broadcast(event)
    :timer.sleep 100
    for user_id <- user_ids do
      assert %Collection{data: [event]} =
        table(user_events_table_name.(user_id))
        |> RethinkDB.run(conn)
    end
  end

  defp events_table_name do
    conf(:events_table_name)
  end

  defp channels_table_name do
    conf(:channels_table_name)
  end

  defp user_events_table_name do
    conf(:user_events_table_name)
  end

  defp conf do
    Application.get_env(:messaging, :rethinkdb)
  end

  defp conf(key) do
    Keyword.get(conf, key)
  end
end
