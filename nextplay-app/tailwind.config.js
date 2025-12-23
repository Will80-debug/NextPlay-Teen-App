/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'gold': {
          50: '#fefce8',
          100: '#fef9c3',
          200: '#fef08a',
          300: '#fde047',
          400: '#facc15',
          500: '#eab308',
          600: '#ca8a04',
          700: '#a16207',
          800: '#854d0e',
          900: '#713f12',
        },
        'bronze': {
          50: '#faf5f0',
          100: '#f4e9dc',
          200: '#e8d0b8',
          300: '#dab38f',
          400: '#cd9668',
          500: '#b87333',
          600: '#a85f2b',
          700: '#8b4e24',
          800: '#6f3f1e',
          900: '#5a3318',
        },
      },
      backgroundImage: {
        'cosmic': 'radial-gradient(ellipse at center, #1a1a1a 0%, #000000 100%)',
      },
    },
  },
  plugins: [],
}
