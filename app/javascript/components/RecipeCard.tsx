import { Link } from 'react-router-dom'
import type { Recipe } from '../types'

interface RecipeCardProps {
  recipe: Recipe
}

function RecipeCard({ recipe }: RecipeCardProps) {
  const totalTime = recipe.cook_time + recipe.prep_time

  return (
    <Link
      to={`/recipes/${recipe.id}`}
      className="block bg-white rounded-lg shadow-md hover:shadow-xl transition-shadow duration-300 overflow-hidden group"
    >
      {/* Image */}
      <div className="relative overflow-hidden aspect-[4/3] bg-gray-200">
        {recipe.image_url ? (
          <img
            src={recipe.image_url}
            alt={recipe.title}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-gray-400">
            <svg className="w-20 h-20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
        )}

        {/* Rating badge */}
        {recipe.ratings !== null && (
          <div className="absolute top-2 right-2 bg-yellow-400 text-gray-900 px-2 py-1 rounded-full text-sm font-semibold flex items-center gap-1">
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
            </svg>
            {Number(recipe.ratings).toFixed(1)}
          </div>
        )}
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Title */}
        <h3 className="font-semibold text-lg text-gray-900 mb-2 line-clamp-2 group-hover:text-red-600 transition-colors">
          {recipe.title}
        </h3>

        {/* Category and Author */}
        <div className="flex flex-wrap gap-2 mb-3">
          {recipe.category && (
            <span className="inline-block bg-red-100 text-red-700 text-xs px-2 py-1 rounded">
              {recipe.category.name}
            </span>
          )}
          {recipe.cuisine && (
            <span className="inline-block bg-gray-100 text-gray-700 text-xs px-2 py-1 rounded">
              {recipe.cuisine}
            </span>
          )}
        </div>

        {/* Author */}
        {recipe.author && (
          <p className="text-sm text-gray-600 mb-3">
            by {recipe.author.name}
          </p>
        )}

        {/* Time info */}
        <div className="flex items-center gap-4 text-sm text-gray-600">
          {recipe.prep_time > 0 && (
            <div className="flex items-center gap-1">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span>Prep: {recipe.prep_time}min</span>
            </div>
          )}
          {recipe.cook_time > 0 && (
            <div className="flex items-center gap-1">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z" />
              </svg>
              <span>Cook: {recipe.cook_time}min</span>
            </div>
          )}
          {totalTime > 0 && (
            <div className="text-gray-900 font-medium">
              Total: {totalTime}min
            </div>
          )}
        </div>
      </div>
    </Link>
  )
}

export default RecipeCard
