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
    {:ok, session} = Messaging.Session.start_link([pid: self, user_id: user_id, last_seen_event_ts: 10])

    :timer.sleep(100)
    table(user_events_table_name.(user_id))
    |> insert(@event)
    |> RethinkDB.run(conn)

    assert_receive {:event, @event}
  end

  test "session sends post last_seen_event_ts events on init", %{conn: conn, user_id: user_id} do
    now = :os.system_time(:milli_seconds)
    {:ok, session} = Messaging.Session.start_link([pid: self, user_id: user_id, last_seen_event_ts: now - 10])

    event = Map.put(@event, "ts", now)

    table(user_events_table_name.(user_id))
    |> insert(event)
    |> RethinkDB.run(conn)

    assert_receive {:event, event}
  end

  test "session creates user_events_table if it does not exist", %{conn: conn} do
    user_id = 10
    {:ok, session} = Messaging.Session.start_link([pid: self, user_id: user_id, last_seen_event_ts: 10])

    :timer.sleep(100)
    table(user_events_table_name.(user_id))
    |> insert(@event)
    |> RethinkDB.run(conn)

    assert_receive {:event, @event}
  end
end
