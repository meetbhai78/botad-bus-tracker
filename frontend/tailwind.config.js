/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        botad: {
          green: '#0d9488',
          dark: '#0f172a',
        },
      },
    },
  },
  plugins: [],
};
