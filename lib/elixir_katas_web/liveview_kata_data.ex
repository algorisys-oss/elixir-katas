defmodule ElixirKatasWeb.LiveviewKataData do
  @moduledoc """
  Shared data module for LiveView Katas sections, tags, and colors.
  Used by both the sidebar layout and the index page.
  """

  @tag_colors %{
    "state" => "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
    "events" => "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200",
    "forms" => "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
    "components" => "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200",
    "navigation" => "bg-cyan-100 text-cyan-800 dark:bg-cyan-900 dark:text-cyan-200",
    "pubsub" => "bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-200",
    "js-interop" => "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200",
    "streams" => "bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200",
    "uploads" => "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200",
    "render" => "bg-teal-100 text-teal-800 dark:bg-teal-900 dark:text-teal-200",
    "lifecycle" => "bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200",
    "ecto" => "bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200",
    "async" => "bg-violet-100 text-violet-800 dark:bg-violet-900 dark:text-violet-200",
    "otp" => "bg-rose-100 text-rose-800 dark:bg-rose-900 dark:text-rose-200"
  }

  def all_tags, do: Map.keys(@tag_colors) |> Enum.sort()
  def tag_color(tag), do: Map.get(@tag_colors, tag, "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200")

  def sections do
    [
      %{title: "Section 1: Basics & State", katas: [
        %{num: "00", slug: "00-liveview-basics", label: "00 - LiveView Basics", color: "bg-indigo-600", tags: ["lifecycle", "render"], description: "Core LiveView lifecycle and concepts"},
        %{num: "01", slug: "01-hello-world", label: "01 - Hello World", color: "bg-green-400", tags: ["render"], description: "Your first step into Phoenix LiveView"},
        %{num: "02", slug: "02-counter", label: "02 - Counter", color: "bg-blue-400", tags: ["state", "events"], description: "State management with increment, decrement, and reset"},
        %{num: "03", slug: "03-mirror", label: "03 - The Mirror", color: "bg-purple-400", tags: ["state", "forms"], description: "Form bindings and real-time updates"},
        %{num: "04", slug: "04-toggler", label: "04 - The Toggler", color: "bg-orange-400", tags: ["state", "render"], description: "Conditional rendering and CSS class switching"},
        %{num: "05", slug: "05-color-picker", label: "05 - Color Picker", color: "bg-pink-400", tags: ["state", "render"], description: "Multiple state values with inline styles"},
        %{num: "06", slug: "06-resizer", label: "06 - The Resizer", color: "bg-teal-400", tags: ["state", "render"], description: "Binding integer state to CSS properties"},
        %{num: "07", slug: "07-spoiler", label: "07 - The Spoiler", color: "bg-yellow-400", tags: ["state", "render"], description: "Click to reveal with boolean state and CSS blur"},
        %{num: "08", slug: "08-accordion", label: "08 - The Accordion", color: "bg-cyan-400", tags: ["state", "render"], description: "One active item at a time pattern"},
        %{num: "09", slug: "09-tabs", label: "09 - The Tabs", color: "bg-indigo-400", tags: ["state", "render"], description: "Switch content based on active tab state"},
        %{num: "10", slug: "10-character-counter", label: "10 - Character Counter", color: "bg-red-400", tags: ["state", "forms"], description: "Real-time string length with limit validation"},
        %{num: "11", slug: "11-stopwatch", label: "11 - The Stopwatch", color: "bg-blue-400", tags: ["state", "lifecycle"], description: "Server-driven timer using process messages"},
        %{num: "12", slug: "12-timer", label: "12 - The Timer", color: "bg-orange-400", tags: ["state", "lifecycle"], description: "Countdown timer with auto-termination"},
        %{num: "13", slug: "13-events-mastery", label: "13 - Events Mastery", color: "bg-green-400", tags: ["events"], description: "Focus, blur, and keyup events with logging"},
        %{num: "14", slug: "14-keybindings", label: "14 - Keybindings", color: "bg-purple-400", tags: ["events", "js-interop"], description: "Global keyboard shortcuts with phx-window-keydown"},
        %{num: "15", slug: "15-calculator", label: "15 - The Calculator", color: "bg-gray-400", tags: ["state", "events"], description: "Complex state management simulating a calculator"}
      ]},
      %{title: "Section 2: Lists & Data", katas: [
        %{num: "16", slug: "16-list", label: "16 - The List", color: "bg-indigo-400", tags: ["state", "render"], description: "Render a list and append new items"},
        %{num: "17", slug: "17-remover", label: "17 - The Remover", color: "bg-red-400", tags: ["state", "events"], description: "Remove specific items from a list by ID"},
        %{num: "18", slug: "18-editor", label: "18 - The Editor", color: "bg-yellow-400", tags: ["state", "forms"], description: "Inline editing of list items"},
        %{num: "19", slug: "19-filter", label: "19 - The Filter", color: "bg-cyan-400", tags: ["state", "render"], description: "Real-time client-side filtering of data"},
        %{num: "20", slug: "20-sorter", label: "20 - The Sorter", color: "bg-teal-400", tags: ["state", "render"], description: "Sort a table by column headers"},
        %{num: "21", slug: "21-paginator", label: "21 - The Paginator", color: "bg-purple-400", tags: ["state", "navigation"], description: "Simple offset-based pagination"},
        %{num: "22", slug: "22-highlighter", label: "22 - The Highlighter", color: "bg-yellow-400", tags: ["state", "render"], description: "Highlighting search terms within text"},
        %{num: "23", slug: "23-multi-select", label: "23 - The Multi-Select", color: "bg-blue-400", tags: ["state", "events"], description: "Selecting multiple items with MapSet"},
        %{num: "24", slug: "24-grid", label: "24 - The Grid", color: "bg-cyan-400", tags: ["render", "components"], description: "Rendering data in a responsive grid layout"},
        %{num: "25", slug: "25-tree", label: "25 - The Tree", color: "bg-indigo-400", tags: ["render", "components"], description: "Recursive rendering of nested data structures"}
      ]},
      %{title: "Section 3: Forms & Validation", katas: [
        %{num: "26", slug: "26-text-input", label: "26 - The Text Input", color: "bg-green-400", tags: ["forms"], description: "Basic text input, form bindings, and submission"},
        %{num: "27", slug: "27-checkbox", label: "27 - The Checkbox", color: "bg-red-400", tags: ["forms"], description: "Boolean state toggling with checkboxes"},
        %{num: "28", slug: "28-radio-buttons", label: "28 - Radio Buttons", color: "bg-blue-400", tags: ["forms"], description: "Mutually exclusive selection using radio inputs"},
        %{num: "29", slug: "29-select", label: "29 - The Select", color: "bg-green-400", tags: ["forms"], description: "Single selection from a dropdown list"},
        %{num: "30", slug: "30-multi-select-form", label: "30 - Multi-Select Form", color: "bg-orange-400", tags: ["forms"], description: "Handling multiple selections with HTML select"},
        %{num: "31", slug: "31-dependent-inputs", label: "31 - Dependent Inputs", color: "bg-purple-400", tags: ["forms", "state"], description: "Dynamic dropdowns with dependent selections"},
        %{num: "32", slug: "32-comparison-validation", label: "32 - Comparison Validation", color: "bg-pink-400", tags: ["forms"], description: "Validating that two fields match"},
        %{num: "33", slug: "33-formats", label: "33 - Formats", color: "bg-blue-400", tags: ["forms"], description: "Regex validation for Email and Phone numbers"},
        %{num: "34", slug: "34-live-feedback", label: "34 - Live Feedback", color: "bg-green-400", tags: ["forms", "events"], description: "Showing validation errors after user interaction"},
        %{num: "35", slug: "35-form-restoration", label: "35 - Form Restoration", color: "bg-red-400", tags: ["forms", "lifecycle"], description: "Recovering form state after server crash"},
        %{num: "36", slug: "36-debounce", label: "36 - Debounce", color: "bg-purple-400", tags: ["forms", "events"], description: "Delaying search requests while typing"},
        %{num: "37", slug: "37-wizard", label: "37 - The Wizard", color: "bg-pink-400", tags: ["forms", "state"], description: "Multi-step form accumulating data across steps"},
        %{num: "38", slug: "38-tag-input", label: "38 - The Tag Input", color: "bg-green-400", tags: ["forms", "components"], description: "Entering multiple values as pills using Enter or Comma"},
        %{num: "39", slug: "39-rating", label: "39 - The Rating Input", color: "bg-orange-400", tags: ["forms", "components"], description: "Custom star rating component"},
        %{num: "40", slug: "40-uploads", label: "40 - File Uploads", color: "bg-red-400", tags: ["forms", "uploads"], description: "Core LiveView file upload with drag & drop"}
      ]},
      %{title: "Section 4: Navigation & Routing", katas: [
        %{num: "41", slug: "41-url-params", label: "41 - URL Params", color: "bg-blue-500", tags: ["navigation"], description: "Query string parameters with handle_params/3"},
        %{num: "42", slug: "42-path-params/1", label: "42 - Path Params", color: "bg-green-500", tags: ["navigation"], description: "Dynamic route segments like /user/:id"},
        %{num: "43", slug: "43-navbar", label: "43 - The Nav Bar", color: "bg-purple-500", tags: ["navigation", "components"], description: "Active link highlighting based on current URI"},
        %{num: "44", slug: "44-breadcrumb", label: "44 - The Breadcrumb", color: "bg-pink-500", tags: ["navigation", "components"], description: "Dynamic navigation hierarchy based on path"},
        %{num: "45", slug: "45-tabs-url", label: "45 - Tabs with URL", color: "bg-indigo-500", tags: ["navigation", "state"], description: "Syncing tab state to URL query parameters"},
        %{num: "46", slug: "46-search-url", label: "46 - Search with URL", color: "bg-cyan-500", tags: ["navigation", "forms"], description: "Deep linking search results via URL params"},
        %{num: "47", slug: "47-protected", label: "47 - Protected Routes", color: "bg-orange-500", tags: ["navigation", "lifecycle"], description: "Redirecting unauthenticated users with on_mount"},
        %{num: "48", slug: "48-redirects", label: "48 - Live Redirects", color: "bg-teal-500", tags: ["navigation"], description: "Understanding push_navigate vs push_patch"},
        %{num: "49", slug: "49-translator", label: "49 - The Translator", color: "bg-yellow-500", tags: ["navigation", "state"], description: "Switching locales and i18n patterns"}
      ]},
      %{title: "Section 5: Components & UI", katas: [
        %{num: "50", slug: "50-components", label: "50 - Functional Components", color: "bg-red-500", tags: ["components"], description: "Reusable components with attr and slot"},
        %{num: "51", slug: "51-card", label: "51 - The Card", color: "bg-blue-500", tags: ["components"], description: "Slots for header, body, footer"},
        %{num: "52", slug: "52-button", label: "52 - The Button", color: "bg-green-500", tags: ["components"], description: "Variants, sizes, loading states"},
        %{num: "53", slug: "53-icon", label: "53 - The Icon", color: "bg-purple-500", tags: ["components"], description: "Wrapping SVG icon libraries"},
        %{num: "54", slug: "54-modal", label: "54 - The Modal", color: "bg-pink-500", tags: ["components", "js-interop"], description: "Global UI state with JS commands"},
        %{num: "55", slug: "55-slideover", label: "55 - The Slide-over", color: "bg-indigo-500", tags: ["components", "js-interop"], description: "Drawer component with transitions"},
        %{num: "56", slug: "56-tooltip", label: "56 - The Tooltip", color: "bg-cyan-500", tags: ["components"], description: "CSS-only tooltips"},
        %{num: "57", slug: "57-dropdown", label: "57 - The Dropdown", color: "bg-orange-500", tags: ["components", "js-interop"], description: "Menu with click-outside detection"},
        %{num: "58", slug: "58-flash", label: "58 - Flash Messages", color: "bg-teal-500", tags: ["components", "lifecycle"], description: "Auto-dismissing toast notifications"},
        %{num: "59", slug: "59-skeleton", label: "59 - The Skeleton", color: "bg-yellow-500", tags: ["components", "render"], description: "Loading state placeholders"},
        %{num: "60", slug: "60-progress", label: "60 - The Progress Bar", color: "bg-red-500", tags: ["components", "async"], description: "Server-driven progress updates"}
      ]},
      %{title: "Section 6: LiveComponents", katas: [
        %{num: "61", slug: "61-stateful", label: "61 - Stateful Component", color: "bg-blue-500", tags: ["components", "lifecycle"], description: "LiveComponent lifecycle"},
        %{num: "62", slug: "62-component-id", label: "62 - Component ID", color: "bg-green-500", tags: ["components"], description: "Managing unique IDs"},
        %{num: "63", slug: "63-send-update", label: "63 - Send Update", color: "bg-purple-500", tags: ["components", "events"], description: "Parent updating child state"},
        %{num: "64", slug: "64-send-self", label: "64 - Send Self", color: "bg-pink-500", tags: ["components", "events"], description: "Child updating its own state"},
        %{num: "65", slug: "65-child-parent", label: "65 - Child-to-Parent", color: "bg-indigo-500", tags: ["components", "events"], description: "Messaging up the tree"},
        %{num: "66", slug: "66-sibling", label: "66 - Sibling Communication", color: "bg-cyan-500", tags: ["components", "events"], description: "Via parent coordinator"},
        %{num: "67", slug: "67-lazy", label: "67 - Lazy Loading", color: "bg-orange-500", tags: ["components", "async"], description: "Async component loading"}
      ]},
      %{title: "Section 7: Data & Persistence", katas: [
        %{num: "68", slug: "68-changesets", label: "68 - Changesets 101", color: "bg-teal-500", tags: ["ecto", "forms"], description: "Schema-less changesets"},
        %{num: "69", slug: "69-crud", label: "69 - The CRUD", color: "bg-yellow-500", tags: ["ecto", "forms"], description: "Full CRUD operations"},
        %{num: "70", slug: "70-optimistic", label: "70 - Optimistic UI", color: "bg-red-500", tags: ["state", "async"], description: "Update before server confirms"},
        %{num: "71", slug: "71-streams", label: "71 - Streams Basic", color: "bg-blue-500", tags: ["streams", "render"], description: "Efficient large list handling"},
        %{num: "72", slug: "72-infinite-scroll", label: "72 - Infinite Scroll", color: "bg-green-500", tags: ["streams", "js-interop"], description: "Pagination with scroll detection"},
        %{num: "73", slug: "73-stream-insert-delete", label: "73 - Stream Insert/Delete", color: "bg-purple-500", tags: ["streams"], description: "Real-time stream updates"},
        %{num: "74", slug: "74-stream-reset", label: "74 - Stream Reset", color: "bg-pink-500", tags: ["streams"], description: "Clear and repopulate streams"},
        %{num: "75", slug: "75-bulk-actions", label: "75 - Bulk Actions", color: "bg-indigo-500", tags: ["streams", "events"], description: "Multi-select operations"}
      ]},
      %{title: "Section 8: Real-time & PubSub", katas: [
        %{num: "76", slug: "76-clock", label: "76 - The Clock", color: "bg-blue-500", tags: ["pubsub", "lifecycle"], description: "Server interval updates"},
        %{num: "77", slug: "77-ticker", label: "77 - The Ticker", color: "bg-indigo-500", tags: ["pubsub", "state"], description: "Stock price simulation"},
        %{num: "78", slug: "78-chat", label: "78 - Chat Room", color: "bg-purple-500", tags: ["pubsub", "forms"], description: "Message broadcasting"},
        %{num: "79", slug: "79-typing", label: "79 - Typing Indicator", color: "bg-pink-500", tags: ["pubsub", "events"], description: "Ephemeral presence"},
        %{num: "80", slug: "80-presence", label: "80 - Presence List", color: "bg-red-500", tags: ["pubsub"], description: "Online users tracking"},
        %{num: "81", slug: "81-cursor", label: "81 - Live Cursor", color: "bg-orange-500", tags: ["pubsub", "js-interop"], description: "Mouse coordinate broadcasting"},
        %{num: "82", slug: "82-notifications", label: "82 - Distributed Notifications", color: "bg-yellow-500", tags: ["pubsub"], description: "Cross-node alerts"},
        %{num: "83", slug: "83-game", label: "83 - The Game State", color: "bg-green-500", tags: ["pubsub", "state"], description: "Multiplayer state synchronization"}
      ]},
      %{title: "Section 9: JS Interop & Hooks", katas: [
        %{num: "84", slug: "84-focus", label: "84 - Accessible Focus", color: "bg-blue-500", tags: ["js-interop"], description: "Focus management"},
        %{num: "85", slug: "85-scroll", label: "85 - Scroll to Bottom", color: "bg-indigo-500", tags: ["js-interop"], description: "Auto-scroll hook"},
        %{num: "86", slug: "86-clipboard", label: "86 - Clipboard Copy", color: "bg-purple-500", tags: ["js-interop"], description: "System clipboard access"},
        %{num: "87", slug: "87-storage", label: "87 - Local Storage", color: "bg-pink-500", tags: ["js-interop"], description: "Browser persistence"},
        %{num: "88", slug: "88-theme", label: "88 - Theme Switcher", color: "bg-red-500", tags: ["js-interop", "state"], description: "Dark/light mode toggling"},
        %{num: "89", slug: "89-chart", label: "89 - Chart.js", color: "bg-orange-500", tags: ["js-interop"], description: "Data visualization"},
        %{num: "90", slug: "90-map", label: "90 - Mapbox", color: "bg-yellow-500", tags: ["js-interop"], description: "Map integration"},
        %{num: "91", slug: "91-masked", label: "91 - Masked Input", color: "bg-green-500", tags: ["js-interop", "forms"], description: "Input formatting"},
        %{num: "92", slug: "92-dropzone", label: "92 - File Dropzone", color: "bg-blue-500", tags: ["js-interop", "uploads"], description: "Drag & drop file handling"},
        %{num: "93", slug: "93-sortable", label: "93 - Sortable List", color: "bg-indigo-500", tags: ["js-interop"], description: "Drag reordering"},
        %{num: "94", slug: "94-audio", label: "94 - Audio Player", color: "bg-purple-500", tags: ["js-interop"], description: "Media control"},
        %{num: "101", slug: "101-hooks", label: "101 - LiveView Hooks", color: "bg-purple-500", tags: ["js-interop", "lifecycle"], description: "JavaScript hooks for client-side interop"}
      ]},
      %{title: "Section 10: Advanced", katas: [
        %{num: "95", slug: "95-async", label: "95 - Async Assigns", color: "bg-pink-500", tags: ["async", "lifecycle"], description: "Non-blocking UI updates"},
        %{num: "96", slug: "96-uploads", label: "96 - File Uploads", color: "bg-red-500", tags: ["uploads"], description: "Advanced upload handling"},
        %{num: "97", slug: "97-images", label: "97 - Image Processing", color: "bg-orange-500", tags: ["uploads", "async"], description: "Image resizing and processing"},
        %{num: "98", slug: "98-pdf", label: "98 - PDF Generation", color: "bg-yellow-500", tags: ["async"], description: "Document generation"},
        %{num: "99", slug: "99-csv", label: "99 - CSV Export", color: "bg-green-500", tags: ["async"], description: "Data export to CSV"},
        %{num: "100", slug: "100-error", label: "100 - Error Boundary", color: "bg-blue-500", tags: ["lifecycle"], description: "Crash handling and recovery"},
        %{num: "104", slug: "104-genserver", label: "104 - GenServer Integration", color: "bg-indigo-500", tags: ["otp", "lifecycle"], description: "Background workers with LiveView"},
        %{num: "125", slug: "125-statemachine", label: "125 - State Machine", color: "bg-yellow-500", tags: ["otp", "state"], description: "Complex workflows with :gen_statem"},
        %{num: "139", slug: "139-virtual-scrolling", label: "139 - Virtual Scrolling", color: "bg-orange-500", tags: ["render", "js-interop"], description: "Efficiently rendering large datasets"},
        %{num: "140", slug: "140-confirm-dialog", label: "140 - Confirm Dialog", color: "bg-teal-500", tags: ["components", "forms"], description: "Form with data confirmation modal"}
      ]}
    ]
  end
end
