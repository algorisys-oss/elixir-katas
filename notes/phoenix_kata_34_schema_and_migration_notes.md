# Kata 34: Schema & Migration

## What is Ecto?

**Ecto** is Elixir's database library. It is NOT an ORM — it does not hide SQL or magically load associations. Instead it gives you:

- **Schemas**: Elixir struct definitions that map to DB tables
- **Changesets**: validation and casting pipelines (Kata 35)
- **Repo**: the interface to run queries (Kata 36)
- **Query DSL**: composable `from/where/select` queries (Kata 37)
- **Migrations**: versioned database schema changes

---

## Ecto Schema

A schema defines the shape of an Elixir struct and how its fields map to a database table.

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email,    :string
    field :username, :string
    field :age,      :integer
    field :verified, :boolean, default: false
    field :bio,      :text

    timestamps()   # adds inserted_at and updated_at
  end
end
```

Using the schema:

```elixir
# Create a struct (like any Elixir struct):
user = %MyApp.Accounts.User{}
# => %User{id: nil, email: nil, username: nil, verified: false, ...}

user = %MyApp.Accounts.User{email: "alice@example.com", username: "alice"}
```

---

## timestamps/1

`timestamps()` is a macro that adds two fields automatically:

| Field | Type | Set by Ecto |
|-------|------|-------------|
| `inserted_at` | NaiveDateTime | On `Repo.insert/2` |
| `updated_at` | NaiveDateTime | On `Repo.update/2` |

For UTC-aware datetimes:

```elixir
timestamps(type: :utc_datetime)
# or
timestamps(type: :utc_datetime_usec)  # with microseconds
```

To rename columns:

```elixir
timestamps(inserted_at: :created_at, updated_at: :modified_at)
```

---

## Primary Keys

Default primary key is `:id` (integer, auto-increment):

```elixir
# Default (no configuration needed):
schema "users" do
  # id is automatically :id, :integer, autogenerate: true
  field :email, :string
end
```

UUID primary key:

```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id

schema "posts" do
  field :title, :string
end
```

No primary key (for join tables):

```elixir
@primary_key false
schema "user_roles" do
  belongs_to :user, User
  belongs_to :role, Role
end
```

---

## Virtual Fields

Virtual fields exist in the struct but are **not persisted** to the database. Useful for form fields, computed values, or temporary data.

```elixir
schema "users" do
  field :email,         :string
  field :password_hash, :string

  # Virtual — not stored in DB:
  field :password,      :string, virtual: true
  field :word_count,    :integer, virtual: true
end
```

---

## Embedded Schemas

An embedded schema has no database table. It is used for:

- JSON/JSONB columns in the database
- Form data that does not map directly to a table
- Complex nested data structures

```elixir
defmodule MyApp.Address do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :street,  :string
    field :city,    :string
    field :country, :string
    field :zip,     :string
  end

  def changeset(address, attrs) do
    address
    |> cast(attrs, [:street, :city, :country, :zip])
    |> validate_required([:street, :city])
  end
end

# Use in a parent schema:
defmodule MyApp.Accounts.User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    embeds_one :address, MyApp.Address
    embeds_many :contacts, MyApp.Contact
  end
end
```

---

## Field Types Reference

| Ecto Type | Elixir Type | PostgreSQL | Notes |
|-----------|-------------|------------|-------|
| `:id` | integer | bigserial | Auto primary key |
| `:string` | String.t() | varchar(255) | Default text field |
| `:text` | String.t() | text | Unlimited length |
| `:integer` | integer | integer | 32-bit |
| `:bigint` | integer | bigint | 64-bit |
| `:float` | float | float | Double precision |
| `:decimal` | Decimal.t() | decimal | Arbitrary precision |
| `:boolean` | boolean | boolean | true/false |
| `:date` | Date.t() | date | YYYY-MM-DD |
| `:time` | Time.t() | time | HH:MM:SS |
| `:naive_datetime` | NaiveDateTime.t() | timestamp | No timezone |
| `:utc_datetime` | DateTime.t() | timestamptz | UTC timezone |
| `:map` | map | jsonb | JSON document |
| `{:array, :string}` | list | text[] | Array of strings |
| `:binary_id` | binary | uuid | UUID |

---

## Ecto.Enum

For fields with a fixed set of allowed values:

```elixir
field :status, Ecto.Enum,
  values: [:draft, :published, :archived]

# Or with string DB storage:
field :role, Ecto.Enum,
  values: [:admin, :editor, :viewer],
  embed_as: :dumped  # stores as string "admin"
```

---

## Migrations

Migrations are Elixir modules that describe database schema changes. They are stored in `priv/repo/migrations/` and versioned by timestamp prefix.

### Generating a Migration

```bash
mix ecto.gen.migration create_users
# Creates: priv/repo/migrations/20240115120000_create_users.exs
```

### Create Table Migration

```elixir
defmodule MyApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email,    :string,  null: false
      add :username, :string,  null: false
      add :age,      :integer
      add :verified, :boolean, default: false
      add :bio,      :text

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:username])
  end
end
```

### up/down vs change

`change/0` is reversible automatically. Use `up/0` and `down/0` for complex changes:

```elixir
def up do
  create table(:events) do
    add :name, :string
    timestamps()
  end
end

def down do
  drop table(:events)
end
```

### Altering Tables

```elixir
defmodule MyApp.Repo.Migrations.AddBioToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add    :bio,       :text
      add    :avatar,    :string
      modify :username,  :string, size: 100
      remove :old_field, :string   # must provide type for reversibility
    end
  end
end
```

### Indexes

```elixir
# Simple index:
create index(:posts, [:user_id])

# Unique index:
create unique_index(:users, [:email])

# Composite index:
create index(:posts, [:user_id, :status])

# Conditional (partial) index:
create index(:posts, [:published_at],
  where: "status = 'published'")

# Named index:
create index(:posts, [:user_id],
  name: :posts_user_id_idx)

# Drop index:
drop index(:users, [:old_column])
```

### Foreign Keys

```elixir
add :user_id, references(:users,
  on_delete: :delete_all,  # or :nilify_all, :restrict, :nothing
  type: :bigint)
```

---

## Migration Commands

```bash
# Generate new migration:
mix ecto.gen.migration create_users

# Run all pending migrations:
mix ecto.migrate

# Roll back the last migration:
mix ecto.rollback

# Roll back N steps:
mix ecto.rollback --step 3

# Migrate to a specific version:
mix ecto.migrate --to 20240115120000

# Show migration status:
mix ecto.migrations

# Reset (drop + create + migrate) — dev only!
mix ecto.reset

# Just drop and recreate:
mix ecto.drop && mix ecto.create && mix ecto.migrate
```

---

## Schema vs Migration — What Goes Where?

| Concern | Schema | Migration |
|---------|--------|-----------|
| Field names | Yes | Yes (must match) |
| Field types | Yes (Ecto types) | Yes (DB types) |
| Default values | In struct | In DB column |
| Indexes | No | Yes |
| Foreign keys | `belongs_to` macro | `references/2` |
| Constraints | In changeset | In migration |
| Timestamps | `timestamps()` | `timestamps()` |

---

## Key Takeaways

1. A **schema** defines the Elixir struct shape — it is the application-side view of the data
2. A **migration** defines the database table structure — it runs SQL DDL
3. **Never edit** a migration that has already been run in production; always create a new one
4. `timestamps()` in both schema and migration gives you `inserted_at`/`updated_at` automatically
5. **Virtual fields** are schema-only — not stored in the DB
6. **Embedded schemas** map to JSONB columns or are used for embedded forms
7. The `schema_migrations` table tracks which migrations have been applied
