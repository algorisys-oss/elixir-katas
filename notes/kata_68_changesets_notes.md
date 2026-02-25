# Kata 68: Schema-less Changesets

## Goal
Use `Ecto.Changeset` validation power without needing a database schema. Ideal for search forms, wizards, or simple inputs.

## Core Concepts

### 1. `types` and `data`
Define a map of field types (`%{name: :string}`) and a map of data (`%{name: "Bob"}`).

### 2. `cast/3` and `validate_*`
Use the standard Ecto API.
```elixir
{%{}, types}
|> Ecto.Changeset.cast(params, Map.keys(types))
|> validate_required([...])
```

## Implementation Details

1.  **Form**: Use standard inputs.
2.  **Events**: `submit_form` calls a custom validator (Kata simulates Ecto behavior manually for simplicity, but the concept stands).

## Tips
- In real apps, creating a dedicated embedded schema (`embedded_schema`) module is often cleaner than raw schemaless changesets.

## Challenge
Add a **"Bio"** field. Enforce a maximum length of **10 characters**.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># Add "bio" to map.
# In validate logic:
if String.length(bio) > 10, do: error, else: ok
</code></pre>
</details>
