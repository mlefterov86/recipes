import { useState, useRef, useEffect } from 'react'
import { useTheme } from '../contexts/ThemeContext'

interface Option {
  id: string
  name: string
  recipes_count?: number
}

interface SearchableSelectProps {
  value: string | undefined
  options: Option[]
  onChange: (value: string | undefined) => void
  placeholder?: string
  disabled?: boolean
  loading?: boolean
}

function SearchableSelect({ value, options, onChange, placeholder = 'Select...', disabled = false, loading = false }: SearchableSelectProps) {
  const { theme } = useTheme()
  const isDOS = theme === 'dos-terminal'
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

  const handleSelect = (optionId: string) => {
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
        className={`w-full px-3 py-2 text-left rounded-lg flex items-center justify-between transition-colors ${
          isDOS
            ? disabled
              ? 'bg-dos-black border border-dos-green-dark text-dos-green-dark cursor-not-allowed font-mono'
              : 'bg-dos-black border-2 border-dos-green text-dos-green font-mono cursor-pointer hover:border-dos-green-dim focus:ring-2 focus:ring-dos-green'
            : disabled
              ? 'bg-gray-100 border border-gray-300 cursor-not-allowed'
              : 'bg-white border border-gray-300 cursor-pointer hover:border-gray-400 focus:ring-2 focus:ring-red-500 focus:border-red-500'
        }`}
      >
        <span className={
          isDOS
            ? selectedOption ? 'text-dos-green' : 'text-dos-green-dim'
            : selectedOption ? 'text-gray-900' : 'text-gray-500'
        }>
          {isDOS && selectedOption ? '► ' : ''}{selectedOption ? selectedOption.name : placeholder}
          {loading && (
            <span className={`text-xs ml-1 ${isDOS ? 'text-dos-green-dim' : 'text-gray-500'}`}>
              {isDOS ? '...' : '(loading...)'}
            </span>
          )}
        </span>
        {!isDOS ? (
          <svg className={`w-5 h-5 text-gray-400 transition-transform ${isOpen ? 'transform rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        ) : (
          <span className={`text-dos-green transition-transform ${isOpen ? 'transform rotate-180' : ''}`}>▼</span>
        )}
      </button>

      {isOpen && (
        <div className={`absolute z-10 w-full mt-1 rounded-lg max-h-60 overflow-hidden ${
          isDOS
            ? 'bg-dos-black border-2 border-dos-green shadow-dos-glow'
            : 'bg-white border border-gray-300 shadow-lg'
        }`}>
          {/* Search input */}
          <div className={`p-2 ${isDOS ? 'border-b border-dos-green' : 'border-b border-gray-200'}`}>
            <input
              ref={inputRef}
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder={isDOS ? 'SEARCH...' : 'Search...'}
              className={`w-full px-3 py-2 rounded text-sm transition-colors ${
                isDOS
                  ? 'bg-dos-black border-2 border-dos-green text-dos-green font-mono placeholder-dos-green-dim focus:ring-2 focus:ring-dos-green'
                  : 'border border-gray-300 focus:ring-2 focus:ring-red-500 focus:border-red-500'
              }`}
            />
          </div>

          {/* Options list */}
          <div className="overflow-y-auto max-h-48">
            {/* Clear option */}
            {value !== undefined && (
              <button
                type="button"
                onClick={handleClear}
                className={`w-full px-3 py-2 text-left text-sm transition-colors ${
                  isDOS
                    ? 'text-dos-green-dim hover:bg-dos-green-dark font-mono border-b border-dos-green'
                    : 'text-gray-500 italic hover:bg-gray-100 border-b border-gray-200'
                }`}
              >
                {isDOS ? '[X] CLEAR' : 'Clear selection'}
              </button>
            )}

            {filteredOptions.length === 0 ? (
              <div className={`px-3 py-2 text-sm ${isDOS ? 'text-dos-green-dim font-mono' : 'text-gray-500'}`}>
                {isDOS ? 'NO OPTIONS FOUND' : 'No options found'}
              </div>
            ) : (
              filteredOptions.map((option, index) => (
                <button
                  key={option.id}
                  ref={(el) => optionsRef.current[index] = el}
                  type="button"
                  onClick={() => handleSelect(option.id)}
                  className={`w-full px-3 py-2 text-left transition-colors ${
                    isDOS
                      ? option.id === value
                        ? 'bg-dos-green text-dos-black font-mono font-bold'
                        : index === highlightedIndex
                          ? 'bg-dos-green-dark text-dos-green font-mono'
                          : 'text-dos-green font-mono hover:bg-dos-green-dark'
                      : option.id === value
                        ? 'bg-red-50 text-red-700 font-medium'
                        : index === highlightedIndex
                          ? 'bg-blue-100'
                          : 'text-gray-900 hover:bg-gray-100'
                  }`}
                >
                  <span>{isDOS && option.id === value ? '► ' : ''}{option.name}</span>
                  {option.recipes_count !== undefined && (
                    <span className={`text-sm ml-1 ${isDOS ? 'text-dos-green-dim' : 'text-gray-500'}`}>
                      ({option.recipes_count})
                    </span>
                  )}
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
