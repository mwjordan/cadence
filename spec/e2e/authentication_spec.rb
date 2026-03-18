require 'rails_helper'

RSpec.describe 'Authentication E2E', type: :system do
  let(:test_email) { ENV.fetch("TEST_EMAIL", "test@example.com") }
  let(:test_password) { ENV.fetch("TEST_PASSWORD", "password123") }
  let(:new_email) { "newuser@example.com" }
  let(:new_password) { "securepassword123" }

  describe 'User Sign Up' do
    it 'allows a new user to sign up' do
      visit new_user_registration_path

      fill_in 'Email', with: new_email
      fill_in 'Password', with: new_password
      fill_in 'Confirm Password', with: new_password

      click_button 'Sign up'

      expect(page).to have_content('Welcome! You have signed up successfully')
      expect(page).to have_current_path(root_path)
    end

    it 'shows error when passwords do not match' do
      visit new_user_registration_path

      fill_in 'Email', with: "another@example.com"
      fill_in 'Password', with: new_password
      fill_in 'Confirm Password', with: 'differentpassword'

      click_button 'Sign up'

      expect(page).to have_content("doesn't match")
    end

    it 'shows error when email is already taken' do
      # First create a user
      User.create!(email: "existing@example.com", password: "testpass123", password_confirmation: "testpass123")

      visit new_user_registration_path

      fill_in 'Email', with: "existing@example.com"
      fill_in 'Password', with: new_password
      fill_in 'Confirm Password', with: new_password

      click_button 'Sign up'

      expect(page).to have_content('has already been taken')
    end
  end

  describe 'User Sign In' do
    it 'allows user to sign in with valid credentials' do
      visit new_user_session_path

      fill_in 'Email', with: test_email
      fill_in 'Password', with: test_password

      click_button 'Sign in'

      expect(page).to have_content('Signed in successfully')
      expect(page).to have_current_path(root_path)
    end

    it 'shows error with invalid password' do
      visit new_user_session_path

      fill_in 'Email', with: test_email
      fill_in 'Password', with: 'wrongpassword'

      click_button 'Sign in'

      expect(page).to have_content('Invalid email or password')
    end

    it 'shows error with non-existent email' do
      visit new_user_session_path

      fill_in 'Email', with: 'nonexistent@example.com'
      fill_in 'Password', with: test_password

      click_button 'Sign in'

      expect(page).to have_content('Invalid email or password')
    end
  end

  describe 'User Sign Out' do
    it 'shows sign out button when user is logged in' do
      # Sign in through the UI
      visit new_user_session_path
      
      fill_in 'Email', with: test_email
      fill_in 'Password', with: test_password
      click_button 'Sign in'

      expect(page).to have_content('Signed in successfully')
      expect(page).to have_content("Signed in as: #{test_email}")
      expect(page).to have_button('Sign out')
    end
  end

  describe 'Unauthenticated User Access' do
    it 'requires authentication to access dashboard' do
      visit root_path
      expect(page).to have_current_path(new_user_session_path)
    end
  end
end
