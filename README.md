# Recipes Application

A full-stack web application built with Rails API backend and React frontend (powered by Vite).

## Architecture

- **Backend**: Rails 8.1 (API-only mode)
- **Frontend**: React 19 + React Router + Vite
- **Database**: PostgreSQL 16
- **Styling**: Tailwind CSS

## Prerequisites

### For Docker Setup (Recommended)
- Docker Desktop or Docker Engine
- Docker Compose

### For Local Setup
- Ruby 3.3.6
- Node.js 20.x or higher
- PostgreSQL 16
- Bundler 2.x

## Project Structure

```
.
├── app/
│   ├── controllers/       # Rails API controllers
│   ├── models/           # ActiveRecord models
│   └── javascript/       # React frontend application
│       ├── components/   # React components
│       ├── entrypoints/  # Vite entry points
│       ├── application.tsx
│       ├── router.tsx    # React Router configuration
│       └── index.html    # Main HTML entry point
├── config/
│   ├── routes.rb        # API routes (namespaced under /api/v1)
│   └── initializers/
│       └── cors.rb      # CORS configuration
└── docker-compose.yml   # Docker services configuration
```

## Getting Started

### Option 1: Docker Setup (Recommended)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd recipes
   ```

2. **Build Docker containers**
   ```bash
   docker-compose build
   ```

3. **Start all services**
   ```bash
   docker-compose up -d
   ```

4. **Setup the database**
   ```bash
   docker-compose exec web rails db:create db:migrate
   ```

5. **View logs** (optional)
   ```bash
   docker-compose logs -f
   ```

6. **Access the application**
   - Frontend (Vite): http://localhost:3036
   - API (Rails): http://localhost:3000
   - Health check: http://localhost:3000/health

7. **Stop services**
   ```bash
   docker-compose down
   ```

### Option 2: Local Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd recipes
   ```

2. **Install Ruby dependencies**
   ```bash
   bundle install
   ```

3. **Install JavaScript dependencies**
   ```bash
   npm install
   ```

4. **Setup the database**

   Ensure PostgreSQL is running, then:
   ```bash
   rails db:create db:migrate
   ```

5. **Start development servers**

   Using Foreman (recommended):
   ```bash
   bin/dev
   ```

   Or manually in separate terminals:

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

6. **Access the application**
   - Frontend (Vite): http://localhost:3036
   - API (Rails): http://localhost:3000
   - Health check: http://localhost:3000/health

## Development

### API Development

All API endpoints are namespaced under `/api/v1/`. Add new endpoints in:
- `config/routes.rb` - Define routes
- `app/controllers/api/v1/` - Create controllers

Example:
```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :recipes
  end
end
```

### Frontend Development

The React application uses React Router for client-side routing. The Vite dev server proxies API requests to the Rails backend automatically.

**Adding new routes:**
Edit `app/javascript/router.tsx` to add new routes.

**Creating components:**
Add new components in `app/javascript/components/`.

### Making API Calls

API calls from the frontend are automatically proxied to the Rails backend:

```typescript
// This calls http://localhost:3000/api/v1/recipes
fetch('/api/v1/recipes')
  .then(response => response.json())
  .then(data => console.log(data));
```

## Testing

This project uses RSpec for testing with FactoryBot for test data, Shoulda Matchers for additional matchers, and Database Cleaner for database management.

### Running Tests

**Run all tests:**
```bash
bundle exec rspec
```

**Run a specific test file:**
```bash
bundle exec rspec spec/requests/health_spec.rb
```

**Run tests matching a pattern:**
```bash
bundle exec rspec spec/models
```

**Run tests with documentation format:**
```bash
bundle exec rspec --format documentation
```

### Running Tests in Docker

**Using the test service (Recommended):**
```bash
# Runs tests with automatic database setup
docker-compose run --rm test
```

The test service automatically:
- Runs in RAILS_ENV=test
- Creates the test database if it doesn't exist
- Runs migrations
- Executes the test suite

**Note:** Always use the `test` service for running tests. The `web` service runs in development mode and is not configured for testing.

### Writing Tests

**Request Specs (API endpoints):**
```ruby
# spec/requests/api/v1/recipes_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::Recipes", type: :request do
  describe "GET /api/v1/recipes" do
    it "returns a successful response" do
      get '/api/v1/recipes'
      expect(response).to have_http_status(:success)
    end
  end
end
```

**Model Specs:**
```ruby
# spec/models/recipe_spec.rb
require 'rails_helper'

RSpec.describe Recipe, type: :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:description) }
end
```

