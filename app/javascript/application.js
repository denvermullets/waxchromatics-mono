// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@rails/actioncable"
import "controllers"

// Auto-scroll trade messages container on page load
document.addEventListener("turbo:load", () => {
  const container = document.getElementById("trade_messages")
  if (container) container.scrollTop = container.scrollHeight
})

// Auto-scroll after a new message is appended via Turbo Stream
document.addEventListener("turbo:before-stream-render", (event) => {
  const stream = event.target
  if (stream.action === "append" && stream.target === "trade_messages") {
    const originalRender = event.detail.render
    event.detail.render = (streamElement) => {
      originalRender(streamElement)
      const container = document.getElementById("trade_messages")
      if (container) container.scrollTop = container.scrollHeight
    }
  }
})

// Clear message input after successful send
document.addEventListener("turbo:submit-end", (event) => {
  if (event.target.id === "new_trade_message" && event.detail.success) {
    event.target.reset()
  }
})
