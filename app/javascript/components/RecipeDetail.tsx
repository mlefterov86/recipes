import { useState, useEffect } from 'react'
import { useParams, Link, useNavigate } from 'react-router-dom'
import { useTheme } from '../contexts/ThemeContext'
import type { RecipeDetail as RecipeDetailType, RecipeDetailResponse } from '../types'

function RecipeDetail() {
  const { theme } = useTheme()
  const isDOS = theme === 'dos-terminal'
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [recipe, setRecipe] = useState<RecipeDetailType | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchRecipe = async () => {
      setLoading(true)
      setError(null)

      try {
        const response = await fetch(`/api/v1/recipes/${id}`)

        if (response.status === 404) {
          setError('Recipe not found')
          return
        }

        if (!response.ok) {
          throw new Error('Failed to fetch recipe')
        }

        const data: RecipeDetailResponse = await response.json()
        setRecipe(data.data || null)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An error occurred')
      } finally {
        setLoading(false)
      }
    }

    fetchRecipe()
  }, [id])

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center py-12">
          <div className={`inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid ${isDOS ? 'border-dos-green border-r-transparent' : 'border-red-600 border-r-transparent'}`}></div>
          <p className={`mt-4 ${isDOS ? 'text-dos-green font-mono' : 'text-gray-600'}`}>
            {isDOS ? 'LOADING RECIPE.DAT...' : 'Loading recipe...'}
          </p>
        </div>
      </div>
    )
  }

  if (error || !recipe) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className={`rounded-lg p-6 ${isDOS ? 'bg-dos-black border-2 border-dos-green text-dos-green font-mono' : 'bg-red-50 border border-red-200 text-red-700'}`}>
          <p className="font-medium mb-2">{isDOS ? 'ERROR:' : ''} {error || 'Recipe not found'}</p>
          <button
            onClick={() => navigate(-1)}
            className={`inline-block px-4 py-2 rounded-lg transition-colors mt-4 ${
              isDOS
                ? 'bg-dos-black border-2 border-dos-green text-dos-green hover:bg-dos-green hover:text-dos-black'
                : 'bg-red-600 text-white hover:bg-red-700'
            }`}
          >
            {isDOS ? '[ESC] BACK TO RECIPES' : 'Back to Recipes'}
          </button>
        </div>
      </div>
    )
  }

  const totalTime = recipe.cook_time + recipe.prep_time

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Back button */}
      <button
        onClick={() => navigate(-1)}
        className={`inline-flex items-center gap-2 mb-6 transition-colors ${
          isDOS
            ? 'text-dos-green hover:text-dos-green-dim font-mono'
            : 'text-gray-600 hover:text-gray-900'
        }`}
      >
        {!isDOS && (
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        )}
        {isDOS ? '[ESC] BACK TO ALL RECIPES' : 'Back to all recipes'}
      </button>

      <div className={`rounded-lg overflow-hidden ${
        isDOS
          ? 'bg-dos-black border-2 border-dos-green'
          : 'bg-white shadow-lg'
      }`}>
        {/* Hero section with image */}
        <div className={`relative h-96 ${isDOS ? 'bg-dos-black' : 'bg-gray-200'}`}>
          {recipe.image_url ? (
            <img
              src={recipe.image_url}
              alt={recipe.title}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className={`w-full h-full flex items-center justify-center ${isDOS ? 'text-dos-green' : 'text-gray-400'}`}>
              {isDOS ? (
                <div className="text-6xl font-mono">[NO IMAGE]</div>
              ) : (
                <svg className="w-32 h-32" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              )}
            </div>
          )}

          {/* Rating overlay */}
          {recipe.ratings !== null && (
            <div className={`absolute top-4 right-4 px-4 py-2 rounded-full text-lg font-bold flex items-center gap-2 ${
              isDOS
                ? 'bg-dos-green text-dos-black border-2 border-dos-green font-mono'
                : 'bg-yellow-400 text-gray-900'
            }`}>
              {!isDOS && (
                <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                </svg>
              )}
              {isDOS ? '★ ' : ''}{Number(recipe.ratings).toFixed(1)}
            </div>
          )}
        </div>

        {/* Content */}
        <div className="p-8">
          {/* Title and meta */}
          <h1 className={`text-4xl font-bold mb-4 ${isDOS ? 'text-dos-green font-mono' : 'text-gray-900'}`}>
            {recipe.title}
          </h1>

          {/* Tags and Author */}
          <div className={`flex flex-wrap items-center gap-3 mb-6 pb-6 ${isDOS ? 'border-b border-dos-green' : 'border-b'}`}>
            {recipe.category && (
              <Link
                to={`/recipes?category_id=${recipe.category.id}`}
                className={`inline-block px-3 py-1 rounded-full text-sm font-medium transition-colors ${
                  isDOS
                    ? 'bg-dos-black border border-dos-green text-dos-green hover:bg-dos-green hover:text-dos-black font-mono'
                    : 'bg-red-100 text-red-700 hover:bg-red-200'
                }`}
              >
                {recipe.category.name}
              </Link>
            )}
            {recipe.cuisine && (
              <span className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${
                isDOS
                  ? 'bg-dos-black border border-dos-green-dim text-dos-green-dim font-mono'
                  : 'bg-gray-100 text-gray-700'
              }`}>
                {recipe.cuisine}
              </span>
            )}
            {recipe.author && (
              <Link
                to={`/recipes?author_id=${recipe.author.id}`}
                className={`inline-flex items-center gap-1 transition-colors ${
                  isDOS
                    ? 'text-dos-green hover:text-dos-green-dim font-mono'
                    : 'text-gray-600 hover:text-red-600'
                }`}
              >
                {!isDOS && (
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                )}
                <span className="font-medium">{isDOS ? '► by ' : 'by '}{recipe.author.name}</span>
              </Link>
            )}
          </div>

          {/* Time Information */}
          <div className={`grid grid-cols-1 md:grid-cols-3 gap-6 mb-8 p-6 rounded-lg ${
            isDOS
              ? 'bg-dos-black border border-dos-green'
              : 'bg-gray-50'
          }`}>
            {recipe.prep_time > 0 && (
              <div className="flex items-center gap-3">
                {!isDOS && (
                  <div className="flex-shrink-0 w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
                    <svg className="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                )}
                <div>
                  <p className={`text-sm ${isDOS ? 'text-dos-green-dim font-mono' : 'text-gray-600'}`}>
                    {isDOS ? 'PREP TIME:' : 'Prep Time'}
                  </p>
                  <p className={`text-lg font-semibold ${isDOS ? 'text-dos-green font-mono' : 'text-gray-900'}`}>
                    {recipe.prep_time} min
                  </p>
                </div>
              </div>
            )}

            {recipe.cook_time > 0 && (
              <div className="flex items-center gap-3">
                {!isDOS && (
                  <div className="flex-shrink-0 w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
                    <svg className="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z" />
                    </svg>
                  </div>
                )}
                <div>
                  <p className={`text-sm ${isDOS ? 'text-dos-green-dim font-mono' : 'text-gray-600'}`}>
                    {isDOS ? 'COOK TIME:' : 'Cook Time'}
                  </p>
                  <p className={`text-lg font-semibold ${isDOS ? 'text-dos-green font-mono' : 'text-gray-900'}`}>
                    {recipe.cook_time} min
                  </p>
                </div>
              </div>
            )}

            {totalTime > 0 && (
              <div className="flex items-center gap-3">
                {!isDOS && (
                  <div className="flex-shrink-0 w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
                    <svg className="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                    </svg>
                  </div>
                )}
                <div>
                  <p className={`text-sm ${isDOS ? 'text-dos-green-dim font-mono' : 'text-gray-600'}`}>
                    {isDOS ? 'TOTAL TIME:' : 'Total Time'}
                  </p>
                  <p className={`text-lg font-semibold ${isDOS ? 'text-dos-green font-mono' : 'text-gray-900'}`}>
                    {totalTime} min
                  </p>
                </div>
              </div>
            )}
          </div>

          {/* Ingredients */}
          <div className="mb-8">
            <h2 className={`text-2xl font-bold mb-4 ${isDOS ? 'text-dos-green font-mono' : 'text-gray-900'}`}>
              {isDOS ? '> INGREDIENTS.TXT' : 'Ingredients'}
            </h2>
            <ul className="space-y-2">
              {recipe.ingredients.map((ingredient, index) => (
                <li key={index} className="flex items-start gap-3">
                  {isDOS ? (
                    <span className="text-dos-green flex-shrink-0 mt-0.5 font-mono">[ ]</span>
                  ) : (
                    <svg className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                    </svg>
                  )}
                  <span className={isDOS ? 'text-dos-green font-mono' : 'text-gray-700'}>{ingredient}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </div>
  )
}

export default RecipeDetail
