export const InputMask = {
    mounted() {
        this.mask = this.el.dataset.mask;
        this.el.addEventListener("input", this.handleInput.bind(this));
    },

    handleInput(e) {
        const value = e.target.value.replace(/\D/g, "");
        let formatted = "";

        if (this.mask === "phone") {
            // (123) 456-7890
            if (value.length > 0) formatted += "(" + value.substring(0, 3);
            if (value.length > 3) formatted += ") " + value.substring(3, 6);
            if (value.length > 6) formatted += "-" + value.substring(6, 10);
        } else if (this.mask === "credit-card") {
            // 1234 5678 1234 5678
            for (let i = 0; i < value.length && i < 16; i += 4) {
                if (i > 0) formatted += " ";
                formatted += value.substring(i, i + 4);
            }
        } else if (this.mask === "date") {
            // MM/DD/YYYY
            if (value.length > 0) formatted += value.substring(0, 2);
            if (value.length > 2) formatted += "/" + value.substring(2, 4);
            if (value.length > 4) formatted += "/" + value.substring(4, 8);
        } else {
            formatted = value;
        }

        this.el.value = formatted;
        // Trigger LiveView update explicitly if needed, but "input" does it naturally
    }
}
