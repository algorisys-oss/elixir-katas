defmodule ElixirKatasWeb.PhoenixApiKataData do
  @moduledoc """
  Shared data module for Phoenix API Katas sections, tags, and colors.
  Used by both the sidebar layout and the index page.
  """

  @tag_colors %{
    "rest" => "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
    "json" => "bg-sky-100 text-sky-800 dark:bg-sky-900 dark:text-sky-200",
    "routing" => "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200",
    "controllers" => "bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200",
    "authentication" => "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200",
    "authorization" => "bg-rose-100 text-rose-800 dark:bg-rose-900 dark:text-rose-200",
    "uploads" => "bg-violet-100 text-violet-800 dark:bg-violet-900 dark:text-violet-200",
    "pagination" => "bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200",
    "plugs" => "bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-200",
    "security" => "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200",
    "testing" => "bg-cyan-100 text-cyan-800 dark:bg-cyan-900 dark:text-cyan-200",
    "advanced" => "bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200",
    "error-handling" => "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200",
    "streaming" => "bg-teal-100 text-teal-800 dark:bg-teal-900 dark:text-teal-200"
  }

  def all_tags, do: Map.keys(@tag_colors) |> Enum.sort()
  def tag_color(tag), do: Map.get(@tag_colors, tag, "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200")

  def sections do
    [
      %{title: "Section 0: API Foundations", katas: [
        %{num: "00", slug: "00-rest-fundamentals", label: "00 - REST Fundamentals", color: "bg-blue-500", tags: ["rest", "json"], description: "RESTful conventions, JSON API design, resource naming, HTTP methods & status codes"}
      ]},

      %{title: "Section 1: API Routing & Controllers", katas: [
        %{num: "01", slug: "01-api-pipeline", label: "01 - API Pipeline", color: "bg-orange-400", tags: ["routing", "plugs"], description: "The :api pipeline, accepts JSON, API-specific plugs vs browser plugs"},
        %{num: "02", slug: "02-resource-routes", label: "02 - Resource Routes & Controllers", color: "bg-orange-500", tags: ["routing", "controllers"], description: "API resource routes, controller actions, json/2 responses, nested resources"}
      ]},

      %{title: "Section 2: Request & Response", katas: [
        %{num: "03", slug: "03-params-and-json", label: "03 - Params & JSON Encoding", color: "bg-sky-400", tags: ["json", "controllers"], description: "Parsing body/query params, Jason encoding/decoding, content negotiation"},
        %{num: "04", slug: "04-status-codes-and-responses", label: "04 - Status Codes & Responses", color: "bg-sky-500", tags: ["rest", "json"], description: "Proper status codes (200, 201, 204, 400, 404, 422), response structure patterns"},
        %{num: "05", slug: "05-error-handling", label: "05 - Error Handling & Fallback", color: "bg-sky-600", tags: ["error-handling", "controllers"], description: "FallbackController, ErrorJSON, changeset errors, consistent error responses"}
      ]},

      %{title: "Section 3: Authentication", katas: [
        %{num: "06", slug: "06-bearer-token-auth", label: "06 - Bearer Token Auth", color: "bg-red-400", tags: ["authentication", "plugs"], description: "Authorization header, Bearer tokens, token verification plug, 401 responses"},
        %{num: "07", slug: "07-jwt-authentication", label: "07 - JWT Authentication", color: "bg-red-500", tags: ["authentication", "security"], description: "Issuing JWTs, signing & verification, claims, token expiry, refresh tokens"},
        %{num: "08", slug: "08-api-keys", label: "08 - API Keys", color: "bg-red-600", tags: ["authentication", "security"], description: "API key generation, header-based auth, rate limiting per key, key rotation"}
      ]},

      %{title: "Section 4: Authorization", katas: [
        %{num: "09", slug: "09-role-based-access", label: "09 - Role-Based Access", color: "bg-rose-400", tags: ["authorization", "plugs"], description: "User roles, role-checking plugs, admin vs user endpoints, scope-based access"},
        %{num: "10", slug: "10-policy-modules", label: "10 - Policy Modules", color: "bg-rose-500", tags: ["authorization", "controllers"], description: "Policy pattern, resource-level authorization, ownership checks, Bodyguard-style policies"}
      ]},

      %{title: "Section 5: File Operations", katas: [
        %{num: "11", slug: "11-file-uploads", label: "11 - File Uploads", color: "bg-violet-400", tags: ["uploads", "controllers"], description: "Multipart uploads via API, Plug.Upload, file validation, storage strategies"},
        %{num: "12", slug: "12-file-downloads-and-streaming", label: "12 - File Downloads & Streaming", color: "bg-violet-500", tags: ["uploads", "streaming"], description: "send_download, streaming large files, content-disposition, presigned URLs"}
      ]},

      %{title: "Section 6: Data & Pagination", katas: [
        %{num: "13", slug: "13-filtering-and-sorting", label: "13 - Filtering & Sorting", color: "bg-emerald-400", tags: ["pagination", "rest"], description: "Query param filtering, sort by column, composable Ecto query patterns"},
        %{num: "14", slug: "14-pagination", label: "14 - Pagination", color: "bg-emerald-500", tags: ["pagination", "rest"], description: "Offset pagination, cursor-based pagination, page metadata, Link headers"}
      ]},

      %{title: "Section 7: Middleware & Security", katas: [
        %{num: "15", slug: "15-rate-limiting", label: "15 - Rate Limiting", color: "bg-pink-400", tags: ["security", "plugs"], description: "Rate limiting plug, per-IP and per-key limits, 429 responses, Hammer library"},
        %{num: "16", slug: "16-cors-and-security", label: "16 - CORS & Security Headers", color: "bg-pink-500", tags: ["security", "plugs"], description: "CORS plug configuration, allowed origins, preflight requests, security headers"}
      ]},

      %{title: "Section 8: Testing APIs", katas: [
        %{num: "17", slug: "17-api-controller-tests", label: "17 - API Controller Tests", color: "bg-cyan-400", tags: ["testing", "controllers"], description: "ConnTest for JSON APIs, testing status codes, response bodies, error cases"},
        %{num: "18", slug: "18-authenticated-endpoint-tests", label: "18 - Authenticated Endpoint Tests", color: "bg-cyan-500", tags: ["testing", "authentication"], description: "Test helpers for auth, setup tokens, testing protected routes, role-based test scenarios"}
      ]},

      %{title: "Section 9: Advanced", katas: [
        %{num: "19", slug: "19-webhooks-and-openapi", label: "19 - Webhooks & OpenAPI", color: "bg-indigo-500", tags: ["advanced", "rest"], description: "Receiving & sending webhooks, signature verification, OpenAPI spec generation, background jobs"}
      ]}
    ]
  end
end
