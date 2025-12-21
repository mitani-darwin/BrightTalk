module.exports = {
  content: [
    "./app/views/**/*.erb",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/frontend/**/*.{js,css}"
  ],
  corePlugins: {
    preflight: false
  },
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#edf5ff",
          100: "#d7e7ff",
          200: "#b2ceff",
          300: "#7fabff",
          400: "#4a82ff",
          500: "#2563eb",
          600: "#1d4ed8",
          700: "#1e3a8a",
          800: "#172554",
          900: "#0b1433"
        }
      },
      boxShadow: {
        card: "0 10px 30px rgba(15, 23, 42, 0.12)",
        soft: "0 8px 20px rgba(15, 23, 42, 0.08)"
      }
    }
  },
  plugins: []
};
