defmodule ElixirKatasWeb.PhoenixKataData do
  @moduledoc """
  Shared data module for Phoenix Web Katas sections, tags, and colors.
  Used by both the sidebar layout and the index page.
  """

  @tag_colors %{
    "http" => "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
    "routing" => "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200",
    "controllers" => "bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200",
    "templates" => "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200",
    "plugs" => "bg-rose-100 text-rose-800 dark:bg-rose-900 dark:text-rose-200",
    "ecto" => "bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200",
    "channels" => "bg-violet-100 text-violet-800 dark:bg-violet-900 dark:text-violet-200",
    "security" => "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200",
    "testing" => "bg-cyan-100 text-cyan-800 dark:bg-cyan-900 dark:text-cyan-200",
    "architecture" => "bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200",
    "deployment" => "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200",
    "cowboy" => "bg-teal-100 text-teal-800 dark:bg-teal-900 dark:text-teal-200",
    "components" => "bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-200"
  }

  def all_tags, do: Map.keys(@tag_colors) |> Enum.sort()
  def tag_color(tag), do: Map.get(@tag_colors, tag, "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200")

  def sections do
    [
      %{title: "Section 0: Foundations", katas: [
        %{num: "00", slug: "00-phoenix-fundamentals", label: "00 - Phoenix Fundamentals", color: "bg-amber-500", tags: ["http", "routing", "plugs"], description: "What is Phoenix, MVC architecture, request lifecycle, project structure, Mix tasks, Plug & Conn"}
      ]},

      %{title: "Section 1: How the Web Works", katas: [
        %{num: "01", slug: "01-http-protocol", label: "01 - HTTP Protocol", color: "bg-blue-400", tags: ["http"], description: "Request/response cycle, HTTP methods, status codes, headers, body"},
        %{num: "02", slug: "02-urls-paths-query-strings", label: "02 - URLs, Paths & Query Strings", color: "bg-blue-500", tags: ["http", "routing"], description: "Anatomy of a URL, path segments, query parameters, encoding"},
        %{num: "03", slug: "03-html-and-forms", label: "03 - HTML & Forms", color: "bg-blue-600", tags: ["http", "templates"], description: "How browsers send data, GET vs POST, form encoding, multipart"},
        %{num: "04", slug: "04-client-server-architecture", label: "04 - Client-Server Architecture", color: "bg-blue-700", tags: ["http", "architecture"], description: "Browser, DNS, server, database, static vs dynamic content"},
        %{num: "05", slug: "05-state-on-the-web", label: "05 - State on the Web", color: "bg-blue-800", tags: ["http", "security"], description: "Cookies, sessions, tokens, stateless HTTP, authentication basics"}
      ]},

      %{title: "Section 2: Elixir Web Stack (Before Phoenix)", katas: [
        %{num: "06", slug: "06-tcp-sockets-in-elixir", label: "06 - TCP Sockets in Elixir", color: "bg-teal-400", tags: ["http", "cowboy"], description: "Raw :gen_tcp server, accepting connections, sending responses"},
        %{num: "07", slug: "07-parsing-http-by-hand", label: "07 - Parsing HTTP by Hand", color: "bg-teal-500", tags: ["http", "cowboy"], description: "Reading request line, headers, building an HTTP response from scratch"},
        %{num: "08", slug: "08-cowboy-and-ranch", label: "08 - Cowboy & Ranch", color: "bg-teal-600", tags: ["cowboy"], description: "The HTTP server under Phoenix, handlers, dispatch rules"},
        %{num: "09", slug: "09-plug-basics", label: "09 - Plug Basics", color: "bg-rose-400", tags: ["plugs"], description: "The Plug specification, function plugs, module plugs, Plug.Conn"},
        %{num: "10", slug: "10-plug-router", label: "10 - Plug Router", color: "bg-rose-500", tags: ["plugs", "routing"], description: "Plug.Router, building a mini web app without Phoenix"},
        %{num: "11", slug: "11-composing-plugs", label: "11 - Composing Plugs", color: "bg-rose-600", tags: ["plugs"], description: "Plug pipelines, halt, middleware pattern, request/response flow"}
      ]},

      %{title: "Section 3: Phoenix - First Steps", katas: [
        %{num: "12", slug: "12-mix-phx-new", label: "12 - mix phx.new", color: "bg-amber-400", tags: ["architecture"], description: "Project generator, what each file does, directory walkthrough"},
        %{num: "13", slug: "13-endpoint-and-config", label: "13 - Endpoint & Config", color: "bg-amber-500", tags: ["architecture", "plugs"], description: "endpoint.ex, config.exs, how Phoenix boots and processes requests"},
        %{num: "14", slug: "14-your-first-route", label: "14 - Your First Route", color: "bg-amber-600", tags: ["routing"], description: "router.ex, GET route, scope, pipe_through, rendering a page"},
        %{num: "15", slug: "15-route-parameters", label: "15 - Route Parameters", color: "bg-amber-700", tags: ["routing"], description: "Path params, query params, catch-all routes, pattern matching URLs"}
      ]},

      %{title: "Section 4: Routing in Depth", katas: [
        %{num: "16", slug: "16-restful-resources", label: "16 - RESTful Resources", color: "bg-orange-400", tags: ["routing", "controllers"], description: "resources macro, all 7 CRUD routes, only/except options"},
        %{num: "17", slug: "17-nested-routes-and-scopes", label: "17 - Nested Routes & Scopes", color: "bg-orange-500", tags: ["routing"], description: "scope, namespace, nested resources, route grouping"},
        %{num: "18", slug: "18-pipelines", label: "18 - Pipelines", color: "bg-orange-600", tags: ["routing", "plugs"], description: "Custom pipelines, plug chains in router, :browser vs :api"},
        %{num: "19", slug: "19-verified-routes", label: "19 - Verified Routes", color: "bg-orange-700", tags: ["routing"], description: "~p sigil, compile-time verified paths, path generation helpers"}
      ]},

      %{title: "Section 5: Controllers & Responses", katas: [
        %{num: "20", slug: "20-controller-basics", label: "20 - Controller Basics", color: "bg-amber-400", tags: ["controllers"], description: "Actions, conn, render, redirect, text and html responses"},
        %{num: "21", slug: "21-request-params", label: "21 - Request Params & Pattern Matching", color: "bg-amber-500", tags: ["controllers"], description: "Matching params in function heads, required vs optional params"},
        %{num: "22", slug: "22-json-apis", label: "22 - JSON APIs", color: "bg-amber-600", tags: ["controllers"], description: "json/2, API controller patterns, content negotiation, status codes"},
        %{num: "23", slug: "23-flash-and-redirects", label: "23 - Flash Messages & Redirects", color: "bg-amber-700", tags: ["controllers"], description: "put_flash, redirect, session data, PRG pattern"},
        %{num: "24", slug: "24-error-handling", label: "24 - Error Handling", color: "bg-amber-800", tags: ["controllers"], description: "action_fallback, error views, 404/500 pages, custom error pages"}
      ]},

      %{title: "Section 6: Views & Templates", katas: [
        %{num: "25", slug: "25-heex-templates", label: "25 - HEEx Templates", color: "bg-yellow-400", tags: ["templates"], description: "Embedded Elixir, expressions, attributes, conditionals, loops"},
        %{num: "26", slug: "26-layouts", label: "26 - Layouts", color: "bg-yellow-500", tags: ["templates"], description: "Root layout, app layout, nested layouts, @inner_content"},
        %{num: "27", slug: "27-function-components", label: "27 - Function Components", color: "bg-yellow-600", tags: ["templates", "components"], description: "attr, slot, component composition, reusable UI pieces"},
        %{num: "28", slug: "28-helpers-and-assigns", label: "28 - Helpers & Assigns", color: "bg-yellow-700", tags: ["templates"], description: "assign, verified routes, link, navigation helpers"},
        %{num: "29", slug: "29-static-assets", label: "29 - Static Assets", color: "bg-yellow-800", tags: ["templates", "architecture"], description: "esbuild, tailwind, priv/static, cache busting, asset pipeline"}
      ]},

      %{title: "Section 7: Custom Plugs", katas: [
        %{num: "30", slug: "30-function-plugs", label: "30 - Function Plugs", color: "bg-rose-400", tags: ["plugs"], description: "Inline request transformations, adding assigns, logging"},
        %{num: "31", slug: "31-module-plugs", label: "31 - Module Plugs", color: "bg-rose-500", tags: ["plugs"], description: "init/call callbacks, options, reusable middleware modules"},
        %{num: "32", slug: "32-plug-conn-deep-dive", label: "32 - Plug.Conn Deep Dive", color: "bg-rose-600", tags: ["plugs"], description: "assigns, private, halting, response headers, status codes"},
        %{num: "33", slug: "33-authentication-plug", label: "33 - Authentication Plug", color: "bg-rose-700", tags: ["plugs", "security"], description: "Session-based auth plug, protecting routes, current_user"}
      ]},

      %{title: "Section 8: Ecto Foundations", katas: [
        %{num: "34", slug: "34-schema-and-migration", label: "34 - Schema & Migration", color: "bg-emerald-400", tags: ["ecto"], description: "Ecto schema, field types, timestamps, mix ecto.gen.migration"},
        %{num: "35", slug: "35-changesets-and-validation", label: "35 - Changesets & Validation", color: "bg-emerald-500", tags: ["ecto"], description: "cast, validate_required, validate_format, custom validators"},
        %{num: "36", slug: "36-repo-basics", label: "36 - Repo Basics", color: "bg-emerald-600", tags: ["ecto"], description: "Repo.insert, get, all, update, delete — full CRUD operations"},
        %{num: "37", slug: "37-ecto-queries", label: "37 - Queries with Ecto.Query", color: "bg-emerald-700", tags: ["ecto"], description: "from, where, select, order_by, join, subqueries"},
        %{num: "38", slug: "38-associations", label: "38 - Associations", color: "bg-emerald-800", tags: ["ecto"], description: "has_many, belongs_to, many_to_many, preloading, nested changesets"}
      ]},

      %{title: "Section 9: Contexts & Architecture", katas: [
        %{num: "39", slug: "39-phoenix-contexts", label: "39 - Phoenix Contexts", color: "bg-indigo-400", tags: ["architecture"], description: "Boundary modules, public API design, mix phx.gen.context"},
        %{num: "40", slug: "40-context-functions", label: "40 - Context Functions", color: "bg-indigo-500", tags: ["architecture"], description: "CRUD patterns, list/get/create/update/delete, error tuples"},
        %{num: "41", slug: "41-multi-context-interactions", label: "41 - Multi-Context Interactions", color: "bg-indigo-600", tags: ["architecture"], description: "Cross-context calls, data flow, keeping boundaries clean"}
      ]},

      %{title: "Section 10: Authentication & Security", katas: [
        %{num: "42", slug: "42-phoenix-auth-generator", label: "42 - Phoenix Auth Generator", color: "bg-red-400", tags: ["security"], description: "mix phx.gen.auth walkthrough, generated code explained"},
        %{num: "43", slug: "43-session-management", label: "43 - Session Management", color: "bg-red-500", tags: ["security"], description: "Login, logout, remember me, session tokens, cookie security"},
        %{num: "44", slug: "44-authorization", label: "44 - Authorization", color: "bg-red-600", tags: ["security"], description: "Role-based access, policy patterns, scope-based authorization"},
        %{num: "45", slug: "45-csrf-and-security-headers", label: "45 - CSRF & Security Headers", color: "bg-red-700", tags: ["security", "plugs"], description: "protect_from_forgery, CSP, secure headers, OWASP basics"}
      ]},

      %{title: "Section 11: Channels & Real-time", katas: [
        %{num: "46", slug: "46-websockets-primer", label: "46 - WebSockets Primer", color: "bg-violet-400", tags: ["channels", "http"], description: "Why WebSockets, upgrade handshake, full-duplex vs HTTP"},
        %{num: "47", slug: "47-channel-basics", label: "47 - Channel Basics", color: "bg-violet-500", tags: ["channels"], description: "Socket, topic, join, handle_in, push, channel lifecycle"},
        %{num: "48", slug: "48-broadcasting-and-presence", label: "48 - Broadcasting & Presence", color: "bg-violet-600", tags: ["channels"], description: "broadcast, PubSub, presence tracking, online users"}
      ]},

      %{title: "Section 12: Testing", katas: [
        %{num: "49", slug: "49-controller-tests", label: "49 - Controller Tests", color: "bg-cyan-400", tags: ["testing"], description: "ConnTest, get/post assertions, response status, body matching"},
        %{num: "50", slug: "50-context-tests", label: "50 - Context Tests", color: "bg-cyan-500", tags: ["testing", "ecto"], description: "DataCase, fixtures, test helpers, testing business logic"},
        %{num: "51", slug: "51-integration-tests", label: "51 - Integration Tests", color: "bg-cyan-600", tags: ["testing"], description: "Feature tests, end-to-end flows, testing full request cycles"}
      ]},

      %{title: "Section 13: Production & Deployment", katas: [
        %{num: "52", slug: "52-configuration", label: "52 - Configuration", color: "bg-gray-400", tags: ["deployment"], description: "config/runtime.exs, environment variables, secrets management"},
        %{num: "53", slug: "53-mix-releases", label: "53 - Mix Releases", color: "bg-gray-500", tags: ["deployment"], description: "mix release, self-contained builds, Dockerfile basics"},
        %{num: "54", slug: "54-telemetry-and-monitoring", label: "54 - Telemetry & Monitoring", color: "bg-gray-600", tags: ["deployment"], description: "Telemetry events, LiveDashboard, metrics, health checks"}
      ]}
    ]
  end
end
