defmodule ElixirKatas.TaskyTest do
  use ElixirKatas.DataCase

  alias ElixirKatas.Tasky

  describe "todos" do
    alias ElixirKatas.Tasky.Todo

    import ElixirKatas.TaskyFixtures

    @invalid_attrs %{title: nil, is_complete: nil}

    test "list_todos/0 returns all todos" do
      todo = todo_fixture()
      assert Tasky.list_todos() == [todo]
    end

    test "get_todo!/1 returns the todo with given id" do
      todo = todo_fixture()
      assert Tasky.get_todo!(todo.id) == todo
    end

    test "create_todo/1 with valid data creates a todo" do
      valid_attrs = %{title: "some title", is_complete: true}

      assert {:ok, %Todo{} = todo} = Tasky.create_todo(valid_attrs)
      assert todo.title == "some title"
      assert todo.is_complete == true
    end

    test "create_todo/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tasky.create_todo(@invalid_attrs)
    end

    test "update_todo/2 with valid data updates the todo" do
      todo = todo_fixture()
      update_attrs = %{title: "some updated title", is_complete: false}

      assert {:ok, %Todo{} = todo} = Tasky.update_todo(todo, update_attrs)
      assert todo.title == "some updated title"
      assert todo.is_complete == false
    end

    test "update_todo/2 with invalid data returns error changeset" do
      todo = todo_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasky.update_todo(todo, @invalid_attrs)
      assert todo == Tasky.get_todo!(todo.id)
    end

    test "delete_todo/1 deletes the todo" do
      todo = todo_fixture()
      assert {:ok, %Todo{}} = Tasky.delete_todo(todo)
      assert_raise Ecto.NoResultsError, fn -> Tasky.get_todo!(todo.id) end
    end

    test "change_todo/1 returns a todo changeset" do
      todo = todo_fixture()
      assert %Ecto.Changeset{} = Tasky.change_todo(todo)
    end
  end
end
