class AppRenameService
  APP_PLACEHOLDER = "RailsAppStarterKit"
  DB_PLACEHOLDER = "rails_app_starter_kit"

  # Files that contain the app module name (PascalCase)
  MODULE_FILES = %w[
    config/application.rb
  ].freeze

  # Files that contain the app name in snake_case
  SNAKE_CASE_FILES = %w[
    config/database.yml
    config/deploy.yml
    Dockerfile
  ].freeze

  # Files that contain the human-readable app name
  HUMAN_NAME_FILES = %w[
    app/views/layouts/application.html.erb
    app/views/pwa/manifest.json.erb
  ].freeze

  def initialize(new_name)
    @new_name = new_name.strip
    @pascal_name = to_pascal_case(@new_name)
    @snake_name = to_snake_case(@new_name)
    @human_name = to_human_name(@new_name)
    @root = Rails.root.to_s
  end

  def call
    validate!
    rename_module_in_files
    rename_snake_case_in_files
    rename_human_name_in_files
    rename_databases
    {
      pascal_name: @pascal_name,
      snake_name: @snake_name,
      human_name: @human_name,
      files_updated: updated_files.uniq
    }
  end

  private

  attr_reader :new_name, :pascal_name, :snake_name, :human_name, :root

  def validate!
    raise ArgumentError, "App name cannot be blank" if new_name.blank?
    raise ArgumentError, "App name must start with a letter" unless new_name.match?(/\A[a-zA-Z]/)
    raise ArgumentError, "App name can only contain letters, numbers, spaces, hyphens, and underscores" unless new_name.match?(/\A[a-zA-Z][a-zA-Z0-9 _-]*\z/)
  end

  def rename_module_in_files
    MODULE_FILES.each do |file|
      path = File.join(root, file)
      next unless File.exist?(path)

      content = File.read(path)
      new_content = content.gsub(APP_PLACEHOLDER, pascal_name)
      if content != new_content
        File.write(path, new_content)
        updated_files << file
      end
    end
  end

  def rename_snake_case_in_files
    SNAKE_CASE_FILES.each do |file|
      path = File.join(root, file)
      next unless File.exist?(path)

      content = File.read(path)
      new_content = content.gsub(DB_PLACEHOLDER, snake_name)
      new_content = new_content.gsub(DB_PLACEHOLDER.upcase, snake_name.upcase)
      if content != new_content
        File.write(path, new_content)
        updated_files << file
      end
    end
  end

  def rename_human_name_in_files
    HUMAN_NAME_FILES.each do |file|
      path = File.join(root, file)
      next unless File.exist?(path)

      content = File.read(path)
      new_content = content.gsub("Rails App Starter Kit", human_name)
      new_content = new_content.gsub(APP_PLACEHOLDER, pascal_name)
      if content != new_content
        File.write(path, new_content)
        updated_files << file
      end
    end
  end

  def rename_databases
    connection = ActiveRecord::Base.connection

    old_dev_db = "#{DB_PLACEHOLDER}_development"
    new_dev_db = "#{snake_name}_development"

    old_test_db = "#{DB_PLACEHOLDER}_test"
    new_test_db = "#{snake_name}_test"

    # Rename databases if they exist and names have changed
    if snake_name != DB_PLACEHOLDER
      [ [ old_dev_db, new_dev_db ], [ old_test_db, new_test_db ] ].each do |old_name, new_name_db|
        if database_exists?(connection, old_name)
          # Disconnect other sessions before renaming
          connection.execute("SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '#{old_name}' AND pid <> pg_backend_pid()")
          connection.execute("ALTER DATABASE \"#{old_name}\" RENAME TO \"#{new_name_db}\"")
        end
      end
    end
  rescue ActiveRecord::StatementInvalid => e
    # Database rename is best-effort — user can do it manually
    Rails.logger.warn("Could not rename database: #{e.message}")
  end

  def database_exists?(connection, name)
    result = connection.execute("SELECT 1 FROM pg_database WHERE datname = '#{name}'")
    result.any?
  end

  def updated_files
    @updated_files ||= []
  end

  def to_pascal_case(name)
    name.gsub(/[-_ ]+/, " ").split.map(&:capitalize).join
  end

  def to_snake_case(name)
    to_pascal_case(name)
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .downcase
  end

  def to_human_name(name)
    name.gsub(/[-_]+/, " ").gsub(/\b\w/, &:upcase)
  end
end
