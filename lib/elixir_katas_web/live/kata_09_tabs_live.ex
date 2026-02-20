defmodule ElixirKatasWeb.Kata09TabsLive do
  use ElixirKatasWeb, :live_component


  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, 
     socket
     |> assign(active_tab: "notes")
     |> assign(selected_tab: :home)
     
     }
  end

  def render(assigns) do
    ~H"""
    
      <div class="flex flex-col h-full text-gray-900 dark:text-gray-100 p-4">
        <div class="max-w-4xl mx-auto w-full">
          
          <div class="bg-gray-50 dark:bg-gray-800 rounded-lg shadow-lg overflow-hidden border border-gray-200 dark:border-gray-700">
            <!-- Tab Navigation -->
            <div class="flex border-b border-gray-200 dark:border-gray-700 bg-gray-100 dark:bg-gray-900">
              <button
                phx-click="set_tab" phx-target={@myself}
                phx-value-tab="home"
                class={"flex-1 px-6 py-4 font-medium transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-inset #{if @selected_tab == :home, do: "bg-white dark:bg-gray-800 text-primary border-t-2 border-primary", else: "text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"}"}
              >
                Home
              </button>
              <button
                phx-click="set_tab" phx-target={@myself}
                phx-value-tab="pricing"
                class={"flex-1 px-6 py-4 font-medium transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-inset #{if @selected_tab == :pricing, do: "bg-white dark:bg-gray-800 text-primary border-t-2 border-primary", else: "text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"}"}
              >
                Pricing
              </button>
              <button
                phx-click="set_tab" phx-target={@myself}
                phx-value-tab="about"
                class={"flex-1 px-6 py-4 font-medium transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-inset #{if @selected_tab == :about, do: "bg-white dark:bg-gray-800 text-primary border-t-2 border-primary", else: "text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"}"}
              >
                About
              </button>
            </div>

            <!-- Tab Content -->
            <div class="p-8 min-h-[300px]">
              <%= case @selected_tab do %>
                <% :home -> %>
                  <div class="animate-fade-in">
                    <h2 class="text-2xl font-bold mb-4">Welcome Home</h2>
                    <p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
                      This is the main dashboard of your application.
                      Notice how the content switches instantly without a page reload.
                      LiveView handles the state change on the server and pushes just the diff to the client.
                    </p>
                    <div class="mt-6 p-4 bg-blue-50 dark:bg-blue-900/20 text-blue-800 dark:text-blue-200 rounded-md border border-blue-100 dark:border-blue-800">
                      <p>Current State: <code class="bg-blue-100 dark:bg-blue-900 px-1 py-0.5 rounded text-sm">@selected_tab = :home</code></p>
                    </div>
                  </div>

                <% :pricing -> %>
                  <div class="animate-fade-in">
                    <h2 class="text-2xl font-bold mb-6">Pricing Plans</h2>
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                      <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-4 text-center">
                        <h3 class="font-bold text-lg mb-2">Basic</h3>
                        <p class="text-3xl font-bold mb-4">$0<span class="text-sm font-normal text-gray-500">/mo</span></p>
                        <button class="w-full py-2 bg-gray-200 dark:bg-gray-700 rounded hover:bg-gray-300 dark:hover:bg-gray-600 transition">Select</button>
                      </div>
                      <div class="border-2 border-primary rounded-lg p-4 text-center transform scale-105 shadow-md bg-white dark:bg-gray-800 relative">
                        <div class="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-1/2 bg-primary text-white text-xs px-2 py-1 rounded">Popular</div>
                        <h3 class="font-bold text-lg mb-2">Pro</h3>
                        <p class="text-3xl font-bold mb-4">$19<span class="text-sm font-normal text-gray-500">/mo</span></p>
                        <button class="w-full py-2 bg-primary text-white rounded hover:bg-primary-dark transition">Select</button>
                      </div>
                      <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-4 text-center">
                        <h3 class="font-bold text-lg mb-2">Enterprise</h3>
                        <p class="text-3xl font-bold mb-4">$99<span class="text-sm font-normal text-gray-500">/mo</span></p>
                        <button class="w-full py-2 bg-gray-200 dark:bg-gray-700 rounded hover:bg-gray-300 dark:hover:bg-gray-600 transition">Select</button>
                      </div>
                    </div>
                  </div>

                <% :about -> %>
                  <div class="animate-fade-in">
                    <h2 class="text-2xl font-bold mb-4">About Us</h2>
                    <p class="text-gray-600 dark:text-gray-300 leading-relaxed">
                      We are building the future of interactive web applications using pure Elixir.
                      No complex JavaScript frameworks required for this interaction!
                    </p>
                    <ul class="mt-4 list-disc ml-6 space-y-2 text-gray-600 dark:text-gray-300">
                      <li>Server-side state management</li>
                      <li>Fast development cycles</li>
                      <li>Scalable architecture</li>
                    </ul>
                  </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    if tab in ["interactive", "source", "notes"] do
       {:noreply, assign(socket, active_tab: tab)}
    else 
       {:noreply, assign(socket, selected_tab: String.to_existing_atom(tab))}
    end
  end
end
