defmodule ElixirKatasWeb.ElixirKata12MapMatchingLive do
  use ElixirKatasWeb, :live_component

  @preset_examples [
    %{
      pattern: "%{name: n}",
      map: "%{name: \"Alice\", age: 30, role: \"admin\"}",
      description: "Extract one key (partial match)"
    },
    %{
      pattern: "%{name: n, age: a}",
      map: "%{name: \"Alice\", age: 30, role: \"admin\"}",
      description: "Extract multiple keys"
    },
    %{
      pattern: "%{role: \"admin\"}",
      map: "%{name: \"Alice\", age: 30, role: \"admin\"}",
      description: "Literal value match"
    },
    %{
      pattern: "%{role: \"user\"}",
      map: "%{name: \"Alice\", age: 30, role: \"admin\"}",
      description: "Literal mismatch - fails!"
    },
    %{
      pattern: "%{missing_key: v}",
      map: "%{name: \"Alice\", age: 30}",
      description: "Key not present - fails!"
    },
    %{
      pattern: "%{}",
      map: "%{name: \"Alice\", age: 30}",
      description: "Empty pattern matches ANY map"
    },
    %{
      pattern: "%{user: %{name: name}}",
      map: "%{user: %{name: \"Bob\", email: \"bob@test.com\"}, active: true}",
      description: "Nested map extraction"
    },
    %{
      pattern: "%{data: %{items: [first | _]}}",
      map: "%{data: %{items: [\"a\", \"b\", \"c\"], count: 3}}",
      description: "Nested map + list matching"
    }
  ]

  @update_examples [
    %{
      map: "%{name: \"Alice\", age: 30}",
      update: "%{map | age: 31}",
      result: "%{name: \"Alice\", age: 31}",
      success: true,
      note: "Key exists, update succeeds"
    },
    %{
      map: "%{name: \"Alice\", age: 30}",
      update: "%{map | email: \"a@b.com\"}",
      result: nil,
      success: false,
      note: "Key does NOT exist - KeyError!"
    },
    %{
      map: "%{name: \"Alice\", age: 30}",
      update: "%{map | name: \"Bob\", age: 25}",
      result: "%{name: \"Bob\", age: 25}",
      success: true,
      note: "Multiple keys updated at once"
    }
  ]

  @function_head_examples [
    %{
      name: "greet/1",
      clauses: [
        %{
          pattern: "%{name: name, role: \"admin\"}",
          body: ~s["Hello Admin \#{name}!"],
          highlight: "Matches admin users"
        },
        %{
          pattern: "%{name: name}",
          body: ~s["Hello \#{name}!"],
          highlight: "Matches any user with a name"
        },
        %{pattern: "%{}", body: "\"Hello stranger!\"", highlight: "Matches any map (fallback)"}
      ],
      test_values: [
        %{label: "Admin user", value: "%{name: \"Alice\", role: \"admin\"}"},
        %{label: "Regular user", value: "%{name: \"Bob\", role: \"user\"}"},
        %{label: "No name", value: "%{role: \"guest\"}"},
        %{label: "Empty map", value: "%{}"}
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_tab, fn -> "matcher" end)
     |> assign_new(:pattern_input, fn -> "" end)
     |> assign_new(:map_input, fn -> "" end)
     |> assign_new(:match_result, fn -> nil end)
     |> assign_new(:selected_update, fn -> nil end)
     |> assign_new(:func_test_result, fn -> nil end)
     |> assign_new(:presets, fn -> @preset_examples end)
     |> assign_new(:update_examples, fn -> @update_examples end)
     |> assign_new(:function_examples, fn -> @function_head_examples end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Map Matching</h2>
      <p class="text-sm opacity-70 mb-6">
        Map pattern matching is <strong>partial</strong>
        - your pattern only needs to match a <em>subset</em>
        of the map's keys. This is fundamentally different from tuples and lists,
        which require structural matches.
      </p>
      
    <!-- Tab Switcher -->
      <div class="tabs tabs-boxed mb-6 bg-base-200">
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="matcher"
          class={"tab " <> if(@active_tab == "matcher", do: "tab-active", else: "")}
        >
          Pattern Matcher
        </button>
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="partial"
          class={"tab " <> if(@active_tab == "partial", do: "tab-active", else: "")}
        >
          Partial vs Exact
        </button>
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="update"
          class={"tab " <> if(@active_tab == "update", do: "tab-active", else: "")}
        >
          Update Syntax
        </button>
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="functions"
          class={"tab " <> if(@active_tab == "functions", do: "tab-active", else: "")}
        >
          Function Heads
        </button>
      </div>
      
    <!-- Pattern Matcher Tab -->
      <%= if @active_tab == "matcher" do %>
        <div class="space-y-6">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Map Pattern Matcher</h3>
              <form phx-submit="try_map_match" phx-target={@myself}>
                <div class="flex flex-col gap-3">
                  <div class="flex flex-col md:flex-row gap-3 items-end">
                    <div class="form-control flex-1">
                      <label class="label py-0">
                        <span class="label-text text-xs">Pattern (left side)</span>
                      </label>
                      <input
                        type="text"
                        name="pattern"
                        value={@pattern_input}
                        placeholder="e.g. %{name: n}"
                        class="input input-bordered input-sm font-mono"
                        autocomplete="off"
                      />
                    </div>
                    <span class="text-2xl font-bold text-warning self-center">=</span>
                    <div class="form-control flex-1">
                      <label class="label py-0">
                        <span class="label-text text-xs">Map (right side)</span>
                      </label>
                      <input
                        type="text"
                        name="map"
                        value={@map_input}
                        placeholder={"e.g. %{name: \"Alice\", age: 30}"}
                        class="input input-bordered input-sm font-mono"
                        autocomplete="off"
                      />
                    </div>
                    <button type="submit" class="btn btn-primary btn-sm">Match!</button>
                  </div>
                </div>
              </form>
              
    <!-- Result -->
              <%= if @match_result do %>
                <div class={"mt-4 rounded-lg border-2 overflow-hidden " <>
                  if(@match_result.success, do: "border-success", else: "border-error")}>
                  <div class={"px-4 py-2 flex items-center gap-2 " <>
                    if(@match_result.success, do: "bg-success/20", else: "bg-error/20")}>
                    <%= if @match_result.success do %>
                      <span class="badge badge-success badge-sm">Match</span>
                    <% else %>
                      <span class="badge badge-error badge-sm">No Match</span>
                    <% end %>
                    <span class="font-mono text-sm">
                      {@match_result.pattern} = {@match_result.map_str}
                    </span>
                  </div>

                  <div class="p-4">
                    <%= if @match_result.success do %>
                      <!-- Visual key matching -->
                      <div class="mb-4">
                        <div class="text-xs opacity-50 mb-2">Map keys:</div>
                        <div class="flex flex-wrap gap-2">
                          <%= for key_info <- @match_result.key_display do %>
                            <div class={"px-3 py-2 rounded-lg border-2 font-mono text-sm " <>
                              if(key_info.matched, do: "border-success bg-success/10 shadow-md", else: "border-base-300 bg-base-100 opacity-50")}>
                              <div class="flex items-center gap-2">
                                <span class="text-info font-bold">{key_info.key}:</span>
                                <span class="text-success">{key_info.value}</span>
                              </div>
                              <%= if key_info.matched and key_info.var do %>
                                <div class="text-xs text-success mt-1">
                                  {key_info.var} = {key_info.value}
                                </div>
                              <% end %>
                              <%= if not key_info.matched do %>
                                <div class="text-xs opacity-40 mt-1">not in pattern</div>
                              <% end %>
                            </div>
                          <% end %>
                        </div>
                      </div>
                      
    <!-- Bindings -->
                      <%= if length(@match_result.bindings) > 0 do %>
                        <div class="overflow-x-auto">
                          <table class="table table-sm table-zebra">
                            <thead>
                              <tr>
                                <th>Variable</th>
                                <th>Bound Value</th>
                                <th>From Key</th>
                              </tr>
                            </thead>
                            <tbody>
                              <%= for binding <- @match_result.bindings do %>
                                <tr>
                                  <td class="font-mono text-info font-bold">{binding.var}</td>
                                  <td class="font-mono text-success">{binding.value}</td>
                                  <td class="font-mono opacity-60">{binding.key}</td>
                                </tr>
                              <% end %>
                            </tbody>
                          </table>
                        </div>
                      <% end %>

                      <div class="text-sm mt-2">{@match_result.explanation}</div>
                    <% else %>
                      <div class="font-mono text-sm bg-error/10 p-3 rounded">
                        ** (MatchError) no match of right hand side value
                        <div class="text-xs mt-2 opacity-70">{@match_result.explanation}</div>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Preset Examples -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Try These Examples</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-2">
                <%= for {preset, idx} <- Enum.with_index(@presets) do %>
                  <button
                    phx-click="load_preset"
                    phx-target={@myself}
                    phx-value-index={idx}
                    class="btn btn-sm btn-ghost justify-start text-left h-auto py-2"
                  >
                    <div class="flex flex-col items-start">
                      <span class="font-mono text-xs">{preset.pattern} = {preset.map}</span>
                      <span class="text-xs opacity-60">{preset.description}</span>
                    </div>
                  </button>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>
      
    <!-- Partial vs Exact Tab -->
      <%= if @active_tab == "partial" do %>
        <div class="space-y-6">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-4">
                Maps Match Partially, Tuples/Lists Match Exactly
              </h3>

              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <!-- Map: Partial -->
                <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                  <h4 class="font-bold text-success text-sm mb-3">Map (Partial Match)</h4>
                  <div class="font-mono text-xs space-y-3">
                    <div class="bg-base-100 rounded p-2">
                      <div>%&lbrace;a: x&rbrace; = %&lbrace;a: 1, b: 2, c: 3&rbrace;</div>
                      <div class="text-success mt-1">x = 1</div>
                      <div class="text-xs opacity-50">Only :a needs to match!</div>
                    </div>
                    <div class="bg-base-100 rounded p-2">
                      <div>%&lbrace;&rbrace; = %&lbrace;a: 1, b: 2&rbrace;</div>
                      <div class="text-success mt-1">Always matches!</div>
                      <div class="text-xs opacity-50">Empty pattern = any map</div>
                    </div>
                  </div>
                </div>
                
    <!-- Tuple: Exact -->
                <div class="bg-error/10 border border-error/30 rounded-lg p-4">
                  <h4 class="font-bold text-error text-sm mb-3">Tuple (Exact Size)</h4>
                  <div class="font-mono text-xs space-y-3">
                    <div class="bg-base-100 rounded p-2">
                      <div>&lbrace;a&rbrace; = &lbrace;1, 2, 3&rbrace;</div>
                      <div class="text-error mt-1">** MatchError</div>
                      <div class="text-xs opacity-50">Size must match exactly</div>
                    </div>
                    <div class="bg-base-100 rounded p-2">
                      <div>&lbrace;a, b, c&rbrace; = &lbrace;1, 2, 3&rbrace;</div>
                      <div class="text-success mt-1">a=1, b=2, c=3</div>
                      <div class="text-xs opacity-50">All 3 positions must match</div>
                    </div>
                  </div>
                </div>
                
    <!-- List: Exact or head|tail -->
                <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
                  <h4 class="font-bold text-warning text-sm mb-3">List (Exact or [h|t])</h4>
                  <div class="font-mono text-xs space-y-3">
                    <div class="bg-base-100 rounded p-2">
                      <div>[a, b] = [1, 2, 3]</div>
                      <div class="text-error mt-1">** MatchError</div>
                      <div class="text-xs opacity-50">Fixed pattern = exact length</div>
                    </div>
                    <div class="bg-base-100 rounded p-2">
                      <div>[h | _] = [1, 2, 3]</div>
                      <div class="text-success mt-1">h = 1</div>
                      <div class="text-xs opacity-50">[h|t] allows partial via tail</div>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Key Insight -->
              <div class="mt-4 alert alert-info text-sm">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  class="stroke-current shrink-0 w-5 h-5"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  >
                  </path>
                </svg>
                <span>
                  <strong>Why partial?</strong>
                  Maps are key-value stores - you typically only care about specific keys.
                  Requiring all keys would make function heads brittle and hard to maintain.
                </span>
              </div>
            </div>
          </div>
          
    <!-- Implications -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Practical Implications</h3>
              <div class="space-y-3">
                <div class="bg-base-300 rounded-lg p-3">
                  <h4 class="font-bold text-sm mb-2 text-info">
                    API handlers can match specific fields
                  </h4>
                  <div class="font-mono text-xs space-y-1">
                    <div>
                      def handle(%&lbrace;"action" =&gt; "create", "data" =&gt; data&rbrace;) do
                    </div>
                    <div class="pl-4">create_record(data)</div>
                    <div>end</div>
                    <div class="mt-1 opacity-50"># Other keys in the map are ignored</div>
                  </div>
                </div>

                <div class="bg-base-300 rounded-lg p-3">
                  <h4 class="font-bold text-sm mb-2 text-info">Structs leverage map matching</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div>def full_name(%User&lbrace;first: f, last: l&rbrace;) do</div>
                    <div class="pl-4">"#&lbrace;f&rbrace; #&lbrace;l&rbrace;"</div>
                    <div>end</div>
                    <div class="mt-1 opacity-50">
                      # Other struct fields are not required in pattern
                    </div>
                  </div>
                </div>

                <div class="bg-base-300 rounded-lg p-3">
                  <h4 class="font-bold text-sm mb-2 text-info">Phoenix assigns pattern matching</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div>
                      def handle_event("save", params, %&lbrace;assigns: %&lbrace;user: user&rbrace;&rbrace; = socket) do
                    </div>
                    <div class="pl-4"># Pattern matched user from deeply nested assigns</div>
                    <div>end</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
      
    <!-- Update Syntax Tab -->
      <%= if @active_tab == "update" do %>
        <div class="space-y-6">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-1">Map Update Syntax</h3>
              <p class="text-xs opacity-60 mb-4">
                The <code class="font-mono">%&lbrace;map | key: new_value&rbrace;</code> syntax
                updates existing keys. Unlike <code class="font-mono">Map.put/3</code>,
                the key <strong>must already exist</strong> or you get a KeyError.
              </p>

              <div class="space-y-4">
                <%= for {example, idx} <- Enum.with_index(@update_examples) do %>
                  <div class={"rounded-lg border-2 overflow-hidden cursor-pointer transition-all hover:shadow-lg " <>
                    if(@selected_update == idx,
                      do: if(example.success, do: "border-success", else: "border-error"),
                      else: "border-base-300")}>
                    <button
                      phx-click="show_update"
                      phx-target={@myself}
                      phx-value-index={idx}
                      class="w-full text-left"
                    >
                      <div class={"px-4 py-3 " <> if(example.success, do: "bg-base-300", else: "bg-error/10")}>
                        <div class="font-mono text-sm mb-1">
                          <span class="opacity-50">map = </span>{example.map}
                        </div>
                        <div class="font-mono text-sm font-bold">{example.update}</div>
                      </div>
                    </button>

                    <%= if @selected_update == idx do %>
                      <div class={"p-4 " <> if(example.success, do: "bg-success/10", else: "bg-error/10")}>
                        <%= if example.success do %>
                          <div class="flex items-center gap-2 mb-2">
                            <span class="badge badge-success badge-sm">Success</span>
                            <span class="text-sm">{example.note}</span>
                          </div>
                          <div class="font-mono text-sm">
                            <span class="opacity-50">Result: </span>
                            <span class="text-success font-bold">{example.result}</span>
                          </div>
                        <% else %>
                          <div class="flex items-center gap-2 mb-2">
                            <span class="badge badge-error badge-sm">KeyError</span>
                            <span class="text-sm">{example.note}</span>
                          </div>
                          <div class="font-mono text-sm text-error">
                            ** (KeyError) key :email not found
                          </div>
                          <div class="mt-2 text-xs opacity-70">
                            Use <code class="font-mono">Map.put(map, :email, "a@b.com")</code>
                            to add new keys instead.
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
              
    <!-- Comparison Table -->
              <div class="mt-6 overflow-x-auto">
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Operation</th>
                      <th>Syntax</th>
                      <th>Key must exist?</th>
                      <th>Can add new keys?</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td class="font-bold">Update syntax</td>
                      <td class="font-mono text-sm">%&lbrace;map | key: val&rbrace;</td>
                      <td><span class="badge badge-warning badge-xs">Yes</span></td>
                      <td><span class="badge badge-error badge-xs">No</span></td>
                    </tr>
                    <tr>
                      <td class="font-bold">Map.put/3</td>
                      <td class="font-mono text-sm">Map.put(map, :key, val)</td>
                      <td><span class="badge badge-success badge-xs">No</span></td>
                      <td><span class="badge badge-success badge-xs">Yes</span></td>
                    </tr>
                    <tr>
                      <td class="font-bold">Map.replace!/3</td>
                      <td class="font-mono text-sm">Map.replace!(map, :key, val)</td>
                      <td><span class="badge badge-warning badge-xs">Yes</span></td>
                      <td><span class="badge badge-error badge-xs">No</span></td>
                    </tr>
                    <tr>
                      <td class="font-bold">Map.merge/2</td>
                      <td class="font-mono text-sm">Map.merge(map, new_map)</td>
                      <td><span class="badge badge-success badge-xs">No</span></td>
                      <td><span class="badge badge-success badge-xs">Yes</span></td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div class="alert alert-warning text-sm">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="stroke-current shrink-0 h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
            <span>
              <strong>Why does update syntax require existing keys?</strong>
              It acts as a safety check. If you misspell a key, you get an immediate error
              instead of silently adding a wrong key. This is especially important with structs.
            </span>
          </div>
        </div>
      <% end %>
      
    <!-- Function Heads Tab -->
      <%= if @active_tab == "functions" do %>
        <div class="space-y-6">
          <%= for func <- @function_examples do %>
            <div class="card bg-base-200 shadow-md">
              <div class="card-body p-4">
                <h3 class="card-title text-sm mb-3">
                  Pattern Matching in Function Heads: <code class="font-mono">{func.name}</code>
                </h3>
                
    <!-- Function Definition -->
                <div class="bg-base-300 rounded-lg p-4 font-mono text-xs mb-4 space-y-2">
                  <%= for {clause, idx} <- Enum.with_index(func.clauses) do %>
                    <div class={"p-2 rounded " <>
                      if(@func_test_result && @func_test_result.matched_idx == idx,
                        do: "bg-success/20 border border-success/30",
                        else: "")}>
                      <div class="opacity-50 text-xs mb-1"># {clause.highlight}</div>
                      <div>
                        def greet(<span class="text-info"><%= clause.pattern %></span>) do
                      </div>
                      <div class="pl-4">{clause.body}</div>
                      <div>end</div>
                    </div>
                  <% end %>
                </div>
                
    <!-- Test Values -->
                <div class="mb-3">
                  <div class="text-xs opacity-50 mb-2">Test with these values:</div>
                  <div class="flex flex-wrap gap-2">
                    <%= for {test_val, idx} <- Enum.with_index(func.test_values) do %>
                      <button
                        phx-click="test_func_head"
                        phx-target={@myself}
                        phx-value-func={func.name}
                        phx-value-index={idx}
                        class={"btn btn-sm " <>
                          if(@func_test_result && @func_test_result.test_idx == idx,
                            do: "btn-primary", else: "btn-outline")}
                      >
                        {test_val.label}
                      </button>
                    <% end %>
                  </div>
                </div>
                
    <!-- Test Result -->
                <%= if @func_test_result do %>
                  <div class="p-4 bg-success/10 border border-success/30 rounded-lg">
                    <div class="font-mono text-sm mb-2">
                      <span class="opacity-50">greet(</span>{@func_test_result.input}<span class="opacity-50">)</span>
                    </div>
                    <div class="flex items-center gap-2 mb-2">
                      <span class="badge badge-success badge-sm">
                        Matched clause {@func_test_result.matched_idx + 1}
                      </span>
                      <span class="text-xs opacity-60">{@func_test_result.clause_desc}</span>
                    </div>
                    <div class="font-mono text-sm">
                      <span class="opacity-50">Result: </span>
                      <span class="text-success font-bold">{@func_test_result.result}</span>
                    </div>
                    <%= if @func_test_result.skipped_clauses > 0 do %>
                      <div class="text-xs opacity-50 mt-2">
                        Skipped {@func_test_result.skipped_clauses} clause(s) that didn't match.
                        Elixir tries clauses top-to-bottom, using the first match.
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
          
    <!-- More Examples -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">More Function Head Patterns</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-base-300 rounded-lg p-3">
                  <h4 class="font-bold text-sm mb-2 text-info">Guard clauses with maps</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div>def process(%&lbrace;age: age&rbrace;) when age &gt;= 18 do</div>
                    <div class="pl-4">"Adult"</div>
                    <div>end</div>
                    <div class="mt-2">def process(%&lbrace;age: _age&rbrace;) do</div>
                    <div class="pl-4">"Minor"</div>
                    <div>end</div>
                  </div>
                </div>

                <div class="bg-base-300 rounded-lg p-3">
                  <h4 class="font-bold text-sm mb-2 text-info">Struct matching</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div>def handle(%User&lbrace;active: true&rbrace; = user) do</div>
                    <div class="pl-4">serve(user)</div>
                    <div>end</div>
                    <div class="mt-2">def handle(%User&lbrace;active: false&rbrace;) do</div>
                    <div class="pl-4">&lbrace;:error, :inactive&rbrace;</div>
                    <div>end</div>
                  </div>
                </div>

                <div class="bg-base-300 rounded-lg p-3">
                  <h4 class="font-bold text-sm mb-2 text-info">Capturing the whole map</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div>def update(%&lbrace;id: id&rbrace; = params) do</div>
                    <div class="pl-4"># id is extracted AND params has full map</div>
                    <div class="pl-4">Repo.get!(User, id)</div>
                    <div class="pl-4">|&gt; User.changeset(params)</div>
                    <div>end</div>
                  </div>
                </div>

                <div class="bg-base-300 rounded-lg p-3">
                  <h4 class="font-bold text-sm mb-2 text-info">Nested extraction</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div>def handle_in("msg", %&lbrace;"body" =&gt; body&rbrace;, socket) do</div>
                    <div class="pl-4">broadcast(socket, "msg", %&lbrace;body: body&rbrace;)</div>
                    <div class="pl-4">&lbrace;:noreply, socket&rbrace;</div>
                    <div>end</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Event Handlers

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("try_map_match", %{"pattern" => pattern, "map" => map_str}, socket) do
    pattern = String.trim(pattern)
    map_str = String.trim(map_str)

    if pattern != "" and map_str != "" do
      result = do_map_match(pattern, map_str)

      {:noreply,
       socket
       |> assign(match_result: result)
       |> assign(pattern_input: pattern)
       |> assign(map_input: map_str)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("load_preset", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    preset = Enum.at(@preset_examples, idx)

    if preset do
      result = do_map_match(preset.pattern, preset.map)

      {:noreply,
       socket
       |> assign(match_result: result)
       |> assign(pattern_input: preset.pattern)
       |> assign(map_input: preset.map)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("show_update", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)

    new_val = if socket.assigns.selected_update == idx, do: nil, else: idx

    {:noreply, assign(socket, selected_update: new_val)}
  end

  def handle_event("test_func_head", %{"func" => func_name, "index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    func = Enum.find(@function_head_examples, fn f -> f.name == func_name end)

    if func do
      test_val = Enum.at(func.test_values, idx)
      {matched_idx, clause, result} = match_function_head(func.clauses, test_val.value)

      {:noreply,
       assign(socket,
         func_test_result: %{
           test_idx: idx,
           input: test_val.value,
           matched_idx: matched_idx,
           clause_desc: clause.highlight,
           result: result,
           skipped_clauses: matched_idx
         }
       )}
    else
      {:noreply, socket}
    end
  end

  # Map match engine

  defp do_map_match(pattern, map_str) do
    pattern_pairs = parse_map_pattern(pattern)
    map_pairs = parse_map_value(map_str)

    # Build key display
    key_display =
      Enum.map(map_pairs, fn {key, value} ->
        matching_pat = Enum.find(pattern_pairs, fn {pk, _pv} -> pk == key end)

        case matching_pat do
          {_pk, pv} ->
            var = if Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pv) and pv != "_", do: pv, else: nil
            %{key: key, value: value, matched: true, var: var}

          nil ->
            %{key: key, value: value, matched: false, var: nil}
        end
      end)

    # Check all pattern keys exist in map
    {all_present, missing_keys} =
      Enum.reduce(pattern_pairs, {true, []}, fn {pk, _pv}, {acc, missing} ->
        if Enum.any?(map_pairs, fn {mk, _mv} -> mk == pk end) do
          {acc, missing}
        else
          {false, missing ++ [pk]}
        end
      end)

    if not all_present do
      %{
        success: false,
        pattern: pattern,
        map_str: map_str,
        key_display: key_display,
        bindings: [],
        explanation:
          "Key(s) not found in map: #{Enum.join(missing_keys, ", ")}. Pattern requires these keys to exist."
      }
    else
      # Check literal matches
      {literals_match, literal_mismatches} =
        Enum.reduce(pattern_pairs, {true, []}, fn {pk, pv}, {acc, mismatches} ->
          map_val = Enum.find_value(map_pairs, fn {mk, mv} -> if mk == pk, do: mv end)

          cond do
            pv == "_" -> {acc, mismatches}
            Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pv) -> {acc, mismatches}
            String.starts_with?(pv, "%{") -> {acc, mismatches}
            String.starts_with?(pv, "[") -> {acc, mismatches}
            pv == map_val -> {acc, mismatches}
            # Quoted string comparison
            "\"#{pv}\"" == map_val or pv == "\"#{map_val}\"" -> {acc, mismatches}
            strip_quotes(pv) == strip_quotes(map_val) -> {acc, mismatches}
            true -> {false, mismatches ++ ["#{pk}: expected #{pv}, got #{map_val}"]}
          end
        end)

      if not literals_match do
        %{
          success: false,
          pattern: pattern,
          map_str: map_str,
          key_display: key_display,
          bindings: [],
          explanation: "Value mismatch: #{Enum.join(literal_mismatches, "; ")}"
        }
      else
        # Collect bindings
        bindings =
          Enum.flat_map(pattern_pairs, fn {pk, pv} ->
            map_val = Enum.find_value(map_pairs, fn {mk, mv} -> if mk == pk, do: mv end)

            cond do
              pv == "_" ->
                []

              Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pv) ->
                [%{var: pv, value: map_val, key: pk}]

              String.starts_with?(pv, "%{") ->
                # Nested map - simplified binding
                [%{var: "(nested)", value: map_val, key: pk}]

              true ->
                []
            end
          end)

        explanation =
          if length(pattern_pairs) == 0 do
            "Empty pattern %{} matches any map. No bindings created."
          else
            matched = length(pattern_pairs)
            total = length(map_pairs)
            "Partial match: pattern matched #{matched} of #{total} keys."
          end

        %{
          success: true,
          pattern: pattern,
          map_str: map_str,
          key_display: key_display,
          bindings: bindings,
          explanation: explanation
        }
      end
    end
  end

  defp parse_map_pattern(pattern) do
    inner =
      pattern
      |> String.trim()
      |> String.trim_leading("%{")
      |> String.trim_trailing("}")
      |> String.trim()

    if inner == "" do
      []
    else
      split_map_entries(inner)
      |> Enum.map(fn entry ->
        cond do
          String.contains?(entry, ": ") ->
            [key, val] = String.split(entry, ": ", parts: 2)
            {String.trim(key), String.trim(val)}

          String.contains?(entry, " => ") ->
            [key, val] = String.split(entry, " => ", parts: 2)
            {String.trim(key), String.trim(val)}

          true ->
            {entry, "_"}
        end
      end)
    end
  end

  defp parse_map_value(map_str) do
    inner =
      map_str
      |> String.trim()
      |> String.trim_leading("%{")
      |> String.trim_trailing("}")
      |> String.trim()

    if inner == "" do
      []
    else
      split_map_entries(inner)
      |> Enum.map(fn entry ->
        cond do
          String.contains?(entry, ": ") ->
            [key, val] = String.split(entry, ": ", parts: 2)
            {String.trim(key), String.trim(val)}

          String.contains?(entry, " => ") ->
            [key, val] = String.split(entry, " => ", parts: 2)
            {String.trim(key), String.trim(val)}

          true ->
            {entry, "nil"}
        end
      end)
    end
  end

  defp split_map_entries(str) do
    do_split_map(str, 0, 0, 0, 0, [], "")
  end

  defp do_split_map("", _p, _b, _m, _q, acc, current) do
    current = String.trim(current)
    if current == "", do: acc, else: acc ++ [current]
  end

  defp do_split_map("," <> rest, 0, 0, 0, 0, acc, current) do
    do_split_map(rest, 0, 0, 0, 0, acc ++ [String.trim(current)], "")
  end

  defp do_split_map("{" <> rest, p, b, m, q, acc, current),
    do: do_split_map(rest, p + 1, b, m, q, acc, current <> "{")

  defp do_split_map("}" <> rest, p, b, m, q, acc, current),
    do: do_split_map(rest, max(p - 1, 0), b, m, q, acc, current <> "}")

  defp do_split_map("[" <> rest, p, b, m, q, acc, current),
    do: do_split_map(rest, p, b + 1, m, q, acc, current <> "[")

  defp do_split_map("]" <> rest, p, b, m, q, acc, current),
    do: do_split_map(rest, p, max(b - 1, 0), m, q, acc, current <> "]")

  defp do_split_map("%" <> rest, p, b, m, q, acc, current),
    do: do_split_map(rest, p, b, m, q, acc, current <> "%")

  defp do_split_map("\"" <> rest, p, b, m, 0, acc, current),
    do: do_split_map(rest, p, b, m, 1, acc, current <> "\"")

  defp do_split_map("\"" <> rest, p, b, m, 1, acc, current),
    do: do_split_map(rest, p, b, m, 0, acc, current <> "\"")

  defp do_split_map(<<c::utf8, rest::binary>>, p, b, m, q, acc, current) do
    do_split_map(rest, p, b, m, q, acc, current <> <<c::utf8>>)
  end

  defp strip_quotes(str) do
    str |> String.trim("\"") |> String.trim("'")
  end

  defp match_function_head(clauses, value_str) do
    map_pairs =
      parse_map_value(value_str |> String.trim_leading("%{") |> then(fn s -> "%{" <> s end))

    result =
      clauses
      |> Enum.with_index()
      |> Enum.find(fn {clause, _idx} ->
        pattern_pairs = parse_map_pattern(clause.pattern)

        # Empty pattern matches anything
        if pattern_pairs == [] do
          true
        else
          Enum.all?(pattern_pairs, fn {pk, pv} ->
            map_val = Enum.find_value(map_pairs, fn {mk, mv} -> if mk == pk, do: mv end)

            cond do
              map_val == nil -> false
              pv == "_" -> true
              Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pv) -> true
              strip_quotes(pv) == strip_quotes(map_val) -> true
              pv == map_val -> true
              true -> false
            end
          end)
        end
      end)

    case result do
      {clause, idx} ->
        # Build result string
        bindings =
          parse_map_pattern(clause.pattern)
          |> Enum.flat_map(fn {pk, pv} ->
            map_val = Enum.find_value(map_pairs, fn {mk, mv} -> if mk == pk, do: mv end)

            if Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pv) and pv != "_" do
              [{pv, strip_quotes(map_val || "")}]
            else
              []
            end
          end)

        result_str =
          Enum.reduce(bindings, clause.body, fn {var, val}, body ->
            String.replace(body, "#\{#{var}\}", val)
            |> String.replace(var, val)
          end)

        {idx, clause, result_str}

      nil ->
        {0, List.first(clauses), "(no clause matched)"}
    end
  end
end
