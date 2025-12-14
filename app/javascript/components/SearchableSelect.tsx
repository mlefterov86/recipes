import { useState, useRef, useEffect } from 'react'

interface Option {
  id: number
  name: string
}

interface SearchableSelectProps {
  value: number | undefined
  options: Option[]
  onChange: (value: number | undefined) => void
  placeholder?: string
  disabled?: boolean
  loading?: boolean
}

function SearchableSelect({ value, options, onChange, placeholder = 'Select...', disabled = false, loading = false }: SearchableSelectProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [highlightedIndex, setHighlightedIndex] = useState(-1)
  const wrapperRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const optionsRef = useRef<(HTMLButtonElement | null)[]>([])

  const selectedOption = options.find(opt => opt.id === value)
  const filteredOptions = options.filter(opt =>
    opt.name.toLowerCase().includes(searchTerm.toLowerCase())
  )

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
        setIsOpen(false)
        setSearchTerm('')
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  // Focus input when dropdown opens
  useEffect(() => {
    if (isOpen && inputRef.current) {
      inputRef.current.focus()
    }
  }, [isOpen])

  // Reset highlighted index when search term changes
  useEffect(() => {
    setHighlightedIndex(-1)
  }, [searchTerm])

  // Scroll highlighted option into view
  useEffect(() => {
    if (highlightedIndex >= 0 && optionsRef.current[highlightedIndex]) {
      optionsRef.current[highlightedIndex]?.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest'
      })
    }
  }, [highlightedIndex])

  const handleSelect = (optionId: number) => {
    onChange(optionId)
    setIsOpen(false)
    setSearchTerm('')
  }

  const handleClear = () => {
    onChange(undefined)
    setIsOpen(false)
    setSearchTerm('')
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      setHighlightedIndex(prev => {
        const next = prev + 1
        return next >= filteredOptions.length ? 0 : next
      })
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      setHighlightedIndex(prev => {
        const next = prev - 1
        return next < 0 ? filteredOptions.length - 1 : next
      })
    } else if (e.key === 'Enter' && highlightedIndex >= 0) {
      e.preventDefault()
      const selectedOption = filteredOptions[highlightedIndex]
      if (selectedOption) {
        handleSelect(selectedOption.id)
      }
    } else if (e.key === 'Escape') {
      setIsOpen(false)
      setSearchTerm('')
    }
  }

  return (
    <div ref={wrapperRef} className="relative">
      <button
        type="button"
        onClick={() => !disabled && setIsOpen(!isOpen)}
        disabled={disabled}
        className={`w-full px-3 py-2 text-left border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 bg-white flex items-center justify-between ${
          disabled ? 'bg-gray-100 cursor-not-allowed' : 'cursor-pointer hover:border-gray-400'
        }`}
      >
        <span className={selectedOption ? 'text-gray-900' : 'text-gray-500'}>
          {selectedOption ? selectedOption.name : placeholder}
          {loading && <span className="text-xs text-gray-500 ml-1">(loading...)</span>}
        </span>
        <svg className={`w-5 h-5 text-gray-400 transition-transform ${isOpen ? 'transform rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-hidden">
          {/* Search input */}
          <div className="p-2 border-b border-gray-200">
            <input
              ref={inputRef}
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Search..."
              className="w-full px-3 py-2 border border-gray-300 rounded focus:ring-2 focus:ring-red-500 focus:border-red-500 text-sm"
            />
          </div>

          {/* Options list */}
          <div className="overflow-y-auto max-h-48">
            {/* Clear option */}
            {value !== undefined && (
              <button
                type="button"
                onClick={handleClear}
                className="w-full px-3 py-2 text-left hover:bg-gray-100 text-gray-500 italic text-sm border-b border-gray-200"
              >
                Clear selection
              </button>
            )}

            {filteredOptions.length === 0 ? (
              <div className="px-3 py-2 text-gray-500 text-sm">No options found</div>
            ) : (
              filteredOptions.map((option, index) => (
                <button
                  key={option.id}
                  ref={(el) => optionsRef.current[index] = el}
                  type="button"
                  onClick={() => handleSelect(option.id)}
                  className={`w-full px-3 py-2 text-left hover:bg-gray-100 ${
                    option.id === value ? 'bg-red-50 text-red-700 font-medium' :
                    index === highlightedIndex ? 'bg-blue-100' : 'text-gray-900'
                  }`}
                >
                  {option.name}
                </button>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )
}

export default SearchableSelect
