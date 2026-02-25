# Kata 21: The Paginator

## Goal
Implement **offset-based pagination** to handle large datasets by displaying a subset of items at a time.

## Core Concepts

### 1. Pagination Params
You need two key integers:
- `page`: The current page number (1-based index).
- `per_page`: Number of items per page.

### 2. Slicing Data
In a real application, you'd use Ecto's `limit` and `offset`. Within a LiveView list, we simulate this with `Enum.slice`.

```elixir
start = (page - 1) * per_page
Enum.slice(all_items, start, per_page)
```

### 3. Total Pages
To disable "Next" appropriately, you must know the total count.
`ceil(total_items / per_page)`

## Implementation Details

1.  **State**: `items` (list), `page` (1), `per_page` (5).
2.  **UI**:
    - List rendering the sliced subset.
    - Previous/Next buttons (disabled at boundaries).
3.  **Events**:
    - `prev`: `max(page - 1, 1)`
    - `next`: `min(page + 1, total_pages)`

## Tips
- Calculating the slice in a helper function or computed assign keeps the render function clean.

## Challenge
Add a **Jump to Page** input. allowing the user to type a page number and go there on Enter (or Blur). Handle invalid numbers gracefully.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("jump", %{"page" => p}, socket) do
  p = String.to_integer(p)
  new_page = p |> max(1) |> min(total_pages(socket.assigns.items, ...))
  {:noreply, assign(socket, page: new_page)}
end</code></pre>
</details>