**Using Factories:**
```ruby
# spec/factories/recipes.rb
FactoryBot.define do
  factory :recipe do
    name { Faker::Food.dish }
    description { Faker::Food.description }
  end
end

# In your specs:
let(:recipe) { create(:recipe) }
```

### Test Coverage

The CI pipeline automatically runs tests on every pull request and push to `main`. See the `test` job in `.github/workflows/ci.yml`.

## Code Quality & Linting

### Running Linters Manually

**Ruby (RuboCop):**
```bash
# Check for issues
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a
```

**JavaScript/TypeScript (ESLint):**
```bash
# Check for issues
npm run lint

# Auto-fix issues
npm run lint:fix
```

### Pre-commit Hooks

The project includes a pre-commit hook that automatically runs RuboCop and ESLint on staged files before each commit.

**Install the pre-commit hook:**
```bash
bin/setup-hooks
```

This will:
- Run RuboCop on staged Ruby files
- Run ESLint on staged JavaScript/TypeScript files
- Prevent commits if linting fails
- Show helpful tips for fixing issues

**Bypass the hook (not recommended):**
```bash
git commit --no-verify
```

### GitHub Actions CI

All pull requests and pushes to `main`, `develop`, or `master` automatically run:
- **RSpec** - Full test suite
- **RuboCop** - Ruby code style
- **ESLint** - JavaScript/TypeScript code style
- **Brakeman** - Rails security vulnerabilities
- **Bundler Audit** - Gem security vulnerabilities
- **npm audit** - JavaScript dependency vulnerabilities (fails on high/critical only)

See `.github/workflows/ci.yml` for details.

**Check for vulnerabilities locally:**
```bash
# Ruby gems
bundle exec bundler-audit

# JavaScript packages
npm audit

# Fix JavaScript vulnerabilities
npm audit fix
```

### Branch Protection Rules

To enforce CI checks before merging on GitHub:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Branches**
3. Click **Add branch protection rule**
4. For **Branch name pattern**, enter: `develop` (or `main`)
5. Enable these settings:
   - ✅ **Require status checks to pass before merging**
   - ✅ **Require branches to be up to date before merging**
   - Select required status checks:
     - `test`
     - `lint_ruby`
     - `lint_js`
     - `scan_ruby`
6. Click **Create** or **Save changes**

This will prevent merging until all CI checks pass.

## Docker Commands

**Rebuild containers after dependency changes:**
```bash
docker-compose build
```

**View running containers:**
```bash
docker-compose ps
```

**Execute Rails commands:**
```bash
docker-compose exec web rails console
docker-compose exec web rails db:migrate
```

**Execute bash in container:**
```bash
docker-compose exec web bash
docker-compose exec vite bash
```

**View logs for specific service:**
```bash
docker-compose logs -f web    # Rails logs
docker-compose logs -f vite   # Vite logs
docker-compose logs -f db     # PostgreSQL logs
```

**Clean up (remove containers and volumes):**
```bash
docker-compose down -v
```

## Environment Variables

Create a `.env` file in the root directory for environment-specific configuration:

```env
DATABASE_URL=postgres://postgres:postgres@localhost:5432/recipes_development
RAILS_ENV=development
NODE_ENV=development
```

## CORS Configuration

CORS is configured to allow requests from the Vite dev server (ports 3036). See `config/initializers/cors.rb` for details.

## Troubleshooting

**Port already in use:**
- Check if another process is using ports 3000, 3036, or 5432
- Stop the conflicting process or change ports in `docker-compose.yml` or `vite.config.ts`

**Database connection issues:**
- Ensure PostgreSQL is running
- Check `DATABASE_URL` environment variable
- Run `docker-compose logs db` to check database logs

**Vite not serving React app:**
- Check if `app/javascript/index.html` exists
- Ensure Node.js packages are installed: `npm install`
- Check Vite logs: `docker-compose logs vite`

**CORS errors:**
- Verify `config/initializers/cors.rb` includes your frontend origin
- Ensure `rack-cors` gem is installed: `bundle install`
- Restart Rails server after CORS changes

## Tech Stack

- **Backend Framework**: Ruby on Rails 8.1
- **Frontend Library**: React 19
- **Build Tool**: Vite 5.4
- **Routing**: React Router DOM
- **Styling**: Tailwind CSS
- **Database**: PostgreSQL 16
- **Web Server**: Puma
- **Package Manager**: npm

## License
Miroslav Lefterov
