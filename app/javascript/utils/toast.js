// Client-side toast, mirroring shared/_flash and shared/_milestone_toast so
// optimistic actions (save/remove) can surface feedback without a round trip.
// Auto-dismisses via the dismiss controller (5s) and can be closed manually.
const TONES = {
  success: {
    bg: "bg-success",
    icon: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z",
  },
  danger: {
    bg: "bg-danger",
    icon: "M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
  },
  warning: {
    bg: "bg-warning",
    icon: "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z",
  },
}

export function showToast(message, { tone = "danger", dismissLabel = "Dismiss" } = {}) {
  const container = document.getElementById("flash-container")
  if (!container || !message) return
  const config = TONES[tone] || TONES.danger

  const wrapper = document.createElement("div")
  wrapper.className = "fixed top-16 right-4 z-40 max-w-sm"
  wrapper.innerHTML = `
    <div class="${config.bg} flex items-start gap-3 p-4 rounded-xl shadow-lg" role="alert" data-controller="dismiss">
      <div class="flex-shrink-0 mt-0.5">
        <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="${config.icon}"/>
        </svg>
      </div>
      <p class="text-sm font-medium text-white flex-1"></p>
      <button type="button" data-action="click->dismiss#hide" class="flex-shrink-0 text-white/70 hover:text-white transition" aria-label="${dismissLabel}">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
        </svg>
      </button>
    </div>`

  wrapper.querySelector("p").textContent = message
  container.appendChild(wrapper)
}