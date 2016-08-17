defmodule Messaging.RethinkDBCase do
  use ExUnit.CaseTemplate
  import RethinkDB.Query
  import Messaging.ConfigHelpers

  using do
    quote do
      import Messaging.ConfigHelpers
      import RethinkDB.Query
      alias RethinkDB.Collection
      alias RethinkDB.Record
    end
  end

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
    :poolboy.checkin(:rethinkdb_pool, conn)

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
      :poolboy.checkin(:rethinkdb_pool, conn)
    end
    :ok
  end

  setup tags do
    conn = :poolboy.checkout(:rethinkdb_pool)
    on_exit fn ->
      table(events_table_name)
      |> delete
      |> RethinkDB.run(conn)

      table(channels_table_name)
      |> delete
      |> RethinkDB.run(conn)

      for user_id <- 1..3 do
        table(user_events_table_name.(user_id))
        |> delete
        |> RethinkDB.run(conn)
      end
      :poolboy.checkin(:rethinkdb_pool, conn)
    end
    {:ok, %{conn: conn}}
  end
end
