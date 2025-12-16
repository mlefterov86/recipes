import { useState, useEffect, useCallback } from 'react'
import { useSearchParams } from 'react-router-dom'
import { useTheme } from '../contexts/ThemeContext'
import RecipeCard from './RecipeCard'
import { RecipeListItem } from './RecipeListItem'
import FilterBar from './FilterBar'
import Pagination from './Pagination'
import { ViewModeToggle } from './ViewModeToggle'
import type { Recipe, FilterParams, PaginationMeta, RecipesResponse } from '../types'

function RecipeList() {
  const { theme, viewMode } = useTheme()
  const isDOS = theme === 'dos-terminal'
  const isListView = viewMode === 'list'
  const [searchParams, setSearchParams] = useSearchParams()
  const [recipes, setRecipes] = useState<Recipe[]>([])
  const [pagination, setPagination] = useState<PaginationMeta | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Helper to validate UUID format
  const isValidUUID = (id: string | null): boolean => {
    if (!id) return false
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    return uuidRegex.test(id)
  }

  // Build filter params from URL search params
  const getFiltersFromURL = useCallback((): FilterParams => {
    const categoryId = searchParams.get('category_id')
    const authorId = searchParams.get('author_id')

    return {
      page: parseInt(searchParams.get('page') || '1'),
      category_id: isValidUUID(categoryId) ? categoryId! : undefined,
      author_id: isValidUUID(authorId) ? authorId! : undefined,
      title: searchParams.get('title') || undefined,
      ingredient: searchParams.get('ingredient') || undefined,
      query: searchParams.get('query') || undefined,
      sort_by: (searchParams.get('sort_by') as FilterParams['sort_by']) || undefined,
    }
  }, [searchParams])

  const [filters, setFilters] = useState<FilterParams>(getFiltersFromURL())

  // Update URL when filters change
  const updateFilters = (newFilters: Partial<FilterParams>) => {
    const updated = { ...filters, ...newFilters }
    setFilters(updated)

    const params = new URLSearchParams()
    if (updated.page) params.set('page', updated.page.toString())
    if (updated.category_id) params.set('category_id', updated.category_id.toString())
    if (updated.author_id) params.set('author_id', updated.author_id.toString())
    if (updated.title) params.set('title', updated.title)
    if (updated.ingredient) params.set('ingredient', updated.ingredient)
    if (updated.query) params.set('query', updated.query)
    if (updated.sort_by) params.set('sort_by', updated.sort_by)

    setSearchParams(params)
  }

  // Fetch recipes when filters change (server-side filtering and pagination)
  useEffect(() => {
    const fetchRecipes = async () => {
      setLoading(true)
      setError(null)

      try {
        const params = new URLSearchParams()
        params.set('page', filters.page.toString())
        if (filters.category_id) params.set('category_id', filters.category_id)
        if (filters.author_id) params.set('author_id', filters.author_id)
        if (filters.title) params.set('title', filters.title)
        if (filters.ingredient) params.set('ingredient', filters.ingredient)
        if (filters.query) params.set('query', filters.query)
        if (filters.sort_by) params.set('sort_by', filters.sort_by)

        const response = await fetch(`/api/v1/recipes?${params.toString()}`)

        if (!response.ok) {
          throw new Error('Failed to fetch recipes')
        }

        const data: RecipesResponse = await response.json()
        setRecipes(data.data || [])
        setPagination(data.meta || null)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An error occurred')
      } finally {
        setLoading(false)
      }
    }

    fetchRecipes()
  }, [filters.page, filters.category_id, filters.author_id, filters.title, filters.ingredient, filters.query, filters.sort_by])

  // Sync filters with URL when URL changes (browser back/forward)
  useEffect(() => {
    setFilters(getFiltersFromURL())
  }, [getFiltersFromURL])

  const handlePageChange = (page: number) => {
    updateFilters({ page })
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-8">
        <h1 className={`text-4xl font-bold ${isDOS ? 'text-dos-green font-mono' : 'text-gray-900'}`}>
          {isDOS ? '> DIR /RECIPES' : 'Discover Delicious Recipes'}
        </h1>
        <ViewModeToggle />
      </div>

      {/* Filters */}
      <FilterBar filters={filters} onFiltersChange={updateFilters} />

      {/* Loading state */}
      {loading && (
        <div className="text-center py-12">
          <div className={`inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid ${isDOS ? 'border-dos-green border-r-transparent' : 'border-red-600 border-r-transparent'}`}></div>
          <p className={`mt-4 ${isDOS ? 'text-dos-green font-mono' : 'text-gray-600'}`}>
            {isDOS ? 'LOADING RECIPES.DAT...' : 'Loading recipes...'}
          </p>
        </div>
      )}

      {/* Error state */}
      {error && !loading && (
        <div className={`rounded-lg p-4 ${isDOS ? 'bg-dos-black border-2 border-dos-green text-dos-green font-mono' : 'bg-red-50 border border-red-200 text-red-700'}`}>
          <p className="font-medium">{isDOS ? 'ERROR:' : 'Error loading recipes'}</p>
          <p className="text-sm mt-1">{error}</p>
        </div>
      )}

      {/* Empty state */}
      {!loading && !error && recipes.length === 0 && (
        <div className="text-center py-12">
          {!isDOS && (
            <svg className="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M12 12h.01M12 12h.01M12 12h.01M12 12h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          )}
          <h3 className={`text-lg font-medium mb-2 ${isDOS ? 'text-dos-green font-mono' : 'text-gray-900'}`}>
            {isDOS ? 'FILE NOT FOUND' : 'No recipes found'}
          </h3>
          <p className={`mb-4 ${isDOS ? 'text-dos-green-dim font-mono' : 'text-gray-600'}`}>
            {isDOS ? 'TRY ADJUSTING YOUR SEARCH PARAMETERS' : 'Try adjusting your filters or search criteria'}
          </p>
          <button
            onClick={() => updateFilters({
              category_id: undefined,
              author_id: undefined,
              title: undefined,
              ingredient: undefined,
              query: undefined,
              sort_by: undefined,
              page: 1
            })}
            className={`inline-block px-4 py-2 rounded-lg transition-colors ${isDOS ? 'bg-dos-black border-2 border-dos-green text-dos-green hover:bg-dos-green hover:text-dos-black' : 'bg-red-600 text-white hover:bg-red-700'}`}
          >
            {isDOS ? 'CLEAR FILTERS' : 'Clear all filters'}
          </button>
        </div>
      )}

      {/* Recipe Grid/List */}
      {!loading && !error && recipes.length > 0 && (
        <>
          {pagination && (
            <div className={`mb-4 text-sm ${isDOS ? 'text-dos-green font-mono' : 'text-gray-600'}`}>
              {isDOS ? `[${recipes.length} OF ${pagination.total_count} FILES]` : `Showing ${recipes.length} of ${pagination.total_count} recipes`}
              {pagination.current_page > 1 && (
                <span> {isDOS ? `[PAGE ${pagination.current_page}/${pagination.total_pages}]` : `(page ${pagination.current_page} of ${pagination.total_pages})`}</span>
              )}
            </div>
          )}

          {isListView ? (
            /* List View */
            <div className="flex flex-col space-y-0">
              {recipes.map((recipe, index) => (
                <RecipeListItem key={recipe.id} recipe={recipe} index={index} />
              ))}
            </div>
          ) : (
            /* Card Grid View */
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {recipes.map((recipe) => (
                <RecipeCard key={recipe.id} recipe={recipe} />
              ))}
            </div>
          )}

          {/* Pagination */}
          {pagination && pagination.total_pages > 1 && (
            <Pagination
              pagination={pagination}
              onPageChange={handlePageChange}
            />
          )}
        </>
      )}
    </div>
  )
}

export default RecipeList
