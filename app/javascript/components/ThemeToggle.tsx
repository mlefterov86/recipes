import React from 'react'
import { useTheme } from '../contexts/ThemeContext'

export function ThemeToggle() {
  const { theme, toggleTheme } = useTheme()
  const isDOS = theme === 'dos-terminal'

  return (
    <button
      onClick={toggleTheme}
      className={`
        px-4 py-2 rounded font-medium transition-all
        ${isDOS
          ? 'bg-dos-black border-2 border-dos-green text-dos-green hover:bg-dos-green-dark hover:text-dos-black'
          : 'bg-white text-red-600 border-2 border-red-600 hover:bg-red-600 hover:text-white'
        }
      `}
      aria-label={`Switch to ${isDOS ? 'modern' : 'DOS terminal'} theme`}
    >
      {isDOS ? '🎨 Modern Mode' : '💻 DOS Mode'}
    </button>
  )
}
