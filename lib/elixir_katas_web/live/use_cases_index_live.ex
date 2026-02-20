defmodule ElixirKatasWeb.UseCasesIndexLive do
  use ElixirKatasWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Use Cases")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-indigo-50 via-white to-purple-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <!-- Header -->
        <div class="mb-12">
          <.link navigate="/" class="inline-flex items-center text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 mb-6">
            <.icon name="hero-arrow-left" class="w-5 h-5 mr-2" />
            Back to Home
          </.link>
          <h1 class="text-4xl md:text-5xl font-extrabold text-gray-900 dark:text-white mb-4">
            Real-World Use Cases
          </h1>
          <p class="text-xl text-gray-600 dark:text-gray-300 max-w-3xl">
            Build complete applications with authentication, database integration, and production-ready patterns
          </p>
        </div>

        <!-- Use Cases Grid -->
        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          <!-- Tasky Card -->
          <.link navigate="/usecases/tasky" class="group relative bg-white dark:bg-gray-800 rounded-2xl shadow-lg hover:shadow-2xl transition-all duration-300 overflow-hidden border border-gray-200 dark:border-gray-700 hover:scale-105">
            <div class="absolute inset-0 bg-gradient-to-br from-purple-500/10 to-indigo-500/10 opacity-0 group-hover:opacity-100 transition-opacity"></div>
            <div class="relative p-6">
              <!-- Icon -->
              <div class="w-14 h-14 bg-gradient-to-br from-purple-500 to-indigo-600 rounded-xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"></path>
                </svg>
              </div>
              
              <!-- Content -->
              <h3 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">Tasky</h3>
              <p class="text-gray-600 dark:text-gray-300 mb-4 text-sm">
                A full-featured todo application with authentication, pagination, search, and favorites
              </p>
              
              <!-- Features -->
              <div class="space-y-2 mb-4">
                <div class="flex items-center text-sm text-gray-500 dark:text-gray-400">
                  <.icon name="hero-check-circle-mini" class="w-4 h-4 mr-2 text-green-500" />
                  User Authentication
                </div>
                <div class="flex items-center text-sm text-gray-500 dark:text-gray-400">
                  <.icon name="hero-check-circle-mini" class="w-4 h-4 mr-2 text-green-500" />
                  CRUD Operations
                </div>
                <div class="flex items-center text-sm text-gray-500 dark:text-gray-400">
                  <.icon name="hero-check-circle-mini" class="w-4 h-4 mr-2 text-green-500" />
                  Search & Pagination
                </div>
              </div>
              
              <!-- CTA -->
              <div class="flex items-center text-purple-600 dark:text-purple-400 font-semibold group-hover:translate-x-2 transition-transform">
                Open App
                <svg class="w-4 h-4 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6"></path>
                </svg>
              </div>
            </div>
          </.link>

          <!-- Placeholder for future use cases -->
          <div class="relative bg-gray-50 dark:bg-gray-800/50 rounded-2xl border-2 border-dashed border-gray-300 dark:border-gray-700 p-6 flex flex-col items-center justify-center min-h-[300px]">
            <div class="w-14 h-14 bg-gray-200 dark:bg-gray-700 rounded-xl flex items-center justify-center mb-4">
              <svg class="w-7 h-7 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
              </svg>
            </div>
            <h3 class="text-lg font-semibold text-gray-500 dark:text-gray-400 mb-2">More Coming Soon</h3>
            <p class="text-sm text-gray-400 dark:text-gray-500 text-center">
              Additional use cases will be added here
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
