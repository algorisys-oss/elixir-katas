/**
 * InfiniteScroll Hook
 * 
 * Automatically loads more items when the user scrolls near the bottom.
 * Uses IntersectionObserver for efficient scroll detection.
 */
export const InfiniteScroll = {
    mounted() {
        this.pending = false

        // Create a sentinel element at the bottom
        const sentinel = this.el.querySelector('[data-infinite-scroll-sentinel]')

        if (!sentinel) {
            console.warn('InfiniteScroll: No sentinel element found. Add data-infinite-scroll-sentinel to an element.')
            return
        }

        // Create an IntersectionObserver to watch the sentinel
        this.observer = new IntersectionObserver(
            entries => {
                const entry = entries[0]

                // If sentinel is visible and we're not already loading
                if (entry.isIntersecting && !this.pending) {
                    this.pending = true

                    // Push event to server to load more items
                    this.pushEvent('load-more', {}, (reply, ref) => {
                        this.pending = false
                    })
                }
            },
            {
                root: null, // viewport
                rootMargin: '100px', // Start loading 100px before reaching the sentinel
                threshold: 0.1
            }
        )

        this.observer.observe(sentinel)
    },

    destroyed() {
        if (this.observer) {
            this.observer.disconnect()
        }
    }
}
