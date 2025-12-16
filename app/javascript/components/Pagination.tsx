import { useTheme } from '../contexts/ThemeContext'
import type { PaginationMeta } from '../types'

interface PaginationProps {
  pagination: PaginationMeta
  onPageChange: (page: number) => void
}

function Pagination({ pagination, onPageChange }: PaginationProps) {
  const { theme } = useTheme()
  const isDOS = theme === 'dos-terminal'
  const { current_page, total_pages, has_prev, has_next } = pagination

  // Generate page numbers to display
  const getPageNumbers = () => {
    const pages: (number | string)[] = []
    const maxPagesToShow = 7

    if (total_pages <= maxPagesToShow) {
      // Show all pages if total is small
      for (let i = 1; i <= total_pages; i++) {
        pages.push(i)
      }
    } else {
      // Always show first page
      pages.push(1)

      if (current_page <= 3) {
        // Near the start
        for (let i = 2; i <= 4; i++) {
          pages.push(i)
        }
        pages.push('...')
        pages.push(total_pages)
      } else if (current_page >= total_pages - 2) {
        // Near the end
        pages.push('...')
        for (let i = total_pages - 3; i <= total_pages; i++) {
          pages.push(i)
        }
      } else {
        // In the middle
        pages.push('...')
        for (let i = current_page - 1; i <= current_page + 1; i++) {
          pages.push(i)
        }
        pages.push('...')
        pages.push(total_pages)
      }
    }

    return pages
  }

  if (total_pages <= 1) {
    return null
  }

  return (
    <div className="flex justify-center items-center gap-2 mt-8">
      {/* Previous button */}
      <button
        onClick={() => onPageChange(current_page - 1)}
        disabled={!has_prev}
        className={`px-4 py-2 rounded-lg font-medium transition-colors ${
          isDOS
            ? has_prev
              ? 'bg-dos-black text-dos-green border-2 border-dos-green hover:bg-dos-green hover:text-dos-black font-mono'
              : 'bg-dos-black text-dos-green-dark border border-dos-green-dark cursor-not-allowed font-mono'
            : has_prev
              ? 'bg-white text-gray-700 hover:bg-red-50 hover:text-red-600 border border-gray-300'
              : 'bg-gray-100 text-gray-400 cursor-not-allowed border border-gray-200'
        }`}
      >
        {isDOS ? '[<]' : 'Previous'}
      </button>

      {/* Page numbers */}
      <div className="flex gap-1">
        {getPageNumbers().map((page, index) => {
          if (page === '...') {
            return (
              <span
                key={`ellipsis-${index}`}
                className={`px-3 py-2 ${isDOS ? 'text-dos-green-dim font-mono' : 'text-gray-500'}`}
              >
                ...
              </span>
            )
          }

          const pageNum = page as number
          const isActive = pageNum === current_page

          return (
            <button
              key={pageNum}
              onClick={() => onPageChange(pageNum)}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                isDOS
                  ? isActive
                    ? 'bg-dos-green text-dos-black border-2 border-dos-green font-mono'
                    : 'bg-dos-black text-dos-green border-2 border-dos-green hover:bg-dos-green hover:text-dos-black font-mono'
                  : isActive
                    ? 'bg-red-600 text-white'
                    : 'bg-white text-gray-700 hover:bg-red-50 hover:text-red-600 border border-gray-300'
              }`}
            >
              {pageNum}
            </button>
          )
        })}
      </div>

      {/* Next button */}
      <button
        onClick={() => onPageChange(current_page + 1)}
        disabled={!has_next}
        className={`px-4 py-2 rounded-lg font-medium transition-colors ${
          isDOS
            ? has_next
              ? 'bg-dos-black text-dos-green border-2 border-dos-green hover:bg-dos-green hover:text-dos-black font-mono'
              : 'bg-dos-black text-dos-green-dark border border-dos-green-dark cursor-not-allowed font-mono'
            : has_next
              ? 'bg-white text-gray-700 hover:bg-red-50 hover:text-red-600 border border-gray-300'
              : 'bg-gray-100 text-gray-400 cursor-not-allowed border border-gray-200'
        }`}
      >
        {isDOS ? '[>]' : 'Next'}
      </button>
    </div>
  )
}

export default Pagination
