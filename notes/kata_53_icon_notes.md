# Kata 53: The Icon System

## The Concept
 managing 1,000 SVGs. Copy-pasting `<svg>...</svg>` bloats templates.
We need a clean `<.icon name="hero-user" />` API.

## The Elixir Way
Phoenix 1.7 ships with a native `CoreComponents.icon/1` that reads icons from the filesystem at compile time!
*   **Source**: `/assets/vendor/heroicons`.
*   **Embed**: The SVG content is injected directly into the HTML (not an `<img>` tag), allowing CSS styling (fill/stroke) to work.

## Deep Dive

### 1. Tailwind Integration
Modern icons often use `currentColor`.
```html
<svg class="w-6 h-6 text-red-500" ...>
```
The `text-red-500` class sets the CSS `color` property. The SVG `stroke="currentColor"` inherits this. This allows you to color icons easily with utility classes.

### 2. Pattern Matching in Render
If building manually:
```elixir
defp icon(%{name: "user"} = assigns), do: ~H"<svg>...</svg>"
defp icon(%{name: "cog"} = assigns), do: ~H"<svg>...</svg>"
```
This works but is tedious. The "Heroicons" pattern (loading from disk) is scalable.

## Common Pitfalls

1.  **Flash of Unstyled Content**: SVGs with no size dimensions can blow up to huge sizes before CSS loads. Always set default `w-5 h-5` classes.
2.  **Accessibility**: Decorative icons should have `aria-hidden="true"`. Semantic icons (like a standalone "Save" floppy disk) need a screen-reader label (`aria-label` or `<span class="sr-only">`).
