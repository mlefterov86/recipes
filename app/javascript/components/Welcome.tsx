import { Link } from 'react-router-dom'
import { useTheme } from '../contexts/ThemeContext'

function Welcome() {
  const { theme } = useTheme()
  const isDOS = theme === 'dos-terminal'

  return (
    <div className="py-12">
      <h2 className={`text-6xl font-bold mb-8 ${isDOS ? 'text-dos-green font-mono' : 'text-red-600'}`}>
        {isDOS ? 'C:\\RECIPES>' : 'Welcome!'}
      </h2>
      <p className={`text-lg mb-8 ${isDOS ? 'text-dos-green font-mono' : 'text-gray-700'}`}>
        {isDOS ? 'SYSTEM READY. RECIPES DATABASE LOADED.' : 'React frontend is running!'}
      </p>
      <Link
        to="/recipes"
        className={`inline-block px-6 py-3 font-semibold rounded-lg transition-colors ${
          isDOS
            ? 'bg-dos-black border-2 border-dos-green text-dos-green hover:bg-dos-green hover:text-dos-black font-mono'
            : 'bg-red-600 text-white hover:bg-red-700'
        }`}
      >
        {isDOS ? '[ENTER] BROWSE RECIPES' : 'Browse Recipes'}
      </Link>
    </div>
  )
}

export default Welcome
