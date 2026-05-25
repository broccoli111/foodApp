/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./components/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        cream: "#FFF8EE",
        oat: "#F5E9D7",
        sage: "#8DAA91",
        basil: "#3F6F4F",
        clay: "#D9875F",
        ink: "#23302A",
        muted: "#728079",
        card: "#FFFFFF"
      },
      borderRadius: {
        comfort: "24px"
      }
    }
  },
  plugins: []
};
