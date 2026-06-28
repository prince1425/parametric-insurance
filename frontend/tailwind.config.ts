import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  darkMode: ["class"],
  theme: {
    extend: {
      colors: {
        ink: "#17211f",
        field: "#2f7d5d",
        monsoon: "#2f6f9f",
        saffron: "#b4652a",
        alert: "#b23b3b",
        paper: "#f7f8f5",
      },
      boxShadow: {
        panel: "0 10px 30px rgba(23, 33, 31, 0.08)",
      },
      borderRadius: {
        enterprise: "8px",
      },
    },
  },
  plugins: [],
};

export default config;
