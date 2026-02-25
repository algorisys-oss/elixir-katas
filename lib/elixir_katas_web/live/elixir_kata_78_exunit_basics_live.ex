defmodule ElixirKatasWeb.ElixirKata78ExunitBasicsLive do
  use ElixirKatasWeb, :live_component

  @assertion_tabs [
    %{
      id: "assert",
      title: "assert / refute",
      description: "The most fundamental assertions. assert checks truthiness, refute checks falsiness.",
      examples: [
        %{
          label: "assert true",
          code: "assert 1 + 1 == 2",
          result: "true",
          note: "Passes when the expression is truthy (anything except nil and false)"
        },
        %{
          label: "assert match",
          code: "assert {:ok, _value} = {:ok, 42}",
          result: "{:ok, 42}",
          note: "Pattern match assertion -- fails if the pattern doesn't match"
        },
        %{
          label: "assert in",
          code: "assert :apple in [:apple, :banana, :cherry]",
          result: "true",
          note: "Check membership in a list"
        },
        %{
          label: "refute",
          code: "refute 1 + 1 == 3",
          result: "true",
          note: "refute is the opposite of assert -- passes when expression is falsy"
        },
        %{
          label: "refute nil",
          code: "refute nil",
          result: "true",
          note: "nil is falsy, so refute nil passes"
        }
      ]
    },
    %{
      id: "assert_raise",
      title: "assert_raise",
      description: "Verify that a function raises a specific exception.",
      examples: [
        %{
          label: "RuntimeError",
          code: "assert_raise RuntimeError, fn -> raise \"boom\" end",
          result: "%RuntimeError{message: \"boom\"}",
          note: "Passes if the function raises RuntimeError"
        },
        %{
          label: "with message",
          code: "assert_raise RuntimeError, \"boom\", fn -> raise \"boom\" end",
          result: "%RuntimeError{message: \"boom\"}",
          note: "Also checks the exception message matches exactly"
        },
        %{
          label: "ArithmeticError",
          code: "assert_raise ArithmeticError, fn -> 1 / 0 end",
          result: "%ArithmeticError{}",
          note: "Works with any exception type"
        },
        %{
          label: "ArgumentError",
          code: "assert_raise ArgumentError, fn -> String.to_integer(\"abc\") end",
          result: "%ArgumentError{}",
          note: "Useful for testing input validation"
        }
      ]
    },
    %{
      id: "assert_receive",
      title: "assert_receive",
      description: "Wait for a message to arrive in the test process mailbox.",
      examples: [
        %{
          label: "basic",
          code: "send(self(), :hello)\nassert_receive :hello",
          result: ":hello",
          note: "Waits up to 100ms (default) for the message"
        },
        %{
          label: "with pattern",
          code: "send(self(), {:ok, 42})\nassert_receive {:ok, value}\n# value is now bound to 42",
          result: "{:ok, 42}",
          note: "You can pattern match to extract values from the message"
        },
        %{
          label: "with timeout",
          code: "send(self(), :done)\nassert_receive :done, 5000",
          result: ":done",
          note: "Second argument is timeout in ms -- useful for async operations"
        },
        %{
          label: "refute_receive",
          code: "refute_receive :nope, 100",
          result: "true",
          note: "Asserts that NO matching message arrives within the timeout"
        }
      ]
    },
    %{
      id: "delta_approx",
      title: "Numeric / Approx",
      description: "Assertions for floating-point and approximate comparisons.",
      examples: [
        %{
          label: "assert_in_delta",
          code: "assert_in_delta 3.14159, 3.14, 0.01",
          result: "true",
          note: "Passes if the two values differ by at most delta (0.01 here)"
        },
        %{
          label: "refute_in_delta",
          code: "refute_in_delta 3.14, 4.0, 0.5",
          result: "true",
          note: "Passes if values differ by MORE than delta"
        },
        %{
          label: "float comparison",
          code: "# Never do: assert 0.1 + 0.2 == 0.3\nassert_in_delta 0.1 + 0.2, 0.3, 1.0e-10",
          result: "true",
          note: "Floating point arithmetic can be imprecise -- always use delta for floats"
        }
      ]
    }
  ]

  @test_structure_sections [
    %{
      id: "basic_test",
      title: "Basic Test File",
      description: "The minimal structure of an ExUnit test file."
    },
    %{
      id: "describe_blocks",
      title: "describe Blocks",
      description: "Group related tests together with describe."
    },
    %{
      id: "setup_callbacks",
      title: "setup / setup_all",
      description: "Run code before each test or once before all tests."
    },
    %{
      id: "async_tags",
      title: "Async & Tags",
      description: "Run tests concurrently and filter with tags."
    },
    %{
      id: "doctest",
      title: "doctest",
      description: "Automatically test code examples in your documentation."
    }
  ]

  @test_patterns [
    %{
      id: "ok_error",
      title: "Testing {:ok, _} / {:error, _}",
      description: "The most common Elixir pattern -- functions returning tagged tuples."
    },
    %{
      id: "lists",
      title: "Testing Lists",
      description: "Assertions for list contents, order, and membership."
    },
    %{
      id: "exceptions",
      title: "Testing Exceptions",
      description: "Verify functions raise the right exceptions."
    },
    %{
      id: "maps_structs",
      title: "Testing Maps & Structs",
      description: "Assert on map contents using pattern matching."
    }
  ]

  @challenge_functions [
    %{
      id: "add",
      name: "Math.add/2",
      description: "Adds two numbers together",
      implementation: "def add(a, b), do: a + b",
      hint: "Test normal cases, zero, and negative numbers",
      sample_tests: [
        "assert Math.add(1, 2) == 3",
        "assert Math.add(0, 0) == 0",
        "assert Math.add(-1, 1) == 0"
      ]
    },
    %{
      id: "safe_div",
      name: "Math.safe_div/2",
      description: "Divides two numbers, returning {:ok, result} or {:error, :div_by_zero}",
      implementation: "def safe_div(_a, 0), do: {:error, :div_by_zero}\ndef safe_div(a, b), do: {:ok, a / b}",
      hint: "Test the happy path AND the error path",
      sample_tests: [
        "assert {:ok, 5.0} = Math.safe_div(10, 2)",
        "assert {:error, :div_by_zero} = Math.safe_div(10, 0)"
      ]
    },
    %{
      id: "upcase_first",
      name: "StringHelper.upcase_first/1",
      description: "Uppercases the first letter of a string",
      implementation: "def upcase_first(<<first::utf8, rest::binary>>), do: String.upcase(<<first::utf8>>) <> rest\ndef upcase_first(\"\"), do: \"\"",
      hint: "Test normal strings, empty string, and already-uppercase",
      sample_tests: [
        "assert StringHelper.upcase_first(\"hello\") == \"Hello\"",
        "assert StringHelper.upcase_first(\"\") == \"\"",
        "assert StringHelper.upcase_first(\"Hello\") == \"Hello\""
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_assertion_tab, fn -> "assert" end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:active_structure_section, fn -> "basic_test" end)
     |> assign_new(:active_pattern, fn -> "ok_error" end)
     |> assign_new(:active_challenge, fn -> "add" end)
     |> assign_new(:challenge_input, fn -> "" end)
     |> assign_new(:challenge_result, fn -> nil end)
     |> assign_new(:show_sample_tests, fn -> false end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">ExUnit Testing Basics</h2>
      <p class="text-sm opacity-70 mb-6">
        <strong>ExUnit</strong> is Elixir's built-in test framework. It provides assertions, test organization,
        setup callbacks, async execution, and doctest support out of the box.
      </p>

      <!-- ===== Section 1: Assertion Explorer ===== -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Assertion Explorer</h3>

          <!-- Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for tab <- assertion_tabs() do %>
              <button
                phx-click="select_assertion_tab"
                phx-target={@myself}
                phx-value-id={tab.id}
                class={"btn btn-sm " <> if(@active_assertion_tab == tab.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= tab.title %>
              </button>
            <% end %>
          </div>

          <% tab = Enum.find(assertion_tabs(), &(&1.id == @active_assertion_tab)) %>
          <p class="text-xs opacity-60 mb-4"><%= tab.description %></p>

          <!-- Example Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(tab.examples) do %>
              <button
                phx-click="select_example"
                phx-target={@myself}
                phx-value-idx={idx}
                class={"btn btn-xs " <> if(idx == @active_example_idx, do: "btn-accent", else: "btn-ghost")}
              >
                <%= example.label %>
              </button>
            <% end %>
          </div>

          <% example = Enum.at(tab.examples, min(@active_example_idx, length(tab.examples) - 1)) %>
          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= example.code %></div>
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result</div>
              <div class="font-mono text-sm text-success font-bold"><%= example.result %></div>
            </div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Note</div>
              <div class="text-sm"><%= example.note %></div>
            </div>
          </div>
        </div>
      </div>

      <!-- ===== Section 2: Test Structure ===== -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Test Structure</h3>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for section <- test_structure_sections() do %>
              <button
                phx-click="select_structure_section"
                phx-target={@myself}
                phx-value-id={section.id}
                class={"btn btn-sm " <> if(@active_structure_section == section.id, do: "btn-secondary", else: "btn-outline")}
              >
                <%= section.title %>
              </button>
            <% end %>
          </div>

          <% structure = Enum.find(test_structure_sections(), &(&1.id == @active_structure_section)) %>
          <p class="text-xs opacity-60 mb-3"><%= structure.description %></p>

          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= structure_code(@active_structure_section) %></div>
        </div>
      </div>

      <!-- ===== Section 3: Test Patterns ===== -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Common Test Patterns</h3>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for pattern <- test_patterns() do %>
              <button
                phx-click="select_pattern"
                phx-target={@myself}
                phx-value-id={pattern.id}
                class={"btn btn-sm " <> if(@active_pattern == pattern.id, do: "btn-accent", else: "btn-outline")}
              >
                <%= pattern.title %>
              </button>
            <% end %>
          </div>

          <% pattern = Enum.find(test_patterns(), &(&1.id == @active_pattern)) %>
          <p class="text-xs opacity-60 mb-3"><%= pattern.description %></p>

          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= pattern_code(@active_pattern) %></div>
        </div>
      </div>

      <!-- ===== Section 4: Write a Test (Challenge) ===== -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Write a Test</h3>
          <p class="text-xs opacity-60 mb-4">
            Pick a function, read what it does, and write assertions to test it.
            Your code runs in a sandbox that defines the module for you.
          </p>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for ch <- challenge_functions() do %>
              <button
                phx-click="select_challenge"
                phx-target={@myself}
                phx-value-id={ch.id}
                class={"btn btn-sm " <> if(@active_challenge == ch.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= ch.name %>
              </button>
            <% end %>
          </div>

          <% challenge = Enum.find(challenge_functions(), &(&1.id == @active_challenge)) %>

          <div class="bg-base-300 rounded-lg p-4 mb-4">
            <div class="text-xs font-bold opacity-60 mb-1">Function</div>
            <div class="font-mono text-sm font-bold mb-2"><%= challenge.name %></div>
            <div class="text-sm mb-2"><%= challenge.description %></div>
            <div class="font-mono text-xs whitespace-pre-wrap bg-base-100 rounded p-2"><%= challenge.implementation %></div>
          </div>

          <div class="bg-info/10 border border-info/30 rounded-lg p-3 mb-4">
            <div class="text-xs font-bold opacity-60 mb-1">Hint</div>
            <div class="text-sm"><%= challenge.hint %></div>
          </div>

          <form phx-submit="run_challenge" phx-target={@myself} class="space-y-3">
            <input type="hidden" name="challenge_id" value={challenge.id} />
            <textarea
              name="code"
              rows="4"
              placeholder={"# Write your assertions here, e.g.:\n# assert Math.add(1, 2) == 3"}
              class="textarea textarea-bordered font-mono text-sm w-full"
              autocomplete="off"
            ><%= @challenge_input %></textarea>
            <div class="flex gap-2 items-center">
              <button type="submit" class="btn btn-primary btn-sm">Run Tests</button>
              <button
                type="button"
                phx-click="toggle_sample_tests"
                phx-target={@myself}
                class="btn btn-ghost btn-sm"
              >
                <%= if @show_sample_tests, do: "Hide Samples", else: "Show Samples" %>
              </button>
            </div>
          </form>

          <%= if @show_sample_tests do %>
            <div class="bg-base-300 rounded-lg p-3 mt-3">
              <div class="text-xs font-bold opacity-60 mb-2">Sample Assertions</div>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= Enum.join(challenge.sample_tests, "\n") %></div>
            </div>
          <% end %>

          <%= if @challenge_result do %>
            <div class={"alert text-sm mt-3 " <> if(@challenge_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono font-bold"><%= @challenge_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- ===== Section 5: Try Your Own ===== -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own</h3>
          <form phx-submit="run_custom" phx-target={@myself} class="space-y-3">
            <input
              type="text"
              name="code"
              value={@custom_code}
              placeholder="ExUnit.start(); assert 1 + 1 == 2"
              class="input input-bordered input-sm font-mono w-full"
              autocomplete="off"
            />
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Run</button>
              <span class="text-xs opacity-50 self-center">Try any Elixir expression</span>
            </div>
          </form>

          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Quick:</span>
            <%= for {label, code} <- quick_examples() do %>
              <button
                phx-click="quick_example"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @custom_result do %>
            <div class={"alert text-sm mt-3 " <> if(@custom_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @custom_result.input %></div>
                <div class="font-mono font-bold mt-1"><%= @custom_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- ===== Section 6: Key Concepts ===== -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>assert and refute are your workhorses</strong> &mdash; assert checks truthiness, refute checks falsiness. Use pattern-matching asserts for structured data.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>describe groups related tests</strong> &mdash; each describe block can have its own setup callback, keeping tests focused and DRY.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>setup runs before each test</strong> &mdash; setup_all runs once before all tests. Return <code class="font-mono bg-base-100 px-1 rounded">&lbrace;:ok, map&rbrace;</code> to make data available via the test context.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>async: true enables parallel tests</strong> &mdash; add it to your <code class="font-mono bg-base-100 px-1 rounded">use ExUnit.Case</code> call. Only safe when tests don't share mutable state.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>doctest verifies documentation examples</strong> &mdash; add <code class="font-mono bg-base-100 px-1 rounded">doctest MyModule</code> in your test file to automatically test all <code class="font-mono bg-base-100 px-1 rounded">iex&gt;</code> examples in @doc attributes.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ── Event Handlers ──

  def handle_event("select_assertion_tab", %{"id" => id}, socket) do
    {:noreply, socket |> assign(active_assertion_tab: id) |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    {:noreply, assign(socket, active_example_idx: String.to_integer(idx_str))}
  end

  def handle_event("select_structure_section", %{"id" => id}, socket) do
    {:noreply, assign(socket, active_structure_section: id)}
  end

  def handle_event("select_pattern", %{"id" => id}, socket) do
    {:noreply, assign(socket, active_pattern: id)}
  end

  def handle_event("select_challenge", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(active_challenge: id)
     |> assign(challenge_input: "")
     |> assign(challenge_result: nil)
     |> assign(show_sample_tests: false)}
  end

  def handle_event("toggle_sample_tests", _params, socket) do
    {:noreply, assign(socket, show_sample_tests: !socket.assigns.show_sample_tests)}
  end

  def handle_event("run_challenge", %{"code" => code, "challenge_id" => challenge_id}, socket) do
    challenge = Enum.find(challenge_functions(), &(&1.id == challenge_id))
    result = evaluate_challenge(code, challenge)
    {:noreply, socket |> assign(challenge_input: code) |> assign(challenge_result: result)}
  end

  def handle_event("run_custom", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))
    {:noreply, socket |> assign(custom_code: code) |> assign(custom_result: result)}
  end

  def handle_event("quick_example", %{"code" => code}, socket) do
    result = evaluate_code(code)
    {:noreply, socket |> assign(custom_code: code) |> assign(custom_result: result)}
  end

  # ── Helpers ──

  defp assertion_tabs, do: @assertion_tabs
  defp test_structure_sections, do: @test_structure_sections
  defp test_patterns, do: @test_patterns
  defp challenge_functions, do: @challenge_functions

  defp structure_code("basic_test") do
    """
    # test/my_module_test.exs
    defmodule MyModuleTest do
      use ExUnit.Case, async: true

      test "greets the world" do
        assert MyModule.hello() == :world
      end

      test "adds two numbers" do
        result = MyModule.add(1, 2)
        assert result == 3
      end
    end

    # Run with: mix test
    # Run single file: mix test test/my_module_test.exs
    # Run single test: mix test test/my_module_test.exs:5\
    """
  end

  defp structure_code("describe_blocks") do
    """
    defmodule CalculatorTest do
      use ExUnit.Case, async: true

      describe "add/2" do
        test "adds positive numbers" do
          assert Calculator.add(1, 2) == 3
        end

        test "adds negative numbers" do
          assert Calculator.add(-1, -2) == -3
        end

        test "adding zero returns the same number" do
          assert Calculator.add(5, 0) == 5
        end
      end

      describe "divide/2" do
        test "divides evenly" do
          assert Calculator.divide(10, 2) == 5.0
        end

        test "returns error for division by zero" do
          assert Calculator.divide(10, 0) == {:error, :div_by_zero}
        end
      end
    end\
    """
  end

  defp structure_code("setup_callbacks") do
    """
    defmodule UserTest do
      use ExUnit.Case, async: true

      # Runs before EACH test -- receives context, returns data
      setup do
        user = %{name: "Alice", age: 30, role: :admin}
        {:ok, user: user}
      end

      # Access setup data via the test context map
      test "user has a name", %{user: user} do
        assert user.name == "Alice"
      end

      test "user is an admin", %{user: user} do
        assert user.role == :admin
      end

      # setup_all runs ONCE before all tests in the module
      # setup_all do
      #   {:ok, db: start_test_database()}
      # end
    end\
    """
  end

  defp structure_code("async_tags") do
    """
    defmodule TaggedTest do
      use ExUnit.Case, async: true  # <-- enables parallel execution

      # Tags let you include/exclude tests
      @tag :slow
      test "a slow integration test" do
        # mix test --only slow
        Process.sleep(1000)
        assert true
      end

      @tag :skip
      test "work in progress" do
        # Skipped by default with @tag :skip
        assert false
      end

      # @describetag applies to all tests in a describe block
      @describetag :api
      describe "API tests" do
        test "fetches users" do
          # mix test --only api
          assert true
        end
      end
    end

    # CLI examples:
    # mix test --only slow        # run only @tag :slow
    # mix test --exclude slow     # skip @tag :slow
    # mix test --only api         # run only @describetag :api\
    """
  end

  defp structure_code("doctest") do
    """
    # In your module:
    defmodule StringHelper do
      @doc \"\"\"
      Upcases the first letter.

      ## Examples

          iex> StringHelper.upcase_first("hello")
          "Hello"

          iex> StringHelper.upcase_first("")
          ""
      \"\"\"
      def upcase_first(<<first::utf8, rest::binary>>),
        do: String.upcase(<<first::utf8>>) <> rest
      def upcase_first(""), do: ""
    end

    # In your test file:
    defmodule StringHelperTest do
      use ExUnit.Case, async: true
      doctest StringHelper  # <-- auto-tests all iex> examples
    end\
    """
  end

  defp pattern_code("ok_error") do
    """
    # Testing functions that return {:ok, value} or {:error, reason}

    test "successful lookup returns {:ok, user}" do
      assert {:ok, user} = Users.find_by_email("alice@example.com")
      assert user.name == "Alice"
      assert user.email == "alice@example.com"
    end

    test "missing user returns :error" do
      assert {:error, :not_found} = Users.find_by_email("nobody@example.com")
    end

    # Pattern match assert is powerful -- it both asserts
    # the shape AND binds variables for further assertions\
    """
  end

  defp pattern_code("lists") do
    """
    # Testing list contents

    test "returns all active users" do
      users = Users.active()

      # Check length
      assert length(users) == 3

      # Check membership
      assert "Alice" in Enum.map(users, & &1.name)

      # Check exact contents (order matters)
      assert [1, 2, 3] = Enum.sort(some_list)

      # Check subset
      assert MapSet.subset?(
        MapSet.new([:read, :write]),
        MapSet.new(user.permissions)
      )
    end

    test "returns empty list when no results" do
      assert [] = Users.search("zzz_nonexistent")
    end\
    """
  end

  defp pattern_code("exceptions") do
    """
    # Testing that functions raise exceptions

    test "raises on invalid input" do
      assert_raise ArgumentError, fn ->
        Parser.parse!(nil)
      end
    end

    test "raises with specific message" do
      assert_raise RuntimeError, "connection lost", fn ->
        Client.connect!("bad_host")
      end
    end

    test "raises FunctionClauseError on wrong type" do
      assert_raise FunctionClauseError, fn ->
        Calculator.add("not", "numbers")
      end
    end\
    """
  end

  defp pattern_code("maps_structs") do
    """
    # Testing maps and structs with pattern matching

    test "returns a user map with expected fields" do
      user = Users.build("Alice", "alice@example.com")

      # Pattern match assert -- checks shape
      assert %{name: "Alice", email: "alice@example.com"} = user

      # Extra keys are OK in pattern match assert
      # (user may have :id, :inserted_at, etc.)

      # If you need exact match, use ==
      assert user == %User{name: "Alice", email: "alice@example.com"}
    end

    test "updates only the specified field" do
      original = %{name: "Alice", age: 30, role: :user}
      updated = Users.promote(original)

      assert updated.role == :admin
      assert updated.name == original.name  # unchanged
    end\
    """
  end

  defp evaluate_challenge(code, challenge) do
    code = String.trim(code)

    if code == "" do
      %{ok: false, input: code, output: "Write at least one assertion!"}
    else
      module_code = build_challenge_module(challenge)
      full_code = module_code <> "\nimport ExUnit.Assertions\n" <> code

      try do
        {result, _} = Code.eval_string(full_code)
        %{ok: true, input: code, output: "All assertions passed! Result: #{inspect(result)}"}
      rescue
        e -> %{ok: false, input: code, output: "Assertion failed: #{Exception.message(e)}"}
      end
    end
  end

  defp build_challenge_module(%{id: "add"}) do
    """
    defmodule Math do
      def add(a, b), do: a + b
    end
    """
  end

  defp build_challenge_module(%{id: "safe_div"}) do
    """
    defmodule Math do
      def safe_div(_a, 0), do: {:error, :div_by_zero}
      def safe_div(a, b), do: {:ok, a / b}
    end
    """
  end

  defp build_challenge_module(%{id: "upcase_first"}) do
    """
    defmodule StringHelper do
      def upcase_first(<<first::utf8, rest::binary>>), do: String.upcase(<<first::utf8>>) <> rest
      def upcase_first(""), do: ""
    end
    """
  end

  defp build_challenge_module(_), do: ""

  defp quick_examples do
    [
      {"assert equal", "import ExUnit.Assertions; assert 2 + 2 == 4"},
      {"pattern match", "import ExUnit.Assertions; assert {:ok, _} = {:ok, 42}"},
      {"assert_raise", "import ExUnit.Assertions; assert_raise ArithmeticError, fn -> 1 / 0 end"},
      {"refute", "import ExUnit.Assertions; refute nil"}
    ]
  end

  defp evaluate_code(code) do
    try do
      {result, _} = Code.eval_string(code)
      %{ok: true, input: code, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, input: code, output: "Error: #{Exception.message(e)}"}
    end
  end
end
