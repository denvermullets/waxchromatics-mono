import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

const crosshairPlugin = {
  id: "crosshair",
  afterDraw(chart) {
    const tooltip = chart.tooltip
    if (!tooltip || !tooltip.getActiveElements().length) return

    const x = tooltip.getActiveElements()[0].element.x
    const yAxis = chart.scales.y
    const ctx = chart.ctx

    ctx.save()
    ctx.beginPath()
    ctx.moveTo(x, yAxis.top)
    ctx.lineTo(x, yAxis.bottom)
    ctx.lineWidth = 1
    ctx.strokeStyle = "rgba(161, 161, 170, 0.3)"
    ctx.stroke()
    ctx.restore()
  },
}

Chart.register(crosshairPlugin)

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
    datasets: { type: Array, default: [] },
    hideLegend: { type: Boolean, default: false },
    timeRange: { type: String, default: "" },
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

  toggle({ params: { index } }) {
    const visible = this.chart.isDatasetVisible(index)
    this.chart.setDatasetVisibility(index, !visible)
    this.chart.update()
    this.dispatch("toggled", { detail: { index, visible: !visible } })
  }

  formatTimeLabels(labels) {
    if (!this.timeRangeValue) return labels

    const range = this.timeRangeValue
    return labels.map((iso) => {
      const d = new Date(iso)
      if (range === "1h") {
        return d.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })
      } else if (range === "24h") {
        return d.toLocaleTimeString([], { hour: "numeric" })
      } else {
        return d.toLocaleDateString([], { month: "numeric", day: "numeric" })
      }
    })
  }

  chartConfig() {
    const isDoughnut = this.typeValue === "doughnut"
    const hasMultiDatasets = this.datasetsValue.length > 0

    return {
      type: this.typeValue,
      data: {
        labels: this.formatTimeLabels(this.labelsValue),
        datasets: hasMultiDatasets
          ? this.datasetsValue.map((ds, i) => ({
              label: ds.label,
              data: ds.data,
              borderColor: ds.color || THEME_COLORS[i],
              backgroundColor: ds.color || THEME_COLORS[i],
              borderDash: ds.dashed ? [5, 4] : [],
              fill: false,
              tension: 0.3,
              pointRadius: 0,
              pointHoverRadius: 4,
            }))
          : [
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
      options: this.chartOptions(isDoughnut, hasMultiDatasets),
    }
  }

  chartOptions(isDoughnut, hasMultiDatasets = false) {
    const fontFamily = "'JetBrains Mono', monospace"
    const textColor = "#a1a1aa" // woodsmoke-400

    const base = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: !this.hideLegendValue && (isDoughnut || hasMultiDatasets),
          position: "bottom",
          labels: {
            color: textColor,
            font: { family: fontFamily, size: 11 },
            padding: 12,
            usePointStyle: true,
            pointStyle: "rectRounded",
            pointStyleWidth: 12,
          },
        },
        tooltip: {
          mode: "index",
          intersect: false,
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
