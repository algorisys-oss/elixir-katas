# Kata 98: PDF Generation

## Goal
Generate PDF documents from HTML content using `wkhtmltopdf` (via `pdf_generator` or similar lib).

## Core Concepts

### 1. LiveView vs Controller
LiveView cannot "stream" a file download directly in the WebSocket.
Instead, you typically:
a) Generate the PDF to a temp path and redirect to a controller serving it `local_path`.
b) Submit a regular form (non-phx) to a controller that returns raw PDF binary with `send_download`.

### 2. The Demo
Uses a standard HTML `<form action="/exports/pdf" method="post">` to bypass WebSocket and do a standard POST.

## Implementation Details

1.  **Controller endpoint**: Handles the POST, renders HTML layout, converts to PDF, sends response.

## Tips
- Styling PDFs is hard. Using a specific simplistic CSS file for the print layout often works best.

## Challenge
**Markdown Support**.
Use `Earmark` to convert the "Body" textarea from Markdown to HTML before generating the PDF. (This logic goes in the Controller, but conceptually it's part of the feature).
**UI Challenge**: Add a "Preview" tab that renders the Markdown as HTML in the browser so the user can see what it will look like.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"><%= Earmark.as_html!(@form[:body].value) |> raw() %>
</code></pre>
</details>
