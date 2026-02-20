/**
 * CursorTracker Hook
 * 
 * Tracks mouse movement and broadcasts cursor position to other connected users.
 * Throttles events to avoid overwhelming the server.
 */
export const CursorTracker = {
    mounted() {
        this.throttleMs = 50 // Throttle to max 20 updates per second
        this.lastSent = 0

        this.handleMouseMove = (e) => {
            const now = Date.now()

            // Throttle the events
            if (now - this.lastSent < this.throttleMs) {
                return
            }

            this.lastSent = now

            // Get coordinates relative to the element
            const rect = this.el.getBoundingClientRect()
            const x = e.clientX - rect.left
            const y = e.clientY - rect.top

            // Push event to the LiveComponent
            this.pushEvent('cursor-move', { x: Math.round(x), y: Math.round(y) })
        }

        this.el.addEventListener('mousemove', this.handleMouseMove)
    },

    destroyed() {
        if (this.handleMouseMove) {
            this.el.removeEventListener('mousemove', this.handleMouseMove)
        }
    }
}
