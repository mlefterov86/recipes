if Recipe.count.zero?
  puts "🌱 Database is empty, running seeds..."
  service = RecipeImporter.call

  if service.success?
    puts "\n🎉 Recipe import process finished!"
    puts "Stats: #{service.result.inspect}"
  else
    puts "Import failed: #{service.errors.message}"
    puts "Error details: #{service.errors.inspect}"
  end
else
  puts "⏭️  Database already seeded, skipping..."
end
