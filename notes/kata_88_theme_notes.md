# Kata 88: Theme Switcher

## Goal
Toggle between Light and Dark modes.

## Core Concepts

### 1. `class` Toggle
Simply swapping `bg-white text-black` for `bg-gray-900 text-white`.

### 2. Persistence
Ideally, save preference to cookie or localStorage (see Kata 87).

## Implementation Details

1.  **State**: `theme` ("light" | "dark").
2.  **Logic**: `if theme == "dark", do: "dark-classes", else: "light-classes"`.

## Tips
- Tailwind's `dark:` modifier works well if you set `darkMode: 'class'` in config and toggle a class on the `<html>` element.

## Challenge
**System Preference Detection**.
Update the Hook to check `window.matchMedia('(prefers-color-scheme: dark)').matches`.
On mount, send this preference to the server to set the initial theme automatically.

<details>
<summary>View Solution</summary>

<pre><code class="javascript">mounted() {
  const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  this.pushEvent("set_theme", {theme: isDark ? "dark" : "light"});
}
</code></pre>
</details>
