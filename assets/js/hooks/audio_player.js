export const AudioPlayer = {
    mounted() {
        this.audio = this.el.querySelector('audio');

        // Server -> Client Events
        this.handleEvent("play", () => this.audio.play());
        this.handleEvent("pause", () => this.audio.pause());

        // Client -> Server Events (Progress)
        this.audio.addEventListener("timeupdate", () => {
            // Throttle updates or just let LiveView handle them if debounce needed
            // For this demo, we might update UI client-side for smoothness 
            // but if we want server to know current time:
            // this.pushEvent("time_update", { time: this.audio.currentTime })

            // Better: Update local progress bar directly for smoothness without roundtrip
            const progress = (this.audio.currentTime / this.audio.duration) * 100;
            const progressBar = this.el.querySelector('.progress-bar');
            if (progressBar) progressBar.style.width = `${progress}%`;

            const timeDisplay = this.el.querySelector('.time-display');
            if (timeDisplay) timeDisplay.textContent = this.formatTime(this.audio.currentTime);
        });

        this.audio.addEventListener("loadedmetadata", () => {
            const durationDisplay = this.el.querySelector('.duration-display');
            if (durationDisplay) durationDisplay.textContent = this.formatTime(this.audio.duration);
        });

        this.audio.addEventListener("ended", () => {
            this.pushEvent("audio_ended", {});
        });
    },

    formatTime(seconds) {
        if (!seconds) return "0:00";
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return `${m}:${s.toString().padStart(2, '0')}`;
    }
}
