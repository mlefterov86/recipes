import { useState, useEffect } from 'react'
import type { Category, Author, FilterParams, SortOption } from '../types'
import TagInput from './TagInput'
import SearchableSelect from './SearchableSelect'

interface FilterBarProps {
  filters: FilterParams
  onFiltersChange: (filters: Partial<FilterParams>) => void
}

function FilterBar({ filters, onFiltersChange }: FilterBarProps) {
  const [categories, setCategories] = useState<Category[]>([])
  const [authors, setAuthors] = useState<Author[]>([])
  const [loading, setLoading] = useState(true)

  // Fetch categories and authors for filters
  // Categories are filtered by selected author, authors are filtered by selected category
  useEffect(() => {
    const fetchFilterData = async () => {
      setLoading(true)
      try {
        // Build query params for contextual filtering
        const categoryParams = new URLSearchParams()
        if (filters.author_id) {
          categoryParams.set('author_id', filters.author_id.toString())
        }
        // Include the currently selected category so it stays in the dropdown
        if (filters.category_id) {
          categoryParams.set('category_id', filters.category_id.toString())
        }

        const authorParams = new URLSearchParams()
        if (filters.category_id) {
          authorParams.set('category_id', filters.category_id.toString())
        }
        // Include the currently selected author so it stays in the dropdown
        if (filters.author_id) {
          authorParams.set('author_id', filters.author_id.toString())
        }

        const categoriesUrl = `/api/v1/categories?${categoryParams.toString()}`
        const authorsUrl = `/api/v1/authors?${authorParams.toString()}`

        const [categoriesRes, authorsRes] = await Promise.all([
          fetch(categoriesUrl),
          fetch(authorsUrl)
        ])

        if (!categoriesRes.ok || !authorsRes.ok) {
          throw new Error(`HTTP error! Categories: ${categoriesRes.status}, Authors: ${authorsRes.status}`)
        }

        const [categoriesData, authorsData] = await Promise.all([
          categoriesRes.json(),
          authorsRes.json()
        ])

        setCategories(categoriesData.data || [])
        setAuthors(authorsData.data || [])
      } catch (error) {
        console.error('Error fetching filter data:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchFilterData()
  }, [filters.category_id, filters.author_id])

  const handleClearFilters = () => {
    onFiltersChange({
      category_id: undefined,
      author_id: undefined,
      title: undefined,
      ingredient: undefined,
      query: undefined,
      sort_by: undefined,
      page: 1
    })
  }

  const hasActiveFilters = filters.category_id || filters.author_id || filters.title || filters.ingredient || filters.query || filters.sort_by
  const isInitialLoad = loading && categories.length === 0 && authors.length === 0

  if (isInitialLoad) {
    return (
      <div className="bg-white rounded-lg shadow p-6 mb-8">
        <p className="text-gray-500">Loading filters...</p>
      </div>
    )
  }

  return (
    <div className="bg-white rounded-lg shadow p-6 mb-8">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-gray-900">Filters</h2>
        {hasActiveFilters && (
          <button
            onClick={handleClearFilters}
            className="text-sm text-red-600 hover:text-red-700 font-medium"
          >
            Clear all filters
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        {/* Category Filter */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Category
          </label>
          <SearchableSelect
            value={filters.category_id}
            options={categories}
            onChange={(value) => onFiltersChange({
              category_id: value,
              page: 1
            })}
            placeholder="All Categories"
            disabled={loading}
            loading={loading}
          />
        </div>

        {/* Author Filter */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Author
          </label>
          <SearchableSelect
            value={filters.author_id}
            options={authors}
            onChange={(value) => onFiltersChange({
              author_id: value,
              page: 1
            })}
            placeholder="All Authors"
            disabled={loading}
            loading={loading}
          />
        </div>

        {/* Title Search */}
        <div>
          <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-1">
            Recipe Title
          </label>
          <TagInput
            value={filters.title || ''}
            onChange={(value) => onFiltersChange({
              title: value || undefined,
              page: 1
            })}
            placeholder="Type and press Enter..."
            tagColor="blue"
            className="w-full"
          />
        </div>

        {/* Ingredient Search */}
        <div>
          <label htmlFor="ingredient" className="block text-sm font-medium text-gray-700 mb-1">
            Ingredient
          </label>
          <TagInput
            value={filters.ingredient || ''}
            onChange={(value) => onFiltersChange({
              ingredient: value || undefined,
              page: 1
            })}
            placeholder="Type and press Enter..."
            tagColor="green"
            className="w-full"
          />
        </div>

        {/* Sort Dropdown */}
        <div>
          <label htmlFor="sort" className="block text-sm font-medium text-gray-700 mb-1">
            Sort By
          </label>
          <select
            id="sort"
            value={filters.sort_by || ''}
            onChange={(e) => onFiltersChange({
              sort_by: (e.target.value as SortOption) || undefined,
              page: 1
            })}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
          >
            <option value="">Default (Rating & Date)</option>
            <option value="rating_desc">Rating (High to Low)</option>
            <option value="rating_asc">Rating (Low to High)</option>
            <option value="created_desc">Newest First</option>
            <option value="created_asc">Oldest First</option>
            <option value="title_asc">Title (A-Z)</option>
            <option value="title_desc">Title (Z-A)</option>
            <option value="author_asc">Author (A-Z)</option>
            <option value="author_desc">Author (Z-A)</option>
            <option value="category_asc">Category (A-Z)</option>
            <option value="category_desc">Category (Z-A)</option>
          </select>
        </div>
      </div>

      {/* General Search - Full Width */}
      <div className="mt-4">
        <label htmlFor="query" className="block text-sm font-medium text-gray-700 mb-1">
          Search All Fields
        </label>
        <TagInput
          value={filters.query || ''}
          onChange={(value) => onFiltersChange({
            query: value || undefined,
            page: 1
          })}
          placeholder="Type words and press Enter, Space, or Comma to add tags..."
          tagColor="purple"
          className="w-full text-base"
        />
      </div>
    </div>
  )
}

export default FilterBar
