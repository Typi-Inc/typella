defmodule Typi.ActionHelpers do
  def translate_errors(reasons) do
    if Map.has_key?(reasons, :__struct__) and reasons.__struct__ == Ecto.Changeset do
      %{ errors: Ecto.Changeset.traverse_errors(reasons, &translate_error/1) }
    else
      %{ errors: traverse_errors(reasons, &translate_error/1) }
    end
  end

  defp traverse_errors(errors, msg_func) do
    Enum.reduce(errors, %{}, fn { key, val }, acc ->
      IO.inspect key
      IO.inspect val
      val = msg_func.(val)
      Map.update(acc, key, [val], &[val|&1])
    end)
  end

  defp translate_error({ msg, opts }) do
    if count = opts[:count] do
      Gettext.dngettext(Typi.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(Typi.Gettext, "errors", msg, opts)
    end
  end
end
