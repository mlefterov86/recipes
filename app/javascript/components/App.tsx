import { Outlet } from "react-router-dom";

function App() {
  return (
    <div className="min-h-screen">
      <header className="bg-red-600 text-white py-4 px-6 mb-8">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <h1 className="text-3xl font-bold">🍳 Recipes</h1>
        </div>
      </header>
      <main className="max-w-4xl mx-auto px-6">
        <Outlet />
      </main>
    </div>
  )
}

export default App
