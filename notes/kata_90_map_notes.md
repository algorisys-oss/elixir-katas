# Kata 90: Mapbox Integration

## Goal
Integrate a complex map library (Mapbox GL JS or Leaflet).

## Core Concepts

### 1. Ignored Container
Like Chart.js, the map container (`<div id="map">`) must be `phx-update="ignore"`.

### 2. Client-side State
The map instance (`this.map`) lives in the Hook.

## Implementation Details

1.  **Hook**: `Mapbox`.
2.  **Markers**: Passed as data attributes or via `push_event`.

## Tips
- You need a valid API access token for Mapbox. Leaflet (OpenStreetMap) is free and requires no token.

## Challenge
**Fly To**. Add a list of cities (New York, London, Tokyo). Clicking one sends an event to the server, which `push_event("fly_to", {lat, lng})`. The Hook calls `map.flyTo(...)`.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("go_to_ny", _, socket) do
  {:noreply, push_event(socket, "fly_to", %{lat: 40.7128, lng: -74.0060})}
end
</code></pre>
</details>
