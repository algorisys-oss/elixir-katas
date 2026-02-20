defmodule ElixirKatas.TaskyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ElixirKatas.Tasky` context.
  """

  @doc """
  Generate a todo.
  """
  def todo_fixture(attrs \\ %{}) do
    {:ok, todo} =
      attrs
      |> Enum.into(%{
        is_complete: true,
        title: "some title"
      })
      |> ElixirKatas.Tasky.create_todo()

    todo
  end
end
