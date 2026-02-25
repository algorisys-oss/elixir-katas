# Kata 99: CSV Export

## Goal
Export data lists to CSV format.

## Core Concepts

### 1. `NimbleCSV`
Efficient CSV generation library.

### 2. Triggering Download
Similar to PDF, easiest via a Controller.
Or: Generate data in LiveView -> `Base64` encode -> Push event -> JS triggers download of Data URI (okay for small files).

## Implementation Details

1.  **Link**: `<a href="/exports/csv">` triggers the controller action.

## Tips
- For large datasets, stream the CSV response chunk-by-chunk using `Plug.Conn.chunk`.

## Challenge
**Column Selection**.
Add checkboxes for "Include ID", "Include Role", etc.
Pass these as query params to the export link: `/exports/csv?columns=id,role`.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">href={"/exports/csv?columns=#{@selected_columns_joined}"}
</code></pre>
</details>
