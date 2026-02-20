// VirtualScroll Hook for efficient rendering of large lists
export const VirtualScroll = {
  mounted() {
    this.container = this.el
    this.itemHeight = parseInt(this.el.dataset.itemHeight) || 80
    this.ticking = false
    this.lastSentScrollTop = 0
    this.threshold = 400 // Trigger update every 400px (5 items)
    this.lastScrollTop = 0 // Keep this for updated()

    this.handleScroll = () => {
      if (!this.ticking) {
        window.requestAnimationFrame(() => {
          const scrollTop = this.container.scrollTop
          const delta = Math.abs(scrollTop - this.lastSentScrollTop)

          if (delta >= this.threshold || scrollTop === 0 ||
            scrollTop >= (this.container.scrollHeight - this.container.clientHeight)) {

            this.pushEvent("scroll", {
              scrollTop: scrollTop.toString()
            })
            this.lastSentScrollTop = scrollTop
          }

          this.lastScrollTop = scrollTop
          this.ticking = false
        })
        this.ticking = true
      }
    }

    this.container.addEventListener('scroll', this.handleScroll)
  },

  updated() {
    // Preserve scroll position after LiveView update
    if (this.lastScrollTop && this.container) {
      this.container.scrollTop = this.lastScrollTop
    }
  },

  destroyed() {
    if (this.container) {
      this.container.removeEventListener('scroll', this.handleScroll)
    }
    if (this.throttleTimeout) {
      clearTimeout(this.throttleTimeout)
    }
  }
}
