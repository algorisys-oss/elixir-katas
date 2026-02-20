defmodule ElixirKatasWeb.Kata15CalculatorLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, 
     socket
     |> assign(active_tab: "notes")
     
     
     |> assign(display: "0")
     |> assign(acc: nil)
     |> assign(op: nil)
     |> assign(new_entry: true)}
  end

  def render(assigns) do
    ~H"""
    
      <div class="flex items-center justify-center p-8 h-full">
        <div class="w-72 bg-gray-900 rounded-2xl p-4 shadow-2xl">
          <!-- Display -->
          <div class="bg-gray-800 rounded-xl p-4 mb-4 text-right overflow-hidden">
            <div class="text-gray-400 text-sm h-6">
              <%= if @acc, do: "#{format_number(@acc)} #{@op}", else: "" %>
            </div>
            <div class="text-white text-4xl font-mono tracking-widest truncate">
              {@display}
            </div>
          </div>

          <!-- Keypad -->
          <div class="grid grid-cols-4 gap-3">
             <!-- Row 1 -->
             <button phx-click="clear" phx-target={@myself} class="btn btn-warning w-full">C</button>
             <button phx-click="op" phx-target={@myself} phx-value-op="/" class="btn btn-secondary w-full">÷</button>
             <button phx-click="op" phx-target={@myself} phx-value-op="*" class="btn btn-secondary w-full">×</button>
             <button phx-click="backspace" phx-target={@myself} class="btn btn-ghost w-full">⌫</button>

             <!-- Row 2 -->
             <button phx-click="num" phx-target={@myself} phx-value-n="7" class="btn btn-neutral w-full text-xl">7</button>
             <button phx-click="num" phx-target={@myself} phx-value-n="8" class="btn btn-neutral w-full text-xl">8</button>
             <button phx-click="num" phx-target={@myself} phx-value-n="9" class="btn btn-neutral w-full text-xl">9</button>
             <button phx-click="op" phx-target={@myself} phx-value-op="-" class="btn btn-secondary w-full text-xl">-</button>

             <!-- Row 3 -->
             <button phx-click="num" phx-target={@myself} phx-value-n="4" class="btn btn-neutral w-full text-xl">4</button>
             <button phx-click="num" phx-target={@myself} phx-value-n="5" class="btn btn-neutral w-full text-xl">5</button>
             <button phx-click="num" phx-target={@myself} phx-value-n="6" class="btn btn-neutral w-full text-xl">6</button>
             <button phx-click="op" phx-target={@myself} phx-value-op="+" class="btn btn-secondary w-full text-xl">+</button>

             <!-- Row 4 -->
             <button phx-click="num" phx-target={@myself} phx-value-n="1" class="btn btn-neutral w-full text-xl">1</button>
             <button phx-click="num" phx-target={@myself} phx-value-n="2" class="btn btn-neutral w-full text-xl">2</button>
             <button phx-click="num" phx-target={@myself} phx-value-n="3" class="btn btn-neutral w-full text-xl">3</button>
             <button phx-click="eval" phx-target={@myself} class="btn btn-primary w-full text-xl row-span-2">=</button>

             <!-- Row 5 -->
             <button phx-click="num" phx-target={@myself} phx-value-n="0" class="btn btn-neutral w-full text-xl col-span-2">0</button>
             <button phx-click="dot" phx-target={@myself} class="btn btn-neutral w-full text-xl">.</button>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("num", %{"n" => n}, socket) do
    new_display =
      if socket.assigns.new_entry do
        n
      else
        if socket.assigns.display == "0", do: n, else: socket.assigns.display <> n
      end
    
    {:noreply, assign(socket, display: new_display, new_entry: false)}
  end

  def handle_event("dot", _, socket) do
    new_display = 
      if String.contains?(socket.assigns.display, "."), do: socket.assigns.display, else: socket.assigns.display <> "."
    {:noreply, assign(socket, display: new_display, new_entry: false)}
  end

  def handle_event("clear", _, socket) do
    {:noreply, assign(socket, display: "0", acc: nil, op: nil, new_entry: true)}
  end
  
  def handle_event("backspace", _, socket) do
    display = socket.assigns.display
    new_display = if String.length(display) > 1, do: String.slice(display, 0..-2//1), else: "0"
    {:noreply, assign(socket, display: new_display)}
  end

  def handle_event("op", %{"op" => op}, socket) do
    current = parse(socket.assigns.display)
    
    if socket.assigns.acc && !socket.assigns.new_entry do
       res = calculate(socket.assigns.acc, socket.assigns.op, current)
       {:noreply, assign(socket, display: format_number(res), acc: res, op: op, new_entry: true)}
    else
       {:noreply, assign(socket, acc: current, op: op, new_entry: true)}
    end
  end

  def handle_event("eval", _, socket) do
    if socket.assigns.op do
      current = parse(socket.assigns.display)
      res = calculate(socket.assigns.acc, socket.assigns.op, current)
      {:noreply, assign(socket, display: format_number(res), acc: nil, op: nil, new_entry: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    if tab in ["interactive", "source", "notes"] do
       {:noreply, assign(socket, active_tab: tab)}
    else 
       {:noreply, socket}
    end
  end


  defp parse(s) do 
     case Integer.parse(s) do
       {i, ""} -> i / 1
       _ -> case Float.parse(s) do
          {f, _} -> f
          :error -> 0.0
       end
     end
  end

  defp calculate(a, "+", b), do: a + b
  defp calculate(a, "-", b), do: a - b
  defp calculate(a, "*", b), do: a * b
  defp calculate(a, "/", b), do: (if b == 0, do: 0.0, else: a / b)
  defp calculate(_, _, b), do: b

  defp format_number(n) do
    if n == trunc(n), do: "#{trunc(n)}", else: "#{n}"
  end
end
