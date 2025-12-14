import { useState, KeyboardEvent } from 'react'

interface TagInputProps {
  value: string
  onChange: (value: string) => void
  placeholder?: string
  className?: string
  tagColor?: 'blue' | 'green' | 'purple'
}

function TagInput({ value, onChange, placeholder, className, tagColor = 'blue' }: TagInputProps) {
  const [inputValue, setInputValue] = useState('')

  const tags = value ? value.trim().split(/[\s,]+/).filter(Boolean) : []

  const colorClasses = {
    blue: 'bg-blue-100 text-blue-800 hover:bg-blue-200',
    green: 'bg-green-100 text-green-800 hover:bg-green-200',
    purple: 'bg-purple-100 text-purple-800 hover:bg-purple-200'
  }

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    // Create tag on Enter, Space, or Comma
    if (e.key === 'Enter' || e.key === ' ' || e.key === ',') {
      e.preventDefault()
      if (inputValue.trim()) {
        const newTags = [...tags, inputValue.trim()]
        onChange(newTags.join(' '))
        setInputValue('')
      }
    }
    // Remove last tag on Backspace when input is empty
    else if (e.key === 'Backspace' && !inputValue && tags.length > 0) {
      const newTags = tags.slice(0, -1)
      onChange(newTags.length > 0 ? newTags.join(' ') : '')
    }
  }

  const removeTag = (index: number) => {
    const newTags = tags.filter((_, i) => i !== index)
    onChange(newTags.length > 0 ? newTags.join(' ') : '')
  }

  return (
    <div className={`flex flex-wrap gap-1.5 items-center px-3 py-2 border border-gray-300 rounded-lg focus-within:ring-2 focus-within:ring-red-500 focus-within:border-red-500 ${className}`}>
      {tags.map((tag, index) => (
        <span
          key={index}
          className={`inline-flex items-center gap-1 px-2 py-0.5 text-sm font-medium rounded ${colorClasses[tagColor]}`}
        >
          {tag}
          <button
            type="button"
            onClick={() => removeTag(index)}
            className="flex-shrink-0"
          >
            <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
            </svg>
          </button>
        </span>
      ))}
      <input
        type="text"
        value={inputValue}
        onChange={(e) => setInputValue(e.target.value)}
        onKeyDown={handleKeyDown}
        placeholder={tags.length === 0 ? placeholder : ''}
        className="flex-1 min-w-[120px] outline-none bg-transparent"
      />
    </div>
  )
}

export default TagInput
