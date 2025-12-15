# Recipes Application

A modern full-stack recipe discovery platform built with Rails API backend and React frontend, featuring advanced search capabilities, filtering, and a modern card-based browsing experience.

## 📖 Table of Contents

- [Project Overview](#project-overview)
- [User Stories](#user-stories)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Development](#development)
- [Testing](#testing)
- [API Endpoints](#api-endpoints)
- [Code Quality](#code-quality)
- [Troubleshooting](#troubleshooting)
- [AI Assistance](#ai-tools-usage)

## Project Overview

The Recipes Application is a comprehensive recipe discovery and browsing platform that allows users to explore thousands of recipes with powerful search and filtering capabilities. Built with a modern tech stack, it provides:

- **Modern UI/UX**: Responsive card grid layout with smooth interactions and intuitive design
- **Advanced Search**: Three-tier search system (title-only, ingredient-only, and full-text search across all fields)
- **Smart Filtering**: Filter by category, author, with contextual filter updates and AND logic
- **Searchable Dropdowns**: Category and author filters with keyboard navigation and real-time search
- **Tag-Based Search**: Visual tag inputs for multi-word searches with OR logic
- **Stable Pagination**: 20 recipes per page with deterministic ordering to prevent duplicates across pages
- **Rich Detail Pages**: Complete recipe information with clickable category/author links for instant filtering
- **URL State Preservation**: All filters and searches are bookmarkable through URL parameters

## User Stories

### As a Recipe Browser
- **Browse Recipes**: I want to view recipes in a modern card grid layout so I can quickly scan options
- **See Key Info**: I want to see recipe images, ratings, prep/cook times at a glance without clicking
- **Paginate Results**: I want to navigate through pages of recipes with numbered pagination

### As a Recipe Searcher
- **Search by Title**: I want to search recipe titles using multiple keywords (space/comma separated) with OR logic
- **Search by Ingredient**: I want to find recipes containing specific ingredients using multiple keywords
- **Search Everything**: I want to search across all fields (title, ingredients, category, author, cuisine) at once
- **Visual Tags**: I want to see my search terms as removable tags inside the input field
- **Instant Results**: I want search results to update immediately as I type

### As a Recipe Filterer
- **Filter by Category**: I want to select a category from a searchable dropdown with keyboard navigation
- **Filter by Author**: I want to select an author from a searchable dropdown with keyboard navigation
- **Contextual Filters**: I want author dropdown to show only authors who have recipes in my selected category
- **Combine Filters**: I want all filters to work together (AND logic) to narrow down results
- **Sort Results**: I want to sort by rating, date, title, author name, or category name

### As a Recipe Viewer
- **View Details**: I want to click a recipe card to see complete details including full ingredient list
- **Navigate Back**: I want the back button to return me to my filtered list with state preserved
- **Quick Filter**: I want to click category/author on detail page to instantly see similar recipes
- **Bookmark Searches**: I want to share or bookmark URLs that preserve my filters and searches

### As a Power User
- **Keyboard Navigation**: I want to navigate searchable dropdowns with arrow keys, enter, and escape
- **Multiple Words**: I want to search for "chocolate chip cookies" and find recipes with ANY of those words
- **Clear Filters**: I want a quick way to clear all filters and start fresh
- **Responsive Design**: I want the app to work seamlessly on mobile, tablet, and desktop

## Features

### Recipe Discovery
- **10,000+ Recipes**: Curated collection of recipes imported from external sources
- **Rich Metadata**: Each recipe includes title, ingredients, prep/cook times, ratings (0-5), cuisine type, and images
- **Smart Categorization**: Recipes organized into normalized categories with counter caches
- **Author Attribution**: Track recipes by author with case-insensitive uniqueness

### Advanced Search & Filtering
- **Three-Tier Search System**:
  - **Title Search**: ILIKE pattern matching on recipe titles
  - **Ingredient Search**: JSONB array element searching
  - **Full-Text Search**: PostgreSQL tsvector across all fields (title, ingredients, category, author, cuisine)
- **Multi-Word Search**: Space or comma-separated keywords with OR logic
- **Tag-Based Input**: Visual tag representation inside input fields with keyboard controls
- **Searchable Dropdowns**: Real-time filtering with keyboard navigation (arrows, enter, escape)
  - **Recipe Count Display**: Shows number of recipes per category/author (e.g., "Desserts (245)")
- **Contextual Filtering**: Author/category dropdowns update based on selected filters
- **AND Logic**: All active filters combine to progressively narrow results

### Modern UI/UX
- **Responsive Grid Layout**: Adaptive card layout (1-4 columns based on screen size)
- **Rich Recipe Cards**: Display image, title, rating, prep/cook times, category, and author
- **Pagination**: Classic numbered pagination (1 2 3...) with prev/next buttons
- **Detail Pages**: Full recipe information with clickable category/author links
- **URL State Management**: Filters persist in URL for bookmarking and sharing
- **Loading States**: Smooth loading indicators and error handling
- **Empty States**: Helpful messaging when no recipes match filters

### Database Architecture
- **PostgreSQL 16**: Advanced features including JSONB, tsvector, and GIN indexes
- **Normalized Schema**: Separate tables for recipes, categories, and authors with foreign keys
- **Counter Caches**: Automatic and manual counter caches for performance optimization
- **Composite Indexes**: Optimized indexes for category+rating, author+rating queries
- **Full-Text Search**: GIN index on tsvector column for instant text search
- **Pagination Stability**: ID tie-breakers ensure consistent results across requests

### Data Import System
- **RecipeImporter**: Bulk import recipes from external JSON sources
- **Smart Processing**:
  - Downloads and extracts gzipped JSON files
  - Normalizes category/author names (titlecase, strip whitespace)
  - Extracts actual image URLs from proxy URLs
  - Handles duplicates and special characters
  - Provides progress tracking and error reporting
  - Updates counter caches automatically

## Tech Stack

### Backend
- **Ruby on Rails 8.1** - API-only mode with modern Rails features
- **PostgreSQL 16** - Advanced database features (JSONB, tsvector, GIN indexes)
- **Puma** - Multi-threaded web server
- **Custom Serializers** - Efficient JSON API responses

### Frontend
- **React 19** - Modern component-based UI library
- **TypeScript** - Type-safe development
- **React Router DOM** - Client-side routing with URL state management
- **Vite 5.4** - Fast build tool and dev server
- **Tailwind CSS** - Utility-first styling framework

### Testing & Quality
- **RSpec 3.13** - Behavior-driven testing framework
- **FactoryBot** - Test data generation
- **Shoulda Matchers** - Simplify model testing
- **Database Cleaner** - Test database isolation
- **RuboCop** - Ruby code style enforcement
- **ESLint** - JavaScript/TypeScript linting
- **Brakeman** - Rails security scanner
- **Bundler Audit** - Gem vulnerability scanning

### DevOps
- **Docker & Docker Compose** - Containerized development environment
- **GitHub Actions** - Continuous integration and automated testing
- **Pre-commit Hooks** - Local code quality checks before commits

## Getting Started

### Prerequisites

#### For Docker Setup (Recommended)
- **Docker Desktop** or **Docker Engine** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Git** for cloning the repository

#### For Local Setup (Alternative)
- **Ruby 3.3.6** - Use rbenv or rvm for version management
- **Node.js 20.x or higher** - Use nvm for version management
- **PostgreSQL 16** - Database server
- **Bundler 2.x** - Ruby dependency management

### Option 1: Docker Setup (Recommended)

This is the fastest way to get started with zero configuration.

#### 1. Clone the Repository
```bash
git clone <repository-url>
cd recipes
```

#### 2. Build Docker Images
```bash
docker compose build
```

This will:
- Build the Docker image with Ruby 3.3.6 and Node.js
- Install system dependencies (PostgreSQL client, build tools, etc.)

**Note:** Ruby gems and npm packages are installed when containers first start, not during build.

#### 3. Start All Services
```bash
docker compose up -d
```

This will:
- Create and start all containers
- Install Ruby gems and npm packages (first run only)
- Create the database and run migrations automatically (`rails db:prepare`)
- Import 10,000+ recipes automatically on first run (if database is empty)
- Start the following services:
  - **db**: PostgreSQL 16 database server (port 5432)
  - **web**: Rails API server (port 3000)
  - **vite**: Vite dev server for React frontend (port 3036)

**Note:** The first `docker compose up -d` may take 10-15 minutes as it:
- Installs all dependencies
- Sets up the database
- Downloads and imports 10,000+ recipes from external source

You can monitor the progress with: `docker compose logs -f web`

#### 4. Wait for Setup to Complete

The first startup automatically imports recipe data. Monitor progress:
```bash
# Watch the logs to see import progress
docker compose logs -f web

# Wait until you see: "🎉 Recipe import process finished!"
# Press Ctrl+C to exit logs
```

#### 5. Verify Setup
```bash
# Check database record counts
docker exec recipes-web-1 rails runner "puts \"Recipes: #{Recipe.count}, Categories: #{Category.count}, Authors: #{Author.count}\""

# Expected output:
# Recipes: 10013, Categories: 50, Authors: 234
```

If the counts are zero, wait a bit longer as the import may still be running. Check logs with `docker compose logs -f web`.

#### 6. Access the Application
- **Frontend (React)**: http://localhost:3036
- **API (Rails)**: http://localhost:3000
- **Health Check**: http://localhost:3000/health
- **API Recipes Endpoint**: http://localhost:3000/api/v1/recipes

#### 7. View Logs (Optional)
```bash
# View all service logs
docker compose logs -f

# View specific service logs
docker compose logs -f web    # Rails logs
docker compose logs -f vite   # Vite logs
docker compose logs -f db     # PostgreSQL logs
```

#### 8. Stop Services
```bash
# Stop containers but keep data
docker compose down

# Stop containers and remove volumes (deletes database data)
docker compose down -v
```

### Option 2: Local Setup (Without Docker)

#### 1. Clone the Repository
```bash
git clone <repository-url>
cd recipes
```

#### 2. Install Ruby Dependencies
```bash
bundle install
```

#### 3. Install JavaScript Dependencies
```bash
npm install
```

#### 4. Setup PostgreSQL Database

Ensure PostgreSQL 16 is installed and running:
```bash
# macOS (Homebrew)
brew services start postgresql@16

# Linux (systemd)
sudo systemctl start postgresql

# Verify PostgreSQL is running
psql --version
```

#### 5. Configure Database Connection

Create `.env` file in the root directory:
```env
DATABASE_HOST=localhost
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
RAILS_ENV=development
NODE_ENV=development
```

#### 6. Setup the Database
```bash
# Create database, run migrations, and import recipe data
rails db:create db:migrate db:seed
```

**Note:** `db:seed` will download and import 10,000+ recipes. This may take 5-10 minutes.

#### 7. Start Development Servers

**Option A: Using Foreman (Recommended)**
```bash
bin/dev
```

**Option B: Manual (3 separate terminals)**

Terminal 1 - Rails API (port 3000):
```bash
rails server -p 3000
```

Terminal 2 - Vite dev server (port 3036):
```bash
npx vite
```

Terminal 3 - Tailwind CSS watcher:
```bash
rails tailwindcss:watch
```

#### 8. Access the Application
- **Frontend (React)**: http://localhost:3036
- **API (Rails)**: http://localhost:3000
- **Health Check**: http://localhost:3000/health

## Documentation

Comprehensive documentation is available in the `/docs` directory:

### 📚 Core Documentation

- **[Database Schema Guide](docs/DATABASE_SCHEMA.md)** - Complete database architecture documentation
  - Entity relationship diagrams
  - Table structures and relationships
  - Index strategy and query optimization
  - Counter cache implementation
  - Pagination stability with ID tie-breakers
  - Migration examples and best practices
  - Model definitions and usage examples

- **[Testing Guide](docs/TESTING.md)** - Complete testing documentation
  - How to run tests (308 passing tests)
  - Test suite breakdown by category
  - Docker and local test execution
  - Shell aliases for faster testing
  - Test database isolation
  - Recent test additions (pagination consistency tests)

### 🎯 Quick Links by Task

**Setting up the database?** → [Database Schema Guide](docs/DATABASE_SCHEMA.md)

**Running tests?** → [Testing Guide](docs/TESTING.md)

**API development?** → See [API Endpoints](#api-endpoints) section below

## Development

### Project Structure

```
.
├── app/
│   ├── commands/              # Service objects for complex operations
│   │   ├── recipe_importer.rb # Bulk recipe import service
│   │   └── service_object.rb  # Base service object class
│   ├── controllers/
│   │   ├── api/v1/            # API controllers (namespaced)
│   │   │   ├── recipes_controller.rb
│   │   │   ├── categories_controller.rb
│   │   │   └── authors_controller.rb
│   │   ├── concerns/          # Controller concerns
│   │   │   └── paginatable.rb # Pagination logic
│   │   ├── application_controller.rb
│   │   └── health_controller.rb
│   ├── models/                # ActiveRecord models
│   │   ├── recipe.rb          # Recipe with search scopes and sorting
│   │   ├── category.rb        # Category with counter caches
│   │   └── author.rb          # Author with counter caches
│   ├── serializers/           # Custom JSON serializers
│   │   ├── recipe_serializer.rb
│   │   ├── category_serializer.rb
│   │   └── author_serializer.rb
│   ├── services/              # Utility services
│   │   ├── file_downloader.rb
│   │   └── gzip_extractor.rb
│   └── javascript/            # React frontend
│       ├── components/        # React components
│       │   ├── RecipeList.tsx
│       │   ├── RecipeDetail.tsx
│       │   ├── RecipeCard.tsx
│       │   ├── FilterBar.tsx
│       │   ├── TagInput.tsx
│       │   ├── SearchableSelect.tsx
│       │   └── Pagination.tsx
│       ├── types/             # TypeScript type definitions
│       │   ├── models/
│       │   │   ├── recipe.ts
│       │   │   ├── category.ts
│       │   │   └── author.ts
│       │   └── api.ts
│       ├── application.tsx    # Main React app
│       ├── router.tsx         # React Router configuration
│       └── index.html         # Entry HTML file
├── config/
│   ├── routes.rb              # Rails routes
│   └── initializers/
│       └── cors.rb            # CORS configuration
├── db/
│   ├── migrate/               # Database migrations
│   ├── schema.rb              # Current database schema
│   └── seeds.rb               # Seed data (uses RecipeImporter)
├── spec/                      # RSpec test suite (308 tests)
│   ├── commands/              # Service object tests
│   ├── controllers/concerns/  # Controller concern tests
│   ├── models/                # Model tests
│   ├── requests/api/v1/       # API endpoint tests
│   ├── serializers/           # Serializer tests
│   ├── services/              # Service tests
│   └── support/               # Test helpers
├── docs/                      # Documentation
│   ├── DATABASE_SCHEMA.md
│   ├── TESTING.md
│   └── recipe-listing-feature-plan.md
└── docker-compose.yml         # Docker services configuration
```

### Database Models

**Recipe Model** (`app/models/recipe.rb`):
- **Attributes**: title, ingredients (JSONB array), cook_time, prep_time, ratings (0-5), cuisine, image_url, searchable (tsvector)
- **Associations**: belongs_to category (optional), belongs_to author (optional)
- **Scopes**:
  - Filtering: `by_category_id`, `by_author_id`
  - Searching: `search_title`, `search_ingredient`, `full_text_search`
  - Sorting: `sorted_by_rating_desc`, `sorted_by_created_desc`, `sorted_by_title_asc`, `sorted_by_author_asc`, `sorted_by_category_asc`, `sorted_by_default`
- **Features**:
  - Full-text search using PostgreSQL tsvector with automatic updates
  - ID tie-breakers in sorting for pagination stability
  - Special character handling in searchable field
  - Automatic counter cache updates for categories and authors

**Category Model** (`app/models/category.rb`):
- **Attributes**: name (unique, titleized), recipes_count, authors_count
- **Counter caches**: Automatic recipes_count, manual authors_count (distinct)
- **Normalization**: Automatically titleizes names (e.g., "pizza dough" → "Pizza Dough")
- **Scopes**: `by_author` (contextual filtering)

**Author Model** (`app/models/author.rb`):
- **Attributes**: name (unique, case-insensitive), recipes_count, categories_count
- **Counter caches**: Automatic recipes_count, manual categories_count (distinct)
- **Normalization**: Strips whitespace, case-insensitive uniqueness
- **Scopes**: `by_category` (contextual filtering)

### Working with the Database

#### Via Rails Console
```bash
# Docker
docker exec -it recipes-web-1 rails console

# Local
rails console

# Query examples
Recipe.count
Recipe.search_title("chocolate").count
Recipe.by_category_id(Category.find_by(name: "Dessert").id).sorted_by_rating_desc.limit(10)
Recipe.search_ingredient("flour").sorted_by_default.first(5)
Category.order(recipes_count: :desc).limit(10)
Author.order(recipes_count: :desc).limit(10)
```

#### Via PostgreSQL CLI
```bash
# Docker
docker exec -it recipes-db-1 psql -U postgres -d recipes_development

# Local
psql -U postgres -d recipes_development

# SQL queries
SELECT COUNT(*) FROM recipes;
SELECT DISTINCT cuisine FROM recipes ORDER BY cuisine;
SELECT name, recipes_count FROM categories ORDER BY recipes_count DESC LIMIT 10;
\d recipes  -- Show table structure
\q          -- Quit
```

#### Via Database GUI (TablePlus, DBeaver, pgAdmin)
- **Host**: localhost
- **Port**: 5432
- **Database**: recipes_development (or recipes_test for testing)
- **Username**: postgres
- **Password**: postgres

### API Development

All API endpoints are namespaced under `/api/v1/` and follow JSON API conventions.

#### Adding New Endpoints

1. **Define routes** in `config/routes.rb`:
```ruby
namespace :api do
  namespace :v1 do
    resources :recipes, only: [:index, :show]
    resources :categories, only: [:index]
    resources :authors, only: [:index]
    # Add your new resource here
  end
end
```

2. **Create controller** in `app/controllers/api/v1/`:
```ruby
module Api
  module V1
    class YourResourceController < ApplicationController
      def index
        # Your logic here
        render_collection(YourResource.all, serializer: YourResourceSerializer)
      end

      def show
        resource = YourResource.find(params[:id])
        render_resource(resource, serializer: YourResourceSerializer)
      end
    end
  end
end
```

3. **Create serializer** in `app/serializers/`:
```ruby
class YourResourceSerializer
  def initialize(resource)
    @resource = resource
  end

  def as_json
    {
      id: @resource.id,
      name: @resource.name,
      # Add other attributes
    }
  end
end
```

### Frontend Development

The React application uses:
- **Vite** for fast development and hot module replacement
- **React Router** for client-side routing (defined in `app/javascript/router.tsx`)
- **TypeScript** with type definitions in `app/javascript/types/`
- **Tailwind CSS** for styling
- **Automatic API Proxying** - API calls to `/api/v1/*` are proxied to the Rails backend

Components are located in `app/javascript/components/` and follow a modern React patterns with hooks and TypeScript.

### Importing Recipe Data

The application uses `RecipeImporter` to load recipes from external sources. This runs automatically during the initial Docker setup (when you first run `docker compose up -d`), importing 10,000+ recipes into the database.

**Manual Import (if needed):**

If you need to re-import recipes or import them manually:

```bash
# Via Docker
docker exec -it recipes-web-1 rails console

# Via Local
rails console

# Import all recipes (10,000+)
RecipeImporter.call

# Check import results
Recipe.count        # Should be ~10,013
Category.count      # Should be ~50
Author.count        # Should be ~234

# View sample data
Recipe.first
Category.order(recipes_count: :desc).limit(10)
Author.order(recipes_count: :desc).limit(10)
```

**How RecipeImporter works:**
- Download gzipped JSON from S3
- Extract and parse recipe data
- Normalize category and author names
- Extract actual image URLs from proxy URLs
- Handle duplicates and special characters
- Update all counter caches
- Report progress and errors

## Testing

The project has comprehensive test coverage with **308 passing tests**.

### Running Tests

#### Option 1: From Docker Container (Recommended)
```bash
# Run all tests
docker exec recipes-web-1 bundle exec rspec

# Run specific test file
docker exec recipes-web-1 bundle exec rspec spec/models/recipe_spec.rb

# Run specific test
docker exec recipes-web-1 bundle exec rspec spec/models/recipe_spec.rb:10

# Run with documentation format
docker exec recipes-web-1 bundle exec rspec --format documentation
```

#### Option 2: Using Docker Compose
```bash
# From project directory (requires web service to be running)
docker compose exec web bundle exec rspec
```

#### Option 3: Local Setup
```bash
# Run all tests
bundle exec rspec

# Run specific file or test
bundle exec rspec spec/models/recipe_spec.rb:10
```

### Test Suite Breakdown

**Total: 308 tests - ALL PASSING ✅**

- **API Endpoints**: 52 tests
  - Recipes API: 39 tests (CRUD, filtering, sorting, pagination consistency)
  - Categories API: 6 tests (index, contextual filtering)
  - Authors API: 6 tests (index, contextual filtering)
  - Health Check: 1 test

- **Models**: 155 tests
  - Recipe: 109 tests (validations, associations, scopes, callbacks, pagination stability)
  - Category: 23 tests (validations, associations, counter caches)
  - Author: 23 tests (validations, associations, counter caches)

- **Serializers**: 18 tests (Recipe, Category, Author JSON structure)

- **Concerns**: 12 tests (Paginatable logic and metadata)

- **Services**: 71 tests (RecipeImporter, FileDownloader, GzipExtractor)

### Test Database Isolation

RSpec is configured to **always use the test database** (`recipes_test`), protecting your development data. The test environment is automatically set and enforced in `spec/rails_helper.rb`.

For more details, see [Testing Guide](docs/TESTING.md).

## API Endpoints

All API endpoints follow JSON API conventions with `data` and `meta` keys.

### Recipes

#### List Recipes
```
GET /api/v1/recipes
```

**Query Parameters:**
- `page` - Page number (default: 1)
- `category_id` - Filter by category UUID
- `author_id` - Filter by author UUID
- `title` - Search recipe titles (supports multiple words with OR logic)
- `ingredient` - Search ingredients array (supports multiple words with OR logic)
- `query` - Full-text search across all fields (title, ingredients, category, author, cuisine)
- `sort_by` - Sort option: `rating_desc`, `rating_asc`, `created_desc`, `created_asc`, `title_asc`, `title_desc`, `author_asc`, `author_desc`, `category_asc`, `category_desc`

**Example - Simple Request:**
```
GET /api/v1/recipes?page=1
```

**Example - Complex Request with Multiple Filters:**
```
GET /api/v1/recipes?category_id=550e8400-e29b-41d4-a716-446655440000&ingredient=chicken%20garlic&title=spicy&sort_by=rating_desc&page=2
```

This complex query will:
- Filter recipes in a specific category (by UUID)
- Search for recipes containing "chicken" OR "garlic" in ingredients
- Search for recipes with "spicy" in the title
- Sort results by rating (highest first)
- Return page 2 of results (recipes 21-40)

**Note:** All filters use AND logic (results must match ALL filters), but within each text search filter (title, ingredient, query), multiple words use OR logic.

**Basic Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "title": "Chocolate Chip Cookies",
      "image_url": "https://example.com/image.jpg",
      "ratings": 4.75,
      "cook_time": 12,
      "prep_time": 15,
      "cuisine": "American",
      "ingredients": ["flour", "sugar", "chocolate chips"],
      "category": {
        "id": "uuid",
        "name": "Desserts",
        "recipes_count": 245
      },
      "author": {
        "id": "uuid",
        "name": "Chef John",
        "recipes_count": 89
      }
    }
  ],
  "meta": {
    "pagination": {
      "current_page": 1,
      "total_pages": 501,
      "total_count": 10013,
      "per_page": 20,
      "has_next": true,
      "has_prev": false
    }
  }
}
```

#### Get Recipe Details
```
GET /api/v1/recipes/:id
```

**Response:**
```json
{
  "data": {
    "id": "uuid",
    "title": "Chocolate Chip Cookies",
    "image_url": "https://example.com/image.jpg",
    "ratings": 4.75,
    "cook_time": 12,
    "prep_time": 15,
    "cuisine": "American",
    "ingredients": [
      "2 cups all-purpose flour",
      "1 cup sugar",
      "2 cups chocolate chips"
    ],
    "category": {
      "id": "uuid",
      "name": "Desserts",
      "recipes_count": 245
    },
    "author": {
      "id": "uuid",
      "name": "Chef John",
      "recipes_count": 89
    },
    "created_at": "2024-12-15T10:00:00.000Z"
  }
}
```

### Categories

#### List Categories
```
GET /api/v1/categories
```

**Query Parameters:**
- `author_id` - Filter categories by author (shows only categories with recipes by this author)
- `category_id` - Include specific category even if filtered out

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Desserts",
      "recipes_count": 245
    },
    {
      "id": "uuid",
      "name": "Main Dishes",
      "recipes_count": 512
    }
  ]
}
```

**Note:** The `recipes_count` field represents the total number of recipes in each category. When contextual filtering is applied (e.g., `author_id` parameter), the count still reflects the total, but only categories with matching recipes are returned.

### Authors

#### List Authors
```
GET /api/v1/authors
```

**Query Parameters:**
- `category_id` - Filter authors by category (shows only authors with recipes in this category)
- `author_id` - Include specific author even if filtered out

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Chef John",
      "recipes_count": 89
    },
    {
      "id": "uuid",
      "name": "Julia Child",
      "recipes_count": 156
    }
  ]
}
```

**Note:** The `recipes_count` field represents the total number of recipes by each author. When contextual filtering is applied (e.g., `category_id` parameter), the count still reflects the total, but only authors with matching recipes are returned.

### Health Check

```
GET /health
```

**Response:**
```json
{
  "status": "ok"
}
```

## Code Quality

### Running Linters Manually

**Ruby (RuboCop):**
```bash
# Docker
docker exec recipes-web-1 bundle exec rubocop

# Auto-fix issues
docker exec recipes-web-1 bundle exec rubocop -a

# Local
bundle exec rubocop
bundle exec rubocop -a
```

**JavaScript/TypeScript (ESLint):**
```bash
# Docker
docker exec recipes-web-1 npm run lint
docker exec recipes-web-1 npm run lint:fix

# Local
npm run lint
npm run lint:fix
```

### Pre-commit Hooks

Install pre-commit hooks to automatically run linters before each commit:

```bash
bin/setup-hooks
```

This will:
- Run RuboCop on staged Ruby files (excluding `db/schema.rb`)
- Run ESLint on staged JavaScript/TypeScript files
- Prevent commits if linting fails
- Show helpful tips for fixing issues

**Bypass the hook (not recommended):**
```bash
git commit --no-verify
```

### Security Scanning

**Rails Security (Brakeman):**
```bash
# Docker
docker exec recipes-web-1 bundle exec brakeman

# Local
bundle exec brakeman
```

**Gem Vulnerabilities (Bundler Audit):**
```bash
# Docker
docker exec recipes-web-1 bundle exec bundler-audit

# Local
bundle exec bundler-audit
```

**npm Vulnerabilities:**
```bash
# Docker
docker exec recipes-web-1 npm audit

# Local
npm audit
npm audit fix  # Fix vulnerabilities automatically
```

### GitHub Actions CI

All pull requests and pushes to `main`, `develop`, or `master` automatically run:
- ✅ **RSpec** - Full test suite (308 tests)
- ✅ **RuboCop** - Ruby code style
- ✅ **ESLint** - JavaScript/TypeScript code style
- ✅ **Brakeman** - Rails security vulnerabilities
- ✅ **Bundler Audit** - Gem security vulnerabilities
- ✅ **npm audit** - JavaScript dependency vulnerabilities

See `.github/workflows/ci.yml` for details.

## Troubleshooting

### Common Issues

**Port Already in Use**
```bash
# Check what's using the port
lsof -ti:3000  # Rails
lsof -ti:3036  # Vite
lsof -ti:5432  # PostgreSQL

# Kill the process
kill -9 $(lsof -ti:3000)

# Or change ports in docker-compose.yml or vite.config.ts
```

**Database Connection Issues**
```bash
# Check if PostgreSQL is running
docker compose ps

# View database logs
docker compose logs db

# Restart database
docker compose restart db

# Recreate database
docker exec recipes-web-1 rails db:drop db:create db:migrate db:seed
```

**Vite Not Serving React App**
```bash
# Check if node_modules exists
ls app/javascript/node_modules

# Reinstall dependencies
docker exec recipes-web-1 npm install

# Check Vite logs
docker compose logs vite

# Restart Vite
docker compose restart vite
```

**CORS Errors**
```bash
# Verify CORS configuration includes your frontend origin
cat config/initializers/cors.rb

# Restart Rails server
docker compose restart web
```

**Test Database Issues**
```bash
# Reset test database
docker exec recipes-web-1 RAILS_ENV=test rails db:drop db:create db:migrate

# Run tests again
docker exec recipes-web-1 bundle exec rspec
```

**Docker Build Failures**
```bash
# Clean Docker cache and rebuild
docker compose down -v
docker system prune -a
docker compose build --no-cache
docker compose up -d
```

**Missing Environment Variables**
```bash
# Check current environment variables
docker exec recipes-web-1 env

# Verify .env file exists (for local setup)
cat .env
```

## Useful Docker Commands

```bash
# View running containers
docker compose ps

# View all containers (including stopped)
docker compose ps -a

# Execute Rails commands
docker exec recipes-web-1 rails console
docker exec recipes-web-1 rails db:migrate
docker exec recipes-web-1 rails routes

# Execute bash in container
docker exec -it recipes-web-1 bash
docker exec -it recipes-vite-1 bash

# View logs for specific service
docker compose logs -f web    # Rails logs
docker compose logs -f vite   # Vite logs
docker compose logs -f db     # PostgreSQL logs

# Restart specific service
docker compose restart web
docker compose restart vite

# Rebuild after dependency changes
docker compose build web
docker compose up -d web

# Clean up (remove containers, networks, volumes)
docker compose down          # Stop containers
docker compose down -v       # Stop and remove volumes (deletes database data)
```

## Environment Variables

Create a `.env` file in the root directory for local setup:

```env
# Database
DATABASE_HOST=localhost
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=recipes_development

# Rails
RAILS_ENV=development
RAILS_LOG_LEVEL=debug

# Node
NODE_ENV=development
```

**Note:** Docker setup uses environment variables defined in `docker-compose.yml`.

## CORS Configuration

CORS is configured to allow requests from the Vite dev server. See `config/initializers/cors.rb`:

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:3036'  # Vite dev server
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```

## AI Tools Usage

I used **Claude Code (Claude Sonnet 4.5)** throughout this project to speed up development. Here's how:

### What I Used AI For

**1. Project Setup**
Got up and running quickly with Docker configs, Rails 8.1 setup, Vite integration, and PostgreSQL configuration. AI helped scaffold the initial project structure so I could focus on building features rather than wrestling with configuration.

**2. Frontend Development**
Since I have junior-level React knowledge and don't have much professional FE experience, I relied heavily on AI assistance for the frontend implementation. This includes:
- React component structure and hooks (useState, useEffect, useRef)
- TypeScript type definitions and interfaces
- React Router and URL state management with useSearchParams
- Custom components like SearchableSelect and TagInput
- Tailwind styling and responsive layouts
- Client-side filtering logic

**3. Backend Problem Solving**
Used AI when I got stuck on backend issues or needed inspiration:
- Debugging query performance problems
- Fixing counter cache behavior
- Resolving pagination consistency issues
- PostgreSQL-specific features (tsvector, GIN indexes)

**4. Test Coverage**
AI helped me write comprehensive RSpec tests faster, covering models, controllers, serializers, and services. This saved a lot of time and ensured good test coverage (308 tests).

**5. Documentation**
AI helped me build this comprehensive documentation you're reading right now, including:
- This README with clear setup instructions and API examples
- [Database Schema Guide](docs/DATABASE_SCHEMA.md) with entity relationships and query optimization
- [Testing Guide](docs/TESTING.md) with test execution instructions
- Even the commit messages (if you look through the git history, you'll notice they're pretty detailed - that's AI helping me document changes properly)

### How I Validated AI-Generated Code

**Testing:** Ran the full RSpec suite (308 tests) and manually tested all features in the browser. Everything had to pass before I considered it done.

**Code Review:** Read through all generated code to understand what it does. Made adjustments when needed for clarity or to match my coding style.

**Linting:** Used RuboCop and ESLint to catch style issues and potential bugs.

**Manual Testing:** Tested all user flows in the browser, tried edge cases, and verified the API with curl.

**Refinement:** When AI code didn't work perfectly, I debugged and fixed issues (e.g., BigDecimal serialization bug, pagination stability problems).

### Transparency

I'm being upfront that AI (specifically Claude Code) played a significant role in this project, especially for frontend development where I'm less experienced. However, all code was reviewed, tested, and validated by me. I made all architectural decisions and ensured the final product meets quality standards.

## License
Miroslav Lefterov
