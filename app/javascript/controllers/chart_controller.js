import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

const THEME_COLORS = [
  "#f97316", // crusta/orange
  "#06b6d4", // bright-turquoise/cyan
  "#a78bfa", // prelude/purple
  "#34d399", // emerald
  "#f472b6", // pink
  "#facc15", // yellow
  "#60a5fa", // blue
  "#fb923c", // light orange
  "#2dd4bf", // teal
  "#c084fc", // violet
]

export default class extends Controller {
  static values = {
    type: String,
    labels: Array,
    data: Array,
    label: { type: String, default: "Count" },
  }

  connect() {
    this.chart = new Chart(this.element, this.chartConfig())
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  chartConfig() {
    const isDoughnut = this.typeValue === "doughnut"

    return {
      type: this.typeValue,
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            label: this.labelValue,
            data: this.dataValue,
            backgroundColor: isDoughnut
              ? THEME_COLORS.slice(0, this.dataValue.length)
              : THEME_COLORS[0],
            borderColor: isDoughnut ? "#1a1a1f" : THEME_COLORS[0],
            borderWidth: isDoughnut ? 2 : 0,
            borderRadius: isDoughnut ? 0 : 4,
          },
        ],
      },
      options: this.chartOptions(isDoughnut),
    }
  }

  chartOptions(isDoughnut) {
    const fontFamily = "'JetBrains Mono', monospace"
    const textColor = "#a1a1aa" // woodsmoke-400

    const base = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: isDoughnut,
          position: "bottom",
          labels: {
            color: textColor,
            font: { family: fontFamily, size: 11 },
            padding: 12,
            usePointStyle: true,
            pointStyleWidth: 8,
          },
        },
        tooltip: {
          titleFont: { family: fontFamily },
          bodyFont: { family: fontFamily },
        },
      },
    }

    if (!isDoughnut) {
      base.scales = {
        x: {
          ticks: { color: textColor, font: { family: fontFamily, size: 10 }, maxRotation: 45 },
          grid: { color: "#27272a" },
        },
        y: {
          ticks: { color: textColor, font: { family: fontFamily, size: 10 }, precision: 0 },
          grid: { color: "#27272a" },
          beginAtZero: true,
        },
      }
      base.indexAxis = "x"
    }

    return base
  }
}
