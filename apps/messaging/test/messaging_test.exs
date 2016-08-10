defmodule MessagingTest do
  use Messaging.RethinkDBCase

  @event %{
    "type" => "message",
    "channel" => 123,
    "user" => 1,
    "text" => "Hello, World!"
  }

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
end
