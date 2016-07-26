defmodule Typi.ActionCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Typi.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Typi.Factory
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Typi.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Typi.Repo, {:shared, self()})
    end

    :ok
  end
end
