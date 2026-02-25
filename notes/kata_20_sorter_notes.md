# Kata 20: The Sorter

## The Concept
**Data Grids**. Sorting by columns (Ascending/Descending).

## The Elixir Way
*   **State**: We track `sort_by` (atom) and `sort_order` (:asc/:desc).
*   **Logic**: `Enum.sort_by` is a stable sort algorithm.

## Deep Dive

### 1. The Toggle Logic
```elixir
if current_field == new_field do
  toggle_order(current_order) # asc -> desc
else
  :asc # New field always starts ascending
end
```
This is a standard UX pattern.

### 2. In-Memory vs Database Sorting
*   **In-Memory**: `Enum.sort_by` works great for lists < 10,000 items loaded in the LiveView.
*   **Database**: For paginated data, you **MUST** sort in the database (`order_by(query, ...)`). Sorting page 1 of 100 in memory is incorrect (it only sorts the 10 visible items, not the whole dataset).

### 3. Atoms vs Strings
We use atoms (`:name`, `:age`) for internal logic, but HTML attributes send strings (`"name"`).
`String.to_existing_atom/1` is safer than `String.to_atom/1` to prevent Denial of Service (filling the atom table), but for fixed column names, explicit pattern matching or a whitelist is best.
```elixir
defp to_column("name"), do: :name
defp to_column("age"), do: :age
```

## Common Pitfalls

1.  **Nil Values**: `Enum.sort` behavior with `nil` can be surprising (nil is usually "smaller" than everything else in Elixir sorting terms).
2.  **Stable Sorting**: If you sort by "Role", the order of "Names" within that role is arbitrary unless you do a composite sort (`primary: role, secondary: name`).
