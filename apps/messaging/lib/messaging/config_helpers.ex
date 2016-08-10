defmodule Messaging.ConfigHelpers do
  def events_table_name do
    conf(:events_table_name)
  end

  def channels_table_name do
    conf(:channels_table_name)
  end

  def user_events_table_name do
    conf(:user_events_table_name)
  end

  def conf do
    Application.get_env(:messaging, :rethinkdb)
  end

  def conf(key) do
    Keyword.get(conf, key)
  end
end
