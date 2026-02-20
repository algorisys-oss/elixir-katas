import Chart from "../../vendor/chart.js"

export const ChartJS = {
    mounted() {
        const ctx = this.el.getContext('2d');
        const data = JSON.parse(this.el.dataset.chartData || '{}');

        this.chart = new Chart(ctx, {
            type: 'bar', // Default, can be dynamic
            data: data,
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'top',
                    },
                    title: {
                        display: true,
                        text: 'LiveView Chart.js Integration'
                    }
                },
                animation: {
                    duration: 500
                }
            }
        });

        this.handleEvent("update-chart", (newData) => {
            this.chart.data = newData;
            this.chart.update();
        });
    },

    updated() {
        const data = JSON.parse(this.el.dataset.chartData || '{}');
        this.chart.data = data;
        this.chart.update();
    },

    destroyed() {
        if (this.chart) {
            this.chart.destroy();
        }
    }
}
