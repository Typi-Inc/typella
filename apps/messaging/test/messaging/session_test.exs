defmodule Messaging.SessionTest do
  use Messaging.RethinkDBCase
  import RethinkDB.Query

  @event %{
    "type" => "message",
    "channel" => 123,
    "user" => 1,
    "text" => "Hello, World!"
  }

  setup %{conn: conn} do
    {:ok, %{conn: conn, user_id: 1}}
  end

  test "session sends new events on db updates", %{conn: conn, user_id: user_id} do
    {:ok, _session} = Messaging.Session.start_link([pid: self, user_id: user_id, last_seen_event_ts: 10])

    :timer.sleep(100)
    table(user_events_table_name.(user_id))
    |> insert(@event)
    |> RethinkDB.run(conn)

    assert_event_receive(@event)
  end

  test "session sends post last_seen_event_ts events on init", %{conn: conn, user_id: user_id} do
    now = :os.system_time(:milli_seconds)
    {:ok, _session} = Messaging.Session.start_link([pid: self, user_id: user_id, last_seen_event_ts: now - 10])

    event = Map.put(@event, "ts", now)

    :timer.sleep(100)
    table(user_events_table_name.(user_id))
    |> insert(event)
    |> RethinkDB.run(conn)

    assert_event_receive(event)
  end

  test "_session creates user_events_table if it does not exist", %{conn: conn} do
    user_id = 10
    {:ok, _session} = Messaging.Session.start_link([pid: self, user_id: user_id, last_seen_event_ts: 10])

    :timer.sleep(100)
    table(user_events_table_name.(user_id))
    |> insert(@event)
    |> RethinkDB.run(conn)

    assert_event_receive(@event)
  end

  defp assert_event_receive(event) do
    assert_receive {:event, received_event}
    for key <- Map.keys(event) do
      assert Map.get(received_event, key) == Map.get(event, key)
    end
  end
end
