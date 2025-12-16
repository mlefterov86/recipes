/* eslint-disable react-refresh/only-export-components */
import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react'

export type Theme = 'modern' | 'dos-terminal'
export type ViewMode = 'card' | 'list'

interface ThemeContextType {
  theme: Theme
  viewMode: ViewMode
  toggleTheme: () => void
  toggleViewMode: () => void
  setTheme: (theme: Theme) => void
  setViewMode: (mode: ViewMode) => void
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined)

const THEME_STORAGE_KEY = 'theme-preference'
const VIEW_MODE_STORAGE_KEY = 'view-mode-preference'

interface ThemeProviderProps {
  children: ReactNode
}

export function ThemeProvider({ children }: ThemeProviderProps) {
  const [theme, setThemeState] = useState<Theme>(() => {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem(THEME_STORAGE_KEY)
      return (stored === 'dos-terminal' ? 'dos-terminal' : 'modern') as Theme
    }
    return 'modern'
  })

  const [viewMode, setViewModeState] = useState<ViewMode>(() => {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem(VIEW_MODE_STORAGE_KEY)
      return (stored === 'list' ? 'list' : 'card') as ViewMode
    }
    return 'card'
  })

  // Sync theme to localStorage and body class
  useEffect(() => {
    localStorage.setItem(THEME_STORAGE_KEY, theme)

    // Update body class for global CRT effects
    if (theme === 'dos-terminal') {
      document.body.classList.add('dos-terminal')
    } else {
      document.body.classList.remove('dos-terminal')
    }
  }, [theme])

  // Sync view mode to localStorage
  useEffect(() => {
    localStorage.setItem(VIEW_MODE_STORAGE_KEY, viewMode)
  }, [viewMode])

  // Sync across browser tabs
  useEffect(() => {
    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === THEME_STORAGE_KEY && e.newValue) {
        setThemeState(e.newValue as Theme)
      }
      if (e.key === VIEW_MODE_STORAGE_KEY && e.newValue) {
        setViewModeState(e.newValue as ViewMode)
      }
    }

    window.addEventListener('storage', handleStorageChange)
    return () => window.removeEventListener('storage', handleStorageChange)
  }, [])

  const toggleTheme = () => {
    setThemeState(prev => prev === 'modern' ? 'dos-terminal' : 'modern')
  }

  const toggleViewMode = () => {
    setViewModeState(prev => prev === 'card' ? 'list' : 'card')
  }

  const setTheme = (newTheme: Theme) => {
    setThemeState(newTheme)
  }

  const setViewMode = (newMode: ViewMode) => {
    setViewModeState(newMode)
  }

  const value: ThemeContextType = {
    theme,
    viewMode,
    toggleTheme,
    toggleViewMode,
    setTheme,
    setViewMode,
  }

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  )
}

export function useTheme() {
  const context = useContext(ThemeContext)
  if (context === undefined) {
    throw new Error('useTheme must be used within a ThemeProvider')
  }
  return context
}
