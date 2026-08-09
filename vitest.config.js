import { defineConfig } from "vitest/config"

export default defineConfig({
  test: {
    environment: "jsdom",
    include: ["spec/javascript/**/*.test.js"],
    restoreMocks: true,
    clearMocks: true,
  },
})
