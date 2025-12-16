import React from 'react'
import { Link } from 'react-router-dom'
import { useTheme } from '../contexts/ThemeContext'

interface Recipe {
  id: string
  title: string
  ratings: number
  cook_time: number
  prep_time: number
  cuisine: string | null
  category: {
    id: string
    name: string
    recipes_count: number
  } | null
  author: {
    id: string
    name: string
    recipes_count: number
  } | null
}

interface RecipeListItemProps {
  recipe: Recipe
  index: number
}

export function RecipeListItem({ recipe, index }: RecipeListItemProps) {
  const { theme } = useTheme()
  const isDOS = theme === 'dos-terminal'

  const totalTime = recipe.prep_time + recipe.cook_time
  const stars = '★'.repeat(Math.floor(recipe.ratings)) + '☆'.repeat(5 - Math.floor(recipe.ratings))

  return (
    <Link
      to={`/recipes/${recipe.id}`}
      className={`
        block p-4 mb-2 transition-all
        ${isDOS
          ? 'border border-dos-green hover:bg-dos-green-dark hover:text-dos-black'
          : 'border border-gray-200 hover:border-red-600 hover:bg-red-50'
        }
      `}
    >
      <div className={`${isDOS ? 'font-mono text-sm' : ''}`}>
        {/* Recipe Number and Title */}
        <div className="flex items-start justify-between mb-2">
          <div className="flex-1">
            <span className={`${isDOS ? 'text-dos-green-dim' : 'text-gray-500'}`}>
              [{String(index + 1).padStart(3, '0')}]
            </span>
            <span className={`ml-2 font-bold ${isDOS ? 'text-dos-green' : 'text-gray-900'}`}>
              {recipe.title}
            </span>
          </div>
          <div className={`${isDOS ? 'text-dos-green' : 'text-yellow-500'}`}>
            {stars} ({recipe.ratings.toFixed(1)})
          </div>
        </div>

        {/* Category and Author */}
        <div className={`ml-6 mb-1 ${isDOS ? 'text-dos-green-dim' : 'text-gray-600'}`}>
          {recipe.category && (
            <span>
              {isDOS ? '►' : '📁'} Category: {recipe.category.name}
            </span>
          )}
          {recipe.category && recipe.author && <span className="mx-2">|</span>}
          {recipe.author && (
            <span>
              {isDOS ? '►' : '👤'} Author: {recipe.author.name}
            </span>
          )}
        </div>

        {/* Time Information */}
        <div className={`ml-6 ${isDOS ? 'text-dos-green-dim' : 'text-gray-600'}`}>
          {isDOS ? '⏱' : '🕒'} Time: {recipe.prep_time}m prep + {recipe.cook_time}m cook = {totalTime}m total
        </div>

        {/* ASCII Separator */}
        {isDOS && (
          <div className="mt-2 text-dos-green-dim opacity-30">
            {'─'.repeat(80)}
          </div>
        )}
      </div>
    </Link>
  )
}
