# Kata 97: Image Processing

## Goal
Process uploaded images (Resize, Convert, Filter) using `Mogrify` (ImageMagick wrapper).

## Core Concepts

### 1. Processing Pipeline
Consume upload -> Temp Path -> `Mogrify.open()` -> `resize()` -> `save()`.

### 2. Display
Serve the processed file from `priv/static/uploads`.

## Implementation Details

1.  **Deps**: Requires `mogrify` and system `imagemagick` installed.
2.  **Code**: See logic in `handle_event("save", ...)`

## Tips
- Image processing is CPU intensive. In production, offload this to a background job (Oban) instead of blocking the LiveView process.

## Challenge
Add **Rotation**. Add a specific button "Is Rotation Needed?" (checkbox). If checked, rotate the image **90 degrees** clockwise during processing.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">|> custom("rotate", "90")
</code></pre>
</details>
