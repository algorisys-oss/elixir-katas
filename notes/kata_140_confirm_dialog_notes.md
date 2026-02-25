# Kata 140: Form Confirmation Dialog


## Goal
Build a form with a **confirmation dialog** that displays the submitted data for user review before final processing. The user can either **Accept** (confirm submission) or **Reject** (go back to edit).


## The Pattern
This is a common UX pattern for:
- Payment forms (review before charging)
- Registration forms (verify details before account creation)
- Contact forms (confirm message before sending)
- Any destructive or irreversible action


## Core Concepts

### 1. Pending State
Instead of processing form data immediately on submit, we store it in a `pending_data` assign and show a confirmation modal.

```elixir
|> assign(:pending_data, params)
|> assign(:show_confirm_modal, true)
```

### 2. Two-Phase Submit
- **Phase 1**: `request_confirm` - Validates data, stores in pending, shows modal
- **Phase 2a**: `accept` - User confirms, process the data
- **Phase 2b**: `reject` - User cancels, close modal, keep form data for editing

### 3. Form Data Preservation
On reject, the form data remains intact so users can make corrections without re-entering everything.


## Implementation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      FORM STATE                             │
│  form_data: %{name: "", email: "", message: ""}             │
└─────────────────────┬───────────────────────────────────────┘
                      │ Submit (phx-submit="request_confirm")
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    VALIDATION                               │
│  errors = validate_form(params)                             │
└──────────┬─────────────────────────────────┬────────────────┘
           │ Valid                           │ Invalid
           ▼                                 ▼
┌─────────────────────────┐     ┌─────────────────────────────┐
│   CONFIRMATION MODAL    │     │      SHOW ERRORS            │
│  pending_data = params  │     │  errors = %{field: "msg"}   │
│  show_confirm_modal=true│     │  form_data = params         │
└────────┬───────┬────────┘     └─────────────────────────────┘
         │       │
   Accept│       │Reject
         ▼       ▼
┌──────────────┐ ┌─────────────────────────────────────────────┐
│   PROCESS    │ │              CLOSE MODAL                    │
│ submitted_   │ │  show_confirm_modal = false                 │
│ data=pending │ │  form_data unchanged (user can edit)        │
│ clear form   │ └─────────────────────────────────────────────┘
└──────────────┘
```


## Deep Dive

### 1. Event Naming Convention
Use clear, intention-revealing names:
- `request_confirm` - Not `submit`, because it doesn't submit yet
- `accept` / `reject` - Binary choice, clear semantics
- Avoid `confirm` alone (ambiguous with `request_confirm`)

### 2. Modal Dismiss Patterns
Three ways to close the modal:
```elixir
# 1. Backdrop click
<div phx-click="reject" phx-target={@myself}>

# 2. Escape key
phx-window-keydown="handle_keydown" phx-key="Escape"

# 3. Explicit "Go Back" button
<button phx-click="reject">Go Back</button>
```

### 3. Preventing Accidental Closes
Stop click propagation inside modal content:
```elixir
<div class="modal-content" phx-click="prevent_close" phx-target={@myself}>

def handle_event("prevent_close", _params, socket) do
  {:noreply, socket}  # Do nothing, prevents backdrop click
end
```

### 4. State Management
Keep these assigns separate:
| Assign | Purpose |
|--------|---------|
| `form_data` | Current form field values (for controlled inputs) |
| `pending_data` | Data waiting for confirmation |
| `submitted_data` | Successfully processed data (for success message) |
| `show_confirm_modal` | Modal visibility toggle |
| `errors` | Validation error messages |

### 5. Validation Timing
Validate **before** showing the modal, not after. Users shouldn't see a confirmation dialog with invalid data.

```elixir
def handle_event("request_confirm", params, socket) do
  errors = validate_form(params)

  if Enum.empty?(errors) do
    # Show modal only if valid
    {:noreply, assign(socket, pending_data: params, show_confirm_modal: true)}
  else
    # Stay on form, show errors
    {:noreply, assign(socket, errors: errors, form_data: params)}
  end
end
```


## Common Pitfalls

1. **Losing Form Data on Reject**: Always preserve `form_data` when closing the modal
2. **Forgetting Escape Key**: Users expect Escape to close modals
3. **No Loading State**: For async operations in `accept`, add a `submitting` flag
4. **Missing Focus Trap**: Accessibility requires focus to stay inside modal (advanced)


## Tips

- For complex forms, consider using `Phoenix.HTML.Form` with changesets
- Add `phx-debounce` on inputs if using `phx-change` for live validation
- Use `Phoenix.LiveView.JS` for smoother modal animations
- Consider adding a "Don't show again" checkbox for repeat users


## Challenges

<h3>Challenge 1: Add Loading State</h3>

<p>Show a spinner on the "Confirm & Submit" button while processing, disabling both buttons.</p>

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># In assigns:
|> assign(:submitting, false)

# In accept handler:
def handle_event("accept", _params, socket) do
  send(self(), :process_submission)
  {:noreply, assign(socket, submitting: true)}
end

def handle_info(:process_submission, socket) do
  Process.sleep(1000)
  {:noreply,
   socket
   |> assign(:submitting, false)
   |> assign(:submitted_data, socket.assigns.pending_data)
   |> assign(:show_confirm_modal, false)}
end
</code></pre>
</details>


<h3>Challenge 2: Edit from Modal</h3>

<p>Add an "Edit" button in the modal that closes it AND focuses the specific field the user wants to change.</p>

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># Handler:
def handle_event("edit_field", %{"field" => field}, socket) do
  {:noreply,
   socket
   |> assign(:show_confirm_modal, false)
   |> push_event("focus-field", %{field: field})}
end

# JS Hook (in app.js):
Hooks.FocusField = {
  mounted() {
    this.handleEvent("focus-field", ({field}) => {
      if (this.el.name === field) {
        this.el.focus()
        this.el.select()
      }
    })
  }
}
</code></pre>
</details>


<h3>Challenge 3: Countdown Timer</h3>

<p>Auto-submit after 10 seconds with a visible countdown. User can cancel anytime.</p>

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># In assigns:
|> assign(:countdown, nil)

# When showing modal, start countdown:
Process.send_after(self(), :tick, 1000)
|> assign(:countdown, 10)

# Handle ticks:
def handle_info(:tick, socket) do
  case socket.assigns.countdown do
    1 -> send(self(), {:accept_auto})
    n when n > 1 ->
      Process.send_after(self(), :tick, 1000)
      {:noreply, assign(socket, countdown: n - 1)}
    _ -> {:noreply, socket}
  end
end
</code></pre>
</details>


<h2>Related Katas</h2>

<ul>
<li><strong>Kata 54</strong>: Modal Dialog - Basic modal mechanics</li>
<li><strong>Kata 37</strong>: Wizard - Multi-step form with review step</li>
<li><strong>Kata 68</strong>: Changesets - Form validation patterns</li>
<li><strong>Kata 70</strong>: Optimistic UI - Alternative approach (submit first, undo later)</li>
</ul>
