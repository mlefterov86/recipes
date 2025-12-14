import { useState, useEffect, useCallback } from 'react'
import { useSearchParams } from 'react-router-dom'
import RecipeCard from './RecipeCard'
import FilterBar from './FilterBar'
import Pagination from './Pagination'
import type { Recipe, FilterParams, PaginationMeta, RecipesResponse } from '../types'

function RecipeList() {
  const [searchParams, setSearchParams] = useSearchParams()
  const [recipes, setRecipes] = useState<Recipe[]>([])
  const [filteredRecipes, setFilteredRecipes] = useState<Recipe[]>([])
  const [pagination, setPagination] = useState<PaginationMeta | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Build filter params from URL search params
  const getFiltersFromURL = useCallback((): FilterParams => {
    return {
      page: parseInt(searchParams.get('page') || '1'),
      category_id: searchParams.get('category_id') ? parseInt(searchParams.get('category_id')!) : undefined,
      author_id: searchParams.get('author_id') ? parseInt(searchParams.get('author_id')!) : undefined,
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

  // Fetch recipes when filters change
  useEffect(() => {
    const fetchRecipes = async () => {
      setLoading(true)
      setError(null)

      try {
        // Fetch ALL recipes (use very high per_page to get all results)
        const params = new URLSearchParams()
        params.set('per_page', '10000') // Fetch all recipes
        if (filters.category_id) params.set('category_id', filters.category_id.toString())
        if (filters.author_id) params.set('author_id', filters.author_id.toString())
        if (filters.sort_by) params.set('sort_by', filters.sort_by)

        const response = await fetch(`/api/v1/recipes?${params.toString()}`)

        if (!response.ok) {
          throw new Error('Failed to fetch recipes')
        }

        const data: RecipesResponse = await response.json()
        setRecipes(data.data || [])
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An error occurred')
      } finally {
        setLoading(false)
      }
    }

    fetchRecipes()
  }, [filters.category_id, filters.author_id, filters.sort_by])

  // Client-side filtering based on search inputs
  useEffect(() => {
    let filtered = [...recipes]

    // Filter by title (case-insensitive, supports multiple words separated by space or comma)
    if (filters.title) {
      const words = filters.title.trim().split(/[\s,]+/).filter(Boolean).map(w => w.toLowerCase())
      filtered = filtered.filter(recipe => {
        const titleLower = recipe.title.toLowerCase()
        return words.some(word => titleLower.includes(word))
      })
    }

    // Filter by ingredient (case-insensitive, supports multiple words, searches in ingredients array)
    if (filters.ingredient) {
      const words = filters.ingredient.trim().split(/[\s,]+/).filter(Boolean).map(w => w.toLowerCase())
      filtered = filtered.filter(recipe =>
        recipe.ingredients?.some(ing => {
          const ingLower = ing.toLowerCase()
          return words.some(word => ingLower.includes(word))
        })
      )
    }

    // Filter by query (searches across all text fields - case-insensitive, supports multiple words)
    if (filters.query) {
      const words = filters.query.trim().split(/[\s,]+/).filter(Boolean).map(w => w.toLowerCase())
      filtered = filtered.filter(recipe => {
        const searchableText = [
          recipe.title,
          recipe.cuisine,
          recipe.category?.name,
          recipe.author?.name,
          ...(recipe.ingredients || [])
        ].filter(Boolean).join(' ').toLowerCase()

        return words.some(word => searchableText.includes(word))
      })
    }

    setFilteredRecipes(filtered)
  }, [recipes, filters.title, filters.ingredient, filters.query])

  // Calculate pagination for filtered results
  const PER_PAGE = 20
  const totalFiltered = filteredRecipes.length
  const totalPages = Math.ceil(totalFiltered / PER_PAGE)
  const currentPage = filters.page
  const startIndex = (currentPage - 1) * PER_PAGE
  const endIndex = startIndex + PER_PAGE
  const paginatedRecipes = filteredRecipes.slice(startIndex, endIndex)

  // Update pagination meta based on filtered results
  useEffect(() => {
    setPagination({
      current_page: currentPage,
      per_page: PER_PAGE,
      total_count: totalFiltered,
      total_pages: totalPages,
      has_next: currentPage < totalPages,
      has_prev: currentPage > 1
    })
  }, [filteredRecipes, currentPage, totalFiltered, totalPages])

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
      <h1 className="text-4xl font-bold text-gray-900 mb-8">
        Discover Delicious Recipes
      </h1>

      {/* Filters */}
      <FilterBar filters={filters} onFiltersChange={updateFilters} />

      {/* Loading state */}
      {loading && (
        <div className="text-center py-12">
          <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-red-600 border-r-transparent"></div>
          <p className="mt-4 text-gray-600">Loading recipes...</p>
        </div>
      )}

      {/* Error state */}
      {error && !loading && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          <p className="font-medium">Error loading recipes</p>
          <p className="text-sm mt-1">{error}</p>
        </div>
      )}

      {/* Empty state */}
      {!loading && !error && filteredRecipes.length === 0 && (
        <div className="text-center py-12">
          <svg className="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M12 12h.01M12 12h.01M12 12h.01M12 12h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No recipes found</h3>
          <p className="text-gray-600 mb-4">
            Try adjusting your filters or search criteria
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
            className="inline-block px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
          >
            Clear all filters
          </button>
        </div>
      )}

      {/* Recipe Grid */}
      {!loading && !error && filteredRecipes.length > 0 && (
        <>
          <div className="mb-4 text-sm text-gray-600">
            Showing {paginatedRecipes.length} of {filteredRecipes.length} recipes
            {filters.title || filters.ingredient || filters.query ? (
              <span className="text-gray-600"> (filtered from {recipes.length} total)</span>
            ) : null}
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {paginatedRecipes.map((recipe) => (
              <RecipeCard key={recipe.id} recipe={recipe} />
            ))}
          </div>

          {/* Pagination */}
          {pagination && (
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
