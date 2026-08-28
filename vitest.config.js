import { defineConfig } from "vitest/config"
import path from "node:path"

export default defineConfig({
  resolve: {
    alias: {
      // Mirrors config/importmap.rb's `pin_all_from "app/javascript/utils"`.
      utils: path.resolve(__dirname, "app/javascript/utils"),
    },
  },
  test: {
    environment: "jsdom",
    include: ["spec/javascript/**/*.test.js"],
    restoreMocks: true,
    clearMocks: true,
  },
})