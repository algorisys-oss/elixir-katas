defmodule ElixirKatasWeb.KatasIndexLive do
  use ElixirKatasWeb, :live_view
  import ElixirKatasWeb.KataComponents

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8">
      <h1 class="text-3xl font-bold mb-8 text-gray-900 dark:text-white">
        Welcome to Phoenix LiveView Katas
      </h1>
      <p class="text-lg text-gray-600 dark:text-gray-300 mb-8">
        Select a kata from the sidebar or the list below to begin your journey.
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <.link navigate="/katas/01-hello-world" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-green-500 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">01 - Hello World</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Your first step into Phoenix LiveView. Learn the basics of rendering and event handling.
          </p>
        </.link>

        <.link navigate="/katas/02-counter" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-blue-500 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">02 - Counter</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Master state management. Build a counter with increment, decrement, and reset functionality.
          </p>
        </.link>

        <.link navigate="/katas/03-mirror" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-purple-500 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">03 - The Mirror</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Form bindings and real-time updates. mirroring input text instantly to the UI.
          </p>
        </.link>

        <.link navigate="/katas/04-toggler" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-orange-500 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">04 - The Toggler</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Learn conditional rendering (`if`) and how to switch CSS classes dynamically based on state.
          </p>
        </.link>

        <.link navigate="/katas/05-color-picker" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-pink-500 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">05 - The Color Picker</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Manage multiple state values (`r, g, b`) and apply inline styles dynamically.
          </p>
        </.link>

        <.link navigate="/katas/06-resizer" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-teal-500 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">06 - The Resizer</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Learn to bind integer state to CSS `width` and `height` properties.
          </p>
        </.link>

        <.link navigate="/katas/07-spoiler" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-yellow-500 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">07 - The Spoiler</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Create a "click to reveal" component using boolean state and CSS blur filters.
          </p>
        </.link>

        <.link navigate="/katas/08-accordion" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-cyan-500 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">08 - The Accordion</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Manage a collection of items where only one can be active at a time (`active_id`).
          </p>
        </.link>
        <.link navigate="/katas/09-tabs" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-indigo-500 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">09 - The Tabs</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Switch content based on active tab state.
          </p>
        </.link>

        <.link navigate="/katas/10-character-counter" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-red-500 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">10 - Character Counter</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Real-time string length calculation with limit validation and visual feedback.
          </p>
        </.link>
        <.link navigate="/katas/11-stopwatch" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-blue-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">11 - The Stopwatch</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            A server-driven timer using process messages and interval handling.
          </p>
        </.link>

        <.link navigate="/katas/12-timer" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-orange-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">12 - The Timer</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Countdown timer with start/stop/reset and auto-termination.
          </p>
        </.link>

        <.link navigate="/katas/13-events-mastery" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-green-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">13 - Events Mastery</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Explore focus, blur, and keyup events with real-time logging.
          </p>
        </.link>

        <.link navigate="/katas/14-keybindings" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-purple-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">14 - Keybindings</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Global window keyboard shortcuts with <code>phx-window-keydown</code>.
          </p>
        </.link>

        <.link navigate="/katas/15-calculator" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-gray-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">15 - The Calculator</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Complex state management simulating a real calculator.
          </p>
        </.link>

        <.link navigate="/katas/16-list" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-indigo-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">16 - The List</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Render a list and append new items.
          </p>
        </.link>

        <.link navigate="/katas/17-remover" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-red-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">17 - The Remover</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Remove specific items from a list by ID.
          </p>
        </.link>

        <.link navigate="/katas/18-editor" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-yellow-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">18 - The Editor</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Inline editing of list items.
          </p>
        </.link>

        <.link navigate="/katas/19-filter" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-cyan-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">19 - The Filter</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Real-time client-side filtering of data.
          </p>
        </.link>

        <.link navigate="/katas/20-sorter" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-teal-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">20 - The Sorter</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Sort a table by column headers (asc/desc).
          </p>
        </.link>
        <.link navigate="/katas/21-paginator" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-purple-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">21 - The Paginator</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Simple offset-based pagination Logic.
          </p>
        </.link>

        <.link navigate="/katas/22-highlighter" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-yellow-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">22 - The Highlighter</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Highlighting search terms within text.
          </p>
        </.link>

        <.link navigate="/katas/23-multi-select" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-blue-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">23 - The Multi-Select</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Selecting multiple items from a list with MapSet.
          </p>
        </.link>

        <.link navigate="/katas/24-grid" class="card bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 p-6 rounded-lg group">
          <div class="flex items-center mb-4">
            <span class="w-3 h-3 rounded-full bg-cyan-600 mr-3"></span>
            <h2 class="text-xl font-semibold group-hover:text-primary transition-colors">24 - The Grid</h2>
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            Rendering data in a responsive grid layout.
          </p>
        </.link>

        <.kata_card
        title="25. The Tree"
        description="Recursive rendering of nested data structures."
        path={~p"/katas/25-tree"}
      />
      <.kata_card
        title="26. The Text Input"
        description="Handling basic text input, form bindings, and submission."
        path={~p"/katas/26-text-input"}
      />
      <.kata_card
        title="27. The Checkbox"
        description="Boolean state toggling with checkboxes and hidden inputs."
        path={~p"/katas/27-checkbox"}
      />
      <.kata_card
        title="28. Radio Buttons"
        description="Mutually exclusive selection using radio inputs."
        path={~p"/katas/28-radio-buttons"}
      />
      <.kata_card
        title="29. The Select"
        description="Single selection from a dropdown list."
        path={~p"/katas/29-select"}
      />
      <.kata_card
        title="30. The Multi-Select Form"
        description="Handling multiple selections with standard HTML select."
        path={~p"/katas/30-multi-select-form"}
      />
      <.kata_card
        title="31. Dependent Inputs"
        description="Dynamic dropdowns where choices depend on previous selections."
        path={~p"/katas/31-dependent-inputs"}
      />
      <.kata_card
        title="32. Comparison Validation"
        description="Validating that two fields match (e.g. Password Confirmation)."
        path={~p"/katas/32-comparison-validation"}
      />
      <.kata_card
        title="33. Formats"
        description="Regex validation for Email and Phone numbers."
        path={~p"/katas/33-formats"}
      />
      <.kata_card
        title="34. Live Feedback"
        description="Showing validation errors only after user interaction (blur)."
        path={~p"/katas/34-live-feedback"}
      />
      <.kata_card
        title="35. Form Restoration"
        description="Recovering form state after a server crash/reconnect."
        path={~p"/katas/35-form-restoration"}
      />
      <.kata_card
        title="36. Debounce"
        description="Delaying search requests while typing to reduce server load."
        path={~p"/katas/36-debounce"}
      />
      <.kata_card
        title="37. The Wizard"
        description="A multi-step form that accumulates data across steps."
        path={~p"/katas/37-wizard"}
      />
      <.kata_card
        title="38. Tag Input"
        description="Entering multiple values as pills (chips) using Enter or Comma."
        path={~p"/katas/38-tag-input"}
      />
      <.kata_card
        title="39. Rating Input"
        description="Custom star rating component with hidden input synchronization."
        path={~p"/katas/39-rating"}
      />
      <.kata_card
        title="40. File Uploads"
        description="Core LiveView file upload functionality with drag & drop."
        path={~p"/katas/40-uploads"}
      />
      <.kata_card
        title="41. URL Params"
        description="Handling query string parameters with handle_params/3."
        path={~p"/katas/41-url-params"}
      />
      <.kata_card
        title="42. Path Params"
        description="Dynamic route segments like /user/:id."
        path={~p"/katas/42-path-params/1"}
      />
      <.kata_card
        title="43. The Nav Bar"
        description="Active link highlighting based on current URI."
        path={~p"/katas/43-navbar"}
      />
      <.kata_card
        title="44. The Breadcrumb"
        description="Dynamic navigation hierarchy based on path."
        path={~p"/katas/44-breadcrumb"}
      />
      <.kata_card
        title="45. Tabs with URL"
        description="Syncing tab state to URL query parameters."
        path={~p"/katas/45-tabs-url"}
      />
      <.kata_card
        title="46. Search with URL"
        description="Deep linking search results via URL params."
        path={~p"/katas/46-search-url"}
      />
      <.kata_card
        title="47. Protected Routes"
        description="Redirecting unauthenticated users with on_mount."
        path={~p"/katas/47-protected"}
      />
      <.kata_card
        title="48. Live Redirects"
        description="Understanding push_navigate vs push_patch."
        path={~p"/katas/48-redirects"}
      />
      <.kata_card
        title="49. The Translator"
        description="Switching locales and i18n patterns."
        path={~p"/katas/49-translator"}
      />
      <.kata_card
        title="50. Functional Components"
        description="Creating reusable components with attr and slot."
        path={~p"/katas/50-components"}
      />
      <.kata_card title="51. The Card" description="Slots for header, body, footer" path={~p"/katas/51-card"} />
      <.kata_card title="52. The Button" description="Variants, sizes, loading states" path={~p"/katas/52-button"} />
      <.kata_card title="53. The Icon" description="Wrapping SVG icon libraries" path={~p"/katas/53-icon"} />
      <.kata_card title="54. The Modal" description="Global UI state with JS commands" path={~p"/katas/54-modal"} />
      <.kata_card title="55. The Slide-over" description="Drawer component with transitions" path={~p"/katas/55-slideover"} />
      <.kata_card title="56. The Tooltip" description="CSS-only tooltips" path={~p"/katas/56-tooltip"} />
      <.kata_card title="57. The Dropdown" description="Menu with click-outside detection" path={~p"/katas/57-dropdown"} />
      <.kata_card title="58. Flash Messages" description="Auto-dismissing toast notifications" path={~p"/katas/58-flash"} />
      <.kata_card title="59. The Skeleton" description="Loading state placeholders" path={~p"/katas/59-skeleton"} />
      <.kata_card title="60. The Progress Bar" description="Server-driven progress updates" path={~p"/katas/60-progress"} />
      <.kata_card title="61. Stateful Component" description="LiveComponent lifecycle" path={~p"/katas/61-stateful"} />
      <.kata_card title="62. Component ID" description="Managing unique IDs" path={~p"/katas/62-component-id"} />
      <.kata_card title="63. Send Update" description="Parent updating child state" path={~p"/katas/63-send-update"} />
      <.kata_card title="64. Send Self" description="Child updating its own state" path={~p"/katas/64-send-self"} />
      <.kata_card title="65. Child-to-Parent" description="Messaging up the tree" path={~p"/katas/65-child-parent"} />
      <.kata_card title="66. Sibling Communication" description="Via parent coordinator" path={~p"/katas/66-sibling"} />
      <.kata_card title="67. Lazy Loading" description="Async component loading" path={~p"/katas/67-lazy"} />
      <.kata_card title="68. Changesets 101" description="Schema-less changesets" path={~p"/katas/68-changesets"} />
      <.kata_card title="69. The CRUD" description="Full CRUD operations" path={~p"/katas/69-crud"} />
      <.kata_card title="70. Optimistic UI" description="Update before server confirms" path={~p"/katas/70-optimistic"} />
      <.kata_card title="71. Streams Basic" description="Efficient large list handling" path={~p"/katas/71-streams"} />
      <.kata_card title="72. Infinite Scroll" description="Pagination with scroll detection" path={~p"/katas/72-infinite-scroll"} />
      <.kata_card title="73. Stream Insert/Delete" description="Real-time stream updates" path={~p"/katas/73-stream-insert-delete"} />
      <.kata_card title="74. Stream Reset" description="Clear and repopulate streams" path={~p"/katas/74-stream-reset"} />
      <.kata_card title="75. Bulk Actions" description="Multi-select operations" path={~p"/katas/75-bulk-actions"} />
      <.kata_card title="76. The Clock" description="Server interval updates" path={~p"/katas/76-clock"} />
      <.kata_card title="77. The Ticker" description="Stock price simulation" path={~p"/katas/77-ticker"} />
      <.kata_card title="78. Chat Room" description="Message broadcasting" path={~p"/katas/78-chat"} />
      <.kata_card title="79. Typing Indicator" description="Ephemeral presence" path={~p"/katas/79-typing"} />
      <.kata_card title="80. Presence List" description="Online users" path={~p"/katas/80-presence"} />
      <.kata_card title="81. Live Cursor" description="Mouse coordinates" path={~p"/katas/81-cursor"} />
      <.kata_card title="82. Distributed Notifications" description="Cross-node alerts" path={~p"/katas/82-notifications"} />
      <.kata_card title="83. The Game State" description="Multiplayer state" path={~p"/katas/83-game"} />
      <.kata_card title="84. Accessible Focus" description="Focus management" path={~p"/katas/84-focus"} />
      <.kata_card title="85. Scroll to Bottom" description="Auto-scroll hook" path={~p"/katas/85-scroll"} />
      <.kata_card title="86. Clipboard Copy" description="System clipboard" path={~p"/katas/86-clipboard"} />
      <.kata_card title="87. Local Storage" description="Browser persistence" path={~p"/katas/87-storage"} />
      <.kata_card title="88. Theme Switcher" description="Dark/light mode" path={~p"/katas/88-theme"} />
      <.kata_card title="89. Chart.js" description="Data visualization" path={~p"/katas/89-chart"} />
      <.kata_card title="90. Mapbox" description="Map integration" path={~p"/katas/90-map"} />
      <.kata_card title="91. Masked Input" description="Input formatting" path={~p"/katas/91-masked"} />
      <.kata_card title="92. File Dropzone" description="Drag & drop" path={~p"/katas/92-dropzone"} />
      <.kata_card title="93. Sortable List" description="Drag reordering" path={~p"/katas/93-sortable"} />
      <.kata_card title="94. Audio Player" description="Media control" path={~p"/katas/94-audio"} />
      <.kata_card title="95. Async Assigns" description="Non-blocking UI" path={~p"/katas/95-async"} />
      <.kata_card title="96. File Uploads" description="Upload handling" path={~p"/katas/96-uploads"} />
      <.kata_card title="97. Image Processing" description="Image resizing" path={~p"/katas/97-images"} />
      <.kata_card title="98. PDF Generation" description="Document generation" path={~p"/katas/98-pdf"} />
      <.kata_card title="99. CSV Export" description="Data export" path={~p"/katas/99-csv"} />
      <.kata_card title="100. Error Boundary" description="Crash handling" path={~p"/katas/100-error"} />
      <.kata_card title="104. GenServer Integration" description="Background workers with LiveView" path={~p"/katas/104-genserver"} />
       <.kata_card title="125. State Machine" description="Complex workflows with :gen_statem" path={~p"/katas/125-statemachine"} />
      <.kata_card title="139. Virtual Scrolling" description="Efficiently rendering large datasets with window-based rendering" path={~p"/katas/139-virtual-scrolling"} />
      <.kata_card title="140. Confirm Dialog" description="Form with data confirmation modal and accept/reject flow" path={~p"/katas/140-confirm-dialog"} />

      </div>
    </div>
    """
  end
end
