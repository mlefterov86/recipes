/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./app/javascript/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'dos': {
          'black': '#000000',
          'green': '#00ff00',
          'green-dim': '#00cc00',
          'green-dark': '#008800',
        },
      },
      fontFamily: {
        'mono': ['Courier New', 'Courier', 'monospace'],
        'dos': ['"Perfect DOS VGA 437"', 'Courier New', 'Courier', 'monospace'],
      },
      animation: {
        'scanline': 'scanline 8s linear infinite',
        'flicker': 'flicker 0.15s infinite',
        'cursor-blink': 'cursor-blink 1s step-end infinite',
      },
      keyframes: {
        scanline: {
          '0%': { transform: 'translateY(-100%)' },
          '100%': { transform: 'translateY(100%)' },
        },
        flicker: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.96' },
        },
        'cursor-blink': {
          '0%, 50%': { opacity: '1' },
          '51%, 100%': { opacity: '0' },
        },
      },
      boxShadow: {
        'dos-glow': '0 0 10px rgba(0, 255, 0, 0.5), 0 0 20px rgba(0, 255, 0, 0.3)',
        'dos-text': '0 0 5px rgba(0, 255, 0, 0.8)',
      },
    },
  },
  plugins: [
    // Custom plugin for text-shadow utility
    function({ addUtilities }) {
      addUtilities({
        '.text-shadow-dos': {
          textShadow: '0 0 5px rgba(0, 255, 0, 0.8), 0 0 10px rgba(0, 255, 0, 0.4)',
        },
      })
    },
  ],
}
