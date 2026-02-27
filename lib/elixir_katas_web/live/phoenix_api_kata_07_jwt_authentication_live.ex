defmodule ElixirKatasWeb.PhoenixApiKata07JwtAuthenticationLive do
  use ElixirKatasWeb, :live_component

  @sample_header %{"alg" => "HS256", "typ" => "JWT"}
  @sample_payload %{
    "sub" => "user_42",
    "name" => "Alice",
    "email" => "alice@example.com",
    "role" => "admin",
    "iat" => 1_700_000_000,
    "exp" => 1_700_086_400,
    "iss" => "my_app"
  }
  @sample_secret "super_secret_key_256_bits_long!!"

  @claims_info [
    %{claim: "sub", full: "Subject", desc: "Who the token is about (user ID)"},
    %{claim: "iat", full: "Issued At", desc: "Unix timestamp when the token was created"},
    %{claim: "exp", full: "Expiration", desc: "Unix timestamp when the token expires"},
    %{claim: "iss", full: "Issuer", desc: "Who issued the token (your app)"},
    %{claim: "aud", full: "Audience", desc: "Who the token is intended for"},
    %{claim: "nbf", full: "Not Before", desc: "Token is not valid before this time"},
    %{claim: "jti", full: "JWT ID", desc: "Unique identifier to prevent replay attacks"}
  ]

  def phoenix_source do
    """
    # JWT Authentication in Elixir
    #
    # JWTs are self-contained tokens: header.payload.signature
    # The server can verify them without a database lookup.

    defmodule MyApp.Token do
      @secret Application.compile_env!(:my_app, :jwt_secret)
      @expiry_seconds 86_400  # 24 hours

      # Generate a JWT for a user
      def generate(user) do
        header = %{"alg" => "HS256", "typ" => "JWT"}

        payload = %{
          "sub" => to_string(user.id),
          "email" => user.email,
          "role" => user.role,
          "iat" => System.system_time(:second),
          "exp" => System.system_time(:second) + @expiry_seconds,
          "iss" => "my_app"
        }

        # Encode header and payload
        header_b64  = Base.url_encode64(Jason.encode!(header), padding: false)
        payload_b64 = Base.url_encode64(Jason.encode!(payload), padding: false)

        # Sign with HMAC-SHA256
        signing_input = header_b64 <> "." <> payload_b64
        signature = :crypto.mac(:hmac, :sha256, @secret, signing_input)
        signature_b64 = Base.url_encode64(signature, padding: false)

        # Assemble the JWT
        signing_input <> "." <> signature_b64
      end

      # Verify and decode a JWT
      def verify(token) do
        with [header_b64, payload_b64, signature_b64] <- String.split(token, "."),
             {:ok, signature} <- Base.url_decode64(signature_b64, padding: false),
             true <- valid_signature?(header_b64, payload_b64, signature),
             {:ok, payload_json} <- Base.url_decode64(payload_b64, padding: false),
             {:ok, payload} <- Jason.decode(payload_json),
             :ok <- check_expiry(payload) do
          {:ok, payload}
        else
          _ -> {:error, :invalid_token}
        end
      end

      defp valid_signature?(header_b64, payload_b64, signature) do
        expected = :crypto.mac(:hmac, :sha256, @secret, header_b64 <> "." <> payload_b64)
        :crypto.hash_equals(expected, signature)
      end

      defp check_expiry(%{"exp" => exp}) do
        if System.system_time(:second) < exp, do: :ok, else: {:error, :expired}
      end
      defp check_expiry(_), do: :ok
    end

    # Using the Token module in a plug:
    defmodule MyAppWeb.Plugs.VerifyJWT do
      import Plug.Conn

      def init(opts), do: opts

      def call(conn, _opts) do
        with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
             {:ok, claims} <- MyApp.Token.verify(token) do
          assign(conn, :current_user_claims, claims)
        else
          _ ->
            conn
            |> put_status(:unauthorized)
            |> Phoenix.Controller.json(%{errors: %{detail: "Invalid or expired token"}})
            |> halt()
        end
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    header_json = Jason.encode!(@sample_header, pretty: true)
    payload_json = Jason.encode!(@sample_payload, pretty: true)

    header_b64 = Base.url_encode64(Jason.encode!(@sample_header), padding: false)
    payload_b64 = Base.url_encode64(Jason.encode!(@sample_payload), padding: false)
    signing_input = header_b64 <> "." <> payload_b64
    signature = :crypto.mac(:hmac, :sha256, @sample_secret, signing_input)
    signature_b64 = Base.url_encode64(signature, padding: false)
    full_jwt = signing_input <> "." <> signature_b64

    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(header_json: header_json)
     |> assign(payload_json: payload_json)
     |> assign(header_b64: header_b64)
     |> assign(payload_b64: payload_b64)
     |> assign(signature_b64: signature_b64)
     |> assign(full_jwt: full_jwt)
     |> assign(claims_info: @claims_info)
     |> assign(active_part: nil)
     |> assign(decode_input: "")
     |> assign(decode_result: nil)
     |> assign(flow_step: 0)
     |> assign(verify_mode: nil)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">JWT Authentication</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Explore the structure of JSON Web Tokens. Click each part to decode it, or step through the
        generation and verification flow.
      </p>

      <!-- JWT Structure Display -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">JWT Structure: header.payload.signature</h3>
        <div class="bg-gray-900 rounded-lg p-4 overflow-x-auto">
          <div class="font-mono text-sm break-all">
            <button
              phx-click="select_part"
              phx-value-part="header"
              phx-target={@myself}
              class={["cursor-pointer transition-all hover:underline", if(@active_part == "header", do: "text-rose-400 font-bold", else: "text-rose-400")]}
            >{@header_b64}</button><span class="text-gray-500">.</span><button
              phx-click="select_part"
              phx-value-part="payload"
              phx-target={@myself}
              class={["cursor-pointer transition-all hover:underline", if(@active_part == "payload", do: "text-purple-400 font-bold", else: "text-purple-400")]}
            >{@payload_b64}</button><span class="text-gray-500">.</span><button
              phx-click="select_part"
              phx-value-part="signature"
              phx-target={@myself}
              class={["cursor-pointer transition-all hover:underline", if(@active_part == "signature", do: "text-cyan-400 font-bold", else: "text-cyan-400")]}
            >{@signature_b64}</button>
          </div>
        </div>

        <!-- Color Legend -->
        <div class="flex flex-wrap gap-4 mt-3 text-sm">
          <div class="flex items-center gap-1.5">
            <span class="w-3 h-3 rounded-full bg-rose-500"></span>
            <span class="text-gray-600 dark:text-gray-400">Header (algorithm + type)</span>
          </div>
          <div class="flex items-center gap-1.5">
            <span class="w-3 h-3 rounded-full bg-purple-500"></span>
            <span class="text-gray-600 dark:text-gray-400">Payload (claims)</span>
          </div>
          <div class="flex items-center gap-1.5">
            <span class="w-3 h-3 rounded-full bg-cyan-500"></span>
            <span class="text-gray-600 dark:text-gray-400">Signature (HMAC)</span>
          </div>
        </div>
      </div>

      <!-- Decoded Part Display -->
      <%= if @active_part do %>
        <div class={["p-4 rounded-lg border-2",
          case @active_part do
            "header" -> "border-rose-300 dark:border-rose-700 bg-rose-50 dark:bg-rose-900/20"
            "payload" -> "border-purple-300 dark:border-purple-700 bg-purple-50 dark:bg-purple-900/20"
            "signature" -> "border-cyan-300 dark:border-cyan-700 bg-cyan-50 dark:bg-cyan-900/20"
            _ -> ""
          end
        ]}>
          <h4 class={["font-semibold mb-2",
            case @active_part do
              "header" -> "text-rose-800 dark:text-rose-300"
              "payload" -> "text-purple-800 dark:text-purple-300"
              "signature" -> "text-cyan-800 dark:text-cyan-300"
              _ -> ""
            end
          ]}>
            Decoded: {String.capitalize(@active_part)}
          </h4>
          <div class="bg-gray-900 rounded-lg p-3 font-mono text-sm">
            <%= if @active_part == "signature" do %>
              <pre class="text-cyan-400 whitespace-pre-wrap"><%= signature_explanation() %></pre>
            <% else %>
              <pre class={["whitespace-pre-wrap", if(@active_part == "header", do: "text-rose-400", else: "text-purple-400")]}><%= if @active_part == "header", do: @header_json, else: @payload_json %></pre>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Registered Claims Reference -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Registered Claims (RFC 7519)</h3>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
          <%= for claim <- @claims_info do %>
            <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
              <div class="flex items-center gap-2 mb-0.5">
                <code class="text-rose-600 dark:text-rose-400 font-bold text-sm">{claim.claim}</code>
                <span class="text-sm text-gray-500 dark:text-gray-400">({claim.full})</span>
              </div>
              <p class="text-sm text-gray-600 dark:text-gray-400">{claim.desc}</p>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Token Generation/Verification Flow -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Token Flow Simulator</h3>
        <div class="flex flex-wrap gap-2 mb-4">
          <button
            phx-click="start_flow"
            phx-value-mode="generate"
            phx-target={@myself}
            class={["px-4 py-2 text-sm rounded-lg font-medium transition-colors cursor-pointer",
              if(@verify_mode == "generate",
                do: "bg-rose-600 text-white",
                else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600")
            ]}
          >
            Generate Token
          </button>
          <button
            phx-click="start_flow"
            phx-value-mode="verify_valid"
            phx-target={@myself}
            class={["px-4 py-2 text-sm rounded-lg font-medium transition-colors cursor-pointer",
              if(@verify_mode == "verify_valid",
                do: "bg-emerald-600 text-white",
                else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600")
            ]}
          >
            Verify Valid Token
          </button>
          <button
            phx-click="start_flow"
            phx-value-mode="verify_expired"
            phx-target={@myself}
            class={["px-4 py-2 text-sm rounded-lg font-medium transition-colors cursor-pointer",
              if(@verify_mode == "verify_expired",
                do: "bg-amber-600 text-white",
                else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600")
            ]}
          >
            Verify Expired Token
          </button>
          <button
            phx-click="start_flow"
            phx-value-mode="verify_tampered"
            phx-target={@myself}
            class={["px-4 py-2 text-sm rounded-lg font-medium transition-colors cursor-pointer",
              if(@verify_mode == "verify_tampered",
                do: "bg-red-600 text-white",
                else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600")
            ]}
          >
            Verify Tampered Token
          </button>
        </div>

        <%= if @verify_mode do %>
          <% steps = flow_steps(@verify_mode) %>
          <div class="flex items-center justify-end mb-3 gap-2">
            <button
              phx-click="reset_flow"
              phx-target={@myself}
              class="px-3 py-1.5 text-sm bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors cursor-pointer"
            >
              Reset
            </button>
            <button
              phx-click="next_flow_step"
              phx-target={@myself}
              disabled={@flow_step >= length(steps)}
              class={["px-4 py-1.5 text-sm rounded-lg font-medium transition-colors cursor-pointer",
                if(@flow_step >= length(steps),
                  do: "bg-gray-300 dark:bg-gray-700 text-gray-500 cursor-not-allowed",
                  else: "bg-rose-600 hover:bg-rose-700 text-white")
              ]}
            >
              <%= if @flow_step == 0, do: "Start", else: "Next Step" %>
            </button>
          </div>

          <div class="space-y-3">
            <%= for {step, i} <- Enum.with_index(steps) do %>
              <div class={["flex items-start gap-4 p-4 rounded-lg transition-all duration-300",
                cond do
                  i < @flow_step -> "bg-gray-50 dark:bg-gray-800 opacity-100"
                  i == @flow_step -> "bg-rose-50 dark:bg-rose-900/20 border-2 border-rose-300 dark:border-rose-700 shadow-md"
                  true -> "bg-gray-50 dark:bg-gray-800 opacity-30"
                end
              ]}>
                <div class={["flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm",
                  cond do
                    i < @flow_step && step.status == :ok -> "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400"
                    i < @flow_step && step.status == :error -> "bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400"
                    true -> "bg-rose-100 dark:bg-rose-900/30 text-rose-600 dark:text-rose-400"
                  end
                ]}>
                  <%= if i < @flow_step && step.status == :ok do %>
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                  <% else %>
                    <%= if i < @flow_step && step.status == :error do %>
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    <% else %>
                      {i + 1}
                    <% end %>
                  <% end %>
                </div>

                <div class="flex-1 min-w-0">
                  <span class="text-xs font-semibold uppercase tracking-wide text-rose-600 dark:text-rose-400">{step.label}</span>
                  <div class="font-mono text-sm text-gray-900 dark:text-white">{step.code}</div>
                  <%= if i <= @flow_step do %>
                    <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">{step.detail}</div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Stateless vs Stateful</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          JWTs are <strong>stateless</strong> &mdash; the server verifies the signature without a database lookup.
          This is fast but means you cannot revoke individual tokens.
          For revocation, combine JWTs with a short expiry and a <strong>refresh token</strong> stored in the database.
        </p>
      </div>
    </div>
    """
  end

  defp signature_explanation do
    """
    HMAC-SHA256(
      base64UrlEncode(header) + "." + base64UrlEncode(payload),
      secret
    )

    # The signature is binary data (32 bytes for SHA256)
    # It's base64url-encoded for transmission
    # Cannot be decoded to readable text — it's a hash!\
    """
    |> String.trim()
  end

  defp flow_steps("generate") do
    [
      %{label: "Build Header", code: "header = %{\"alg\" => \"HS256\", \"typ\" => \"JWT\"}", detail: "Algorithm and token type", status: :ok},
      %{label: "Build Payload", code: "payload = %{\"sub\" => user.id, \"exp\" => now + 86400, ...}", detail: "Claims: subject, expiration, issued-at, issuer", status: :ok},
      %{label: "Encode", code: "header_b64 <> \".\" <> payload_b64", detail: "Base64url-encode both header and payload (no padding)", status: :ok},
      %{label: "Sign", code: ":crypto.mac(:hmac, :sha256, secret, signing_input)", detail: "HMAC-SHA256 of the encoded header.payload with secret key", status: :ok},
      %{label: "Assemble", code: "signing_input <> \".\" <> signature_b64", detail: "Final JWT: header.payload.signature — ready to send to client", status: :ok}
    ]
  end

  defp flow_steps("verify_valid") do
    [
      %{label: "Split", code: "String.split(token, \".\")", detail: "Split JWT into 3 parts: [header_b64, payload_b64, signature_b64]", status: :ok},
      %{label: "Verify Signature", code: ":crypto.hash_equals(expected, actual)", detail: "Recompute HMAC and compare — signatures match!", status: :ok},
      %{label: "Decode Payload", code: "Base.url_decode64(payload_b64)", detail: "Decode base64url payload to JSON, then parse", status: :ok},
      %{label: "Check Expiry", code: "System.system_time(:second) < exp", detail: "Token has not expired — still valid", status: :ok},
      %{label: "Result", code: "{:ok, claims}", detail: "Token verified! Claims extracted and returned.", status: :ok}
    ]
  end

  defp flow_steps("verify_expired") do
    [
      %{label: "Split", code: "String.split(token, \".\")", detail: "Split JWT into 3 parts", status: :ok},
      %{label: "Verify Signature", code: ":crypto.hash_equals(expected, actual)", detail: "Signature is valid (token was not tampered)", status: :ok},
      %{label: "Decode Payload", code: "Base.url_decode64(payload_b64)", detail: "Payload decoded successfully", status: :ok},
      %{label: "Check Expiry", code: "System.system_time(:second) < exp", detail: "FAILED: exp is in the past — token has expired!", status: :error},
      %{label: "Result", code: "{:error, :expired}", detail: "Token rejected. Client must refresh or re-authenticate.", status: :error}
    ]
  end

  defp flow_steps("verify_tampered") do
    [
      %{label: "Split", code: "String.split(token, \".\")", detail: "Split JWT into 3 parts", status: :ok},
      %{label: "Verify Signature", code: ":crypto.hash_equals(expected, actual)", detail: "FAILED: computed HMAC does not match the token's signature!", status: :error},
      %{label: "Result", code: "{:error, :invalid_token}", detail: "Token rejected. Someone modified the payload after signing.", status: :error}
    ]
  end

  def handle_event("select_part", %{"part" => part}, socket) do
    new_part = if socket.assigns.active_part == part, do: nil, else: part
    {:noreply, assign(socket, active_part: new_part)}
  end

  def handle_event("start_flow", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, verify_mode: mode, flow_step: 0)}
  end

  def handle_event("next_flow_step", _params, socket) do
    steps = flow_steps(socket.assigns.verify_mode)
    max = length(steps)
    new_step = min(socket.assigns.flow_step + 1, max)
    {:noreply, assign(socket, flow_step: new_step)}
  end

  def handle_event("reset_flow", _params, socket) do
    {:noreply, assign(socket, flow_step: 0)}
  end
end
