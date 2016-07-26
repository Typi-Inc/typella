defmodule Typi.Action do
  defmacro __using__(which) do
    quote do
      import Ecto
      import Ecto.Query

      import Typi.ActionHelpers
      import Typi.Gettext
    end
  end
end
