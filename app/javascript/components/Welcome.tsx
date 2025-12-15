import { Link } from 'react-router-dom'

function Welcome() {
  return (
    <div className="py-12">
      <h2 className="text-6xl font-bold text-red-600 mb-8">
        Welcome!
      </h2>
      <p className="text-gray-700 text-lg mb-8">React frontend is running!</p>
      <Link
        to="/recipes"
        className="inline-block px-6 py-3 bg-red-600 text-white font-semibold rounded-lg hover:bg-red-700 transition-colors"
      >
        Browse Recipes
      </Link>
    </div>
  )
}

export default Welcome
