import { Outlet } from "react-router-dom";
import { useTheme } from "../contexts/ThemeContext";
import { ThemeToggle } from "./ThemeToggle";

function App() {
  const { theme } = useTheme()
  const isDOS = theme === 'dos-terminal'

  return (
    <div className={`min-h-screen ${isDOS ? 'bg-dos-black text-dos-green font-mono' : 'bg-white text-gray-900'}`}>
      <header className={`py-4 px-6 mb-8 ${isDOS ? 'bg-dos-black border-b-2 border-dos-green' : 'bg-red-600 text-white'}`}>
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <h1 className={`text-3xl font-bold ${isDOS ? 'text-dos-green font-mono' : 'text-white'}`}>
            {isDOS ? '> RECIPES.EXE' : '🍳 Recipes'}
          </h1>
          <div className="flex gap-3">
            <ThemeToggle />
          </div>
        </div>
      </header>
      <main className="max-w-7xl mx-auto px-6">
        <Outlet />
      </main>
    </div>
  )
}

export default App
