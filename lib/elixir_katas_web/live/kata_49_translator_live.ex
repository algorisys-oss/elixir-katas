defmodule ElixirKatasWeb.Kata49TranslatorLive do
  use ElixirKatasWeb, :live_component

  @translations %{
    "en" => %{
      "welcome" => "Welcome",
      "greeting" => "Hello, World!",
      "description" => "This is a simple internationalization demo.",
      "select_language" => "Select Language",
      "current_locale" => "Current Locale"
    },
    "es" => %{
      "welcome" => "Bienvenido",
      "greeting" => "¡Hola, Mundo!",
      "description" => "Esta es una demostración simple de internacionalización.",
      "select_language" => "Seleccionar Idioma",
      "current_locale" => "Configuración Regional Actual"
    },
    "fr" => %{
      "welcome" => "Bienvenue",
      "greeting" => "Bonjour, le Monde!",
      "description" => "Ceci est une démonstration simple d'internationalisation.",
      "select_language" => "Sélectionner la Langue",
      "current_locale" => "Locale Actuelle"
    },
    "de" => %{
      "welcome" => "Willkommen",
      "greeting" => "Hallo, Welt!",
      "description" => "Dies ist eine einfache Internationalisierungsdemo.",
      "select_language" => "Sprache Auswählen",
      "current_locale" => "Aktuelle Sprache"
    }
  }

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:locale, "en")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Switch languages to see translated content. In production, use Gettext.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <!-- Language Selector -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-700 mb-2">
              <%= t(@locale, "select_language") %>
            </label>
            <div class="flex gap-2">
              <button
                phx-click="set_locale" phx-target={@myself}
                phx-value-locale="en"
                class={"px-4 py-2 rounded text-sm font-medium " <> 
                       if(@locale == "en", do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")}
              >
                🇬🇧 English
              </button>
              <button
                phx-click="set_locale" phx-target={@myself}
                phx-value-locale="es"
                class={"px-4 py-2 rounded text-sm font-medium " <> 
                       if(@locale == "es", do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")}
              >
                🇪🇸 Español
              </button>
              <button
                phx-click="set_locale" phx-target={@myself}
                phx-value-locale="fr"
                class={"px-4 py-2 rounded text-sm font-medium " <> 
                       if(@locale == "fr", do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")}
              >
                🇫🇷 Français
              </button>
              <button
                phx-click="set_locale" phx-target={@myself}
                phx-value-locale="de"
                class={"px-4 py-2 rounded text-sm font-medium " <> 
                       if(@locale == "de", do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")}
              >
                🇩🇪 Deutsch
              </button>
            </div>
          </div>

          <!-- Translated Content -->
          <div class="space-y-4">
            <div class="p-4 bg-indigo-50 rounded">
              <h2 class="text-2xl font-bold text-indigo-900">
                <%= t(@locale, "welcome") %>
              </h2>
            </div>
            
            <div class="p-4 bg-gray-50 rounded">
              <p class="text-lg text-gray-800">
                <%= t(@locale, "greeting") %>
              </p>
            </div>
            
            <div class="p-4 bg-gray-50 rounded">
              <p class="text-sm text-gray-600">
                <%= t(@locale, "description") %>
              </p>
            </div>
            
            <div class="p-3 bg-blue-50 border border-blue-200 rounded">
              <div class="text-xs text-blue-600 font-medium">
                <%= t(@locale, "current_locale") %>: <span class="font-mono"><%= @locale %></span>
              </div>
            </div>
          </div>
        </div>
      </div>
    
    """
  end

  defp t(locale, key) do
    get_in(@translations, [locale, key]) || key
  end

  def handle_event("set_locale", %{"locale" => locale}, socket) do
    {:noreply, assign(socket, locale: locale)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
