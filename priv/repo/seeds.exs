# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ElixirKatas.Repo.insert!(%ElixirKatas.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias ElixirKatas.Accounts

# Create demo user for Tasky
{:ok, user} = Accounts.register_user(%{
  email: "demo1@example.com",
  password: "demo123demo123"
})
IO.puts("Demo user created: demo1@example.com / demo123demo123")

alias ElixirKatas.Tasky

# Create a sample task
{:ok, todo} = Tasky.create_todo(user.id, %{
  title: "Complete Tasky Blue Belt",
  category: "Development",
  priority: "high",
  due_date: Date.add(Date.utc_today(), 2)
})

# Add subtasks
{:ok, _} = Tasky.create_subtask(%{
  "title" => "Implement Subtasks",
  "is_complete" => true,
  "todo_id" => todo.id
})

{:ok, _} = Tasky.create_subtask(%{
  "title" => "Implement Comments",
  "is_complete" => true,
  "todo_id" => todo.id
})

{:ok, _} = Tasky.create_subtask(%{
  "title" => "Implement Attachments",
  "is_complete" => true,
  "todo_id" => todo.id
})

{:ok, _} = Tasky.create_subtask(%{
  "title" => "Verify all features",
  "is_complete" => false,
  "todo_id" => todo.id
})

# Add comments
{:ok, _} = Tasky.create_comment(%{
  "content" => "This is coming along nicely!",
  "todo_id" => todo.id,
  "user_id" => user.id
})

{:ok, _} = Tasky.create_comment(%{
  "content" => "Don't forget to test the file uploads.",
  "todo_id" => todo.id,
  "user_id" => user.id
})

# Add attachment
{:ok, _} = Tasky.create_attachment(%{
  "filename" => "demo-image.svg",
  "content_type" => "image/svg+xml",
  "path" => "/uploads/demo-image.svg",
  "size" => 1234,
  "todo_id" => todo.id
})

IO.puts("Created sample Todo with Subtasks, Comments, and Attachment.")
