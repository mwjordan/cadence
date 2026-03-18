# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default test user
test_email = ENV.fetch("TEST_EMAIL", "test@example.com")
test_password = ENV.fetch("TEST_PASSWORD", "password123")

User.find_or_create_by!(email: test_email) do |user|
  user.password = test_password
  user.password_confirmation = test_password
end

puts "✓ Default test user created: #{test_email}"
