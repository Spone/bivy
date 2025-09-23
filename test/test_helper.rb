# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "bivy"

require "minitest/autorun"
require "active_record"

# Set up an in-memory SQLite database for testing
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Create a dummy table for our test models
ActiveRecord::Schema.define do
  create_table :campgrounds do |t|
    t.string :name
    t.timestamps
  end
end

# Shared helper module for Bivy::Indexable tests
module IndexableTestHelper
  def setup
    # Clear any previously tracked indexable models
    Bivy::Indexable.instance_variable_set(:@models, Set.new) if Bivy::Indexable.instance_variable_defined?(:@models)

    # Define test models for each test to avoid conflicts
    @test_models = []
  end

  def teardown
    # Clean up any test models created during tests
    @test_models.each do |model_name|
      Object.send(:remove_const, model_name) if Object.const_defined?(model_name)
    end
  end

  private

  def create_test_model(name, &block)
    # Create a new ActiveRecord model class for testing
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "campgrounds" # Camping-themed table name
      class_eval(&block) if block_given?
    end

    # Assign it to a constant so it has a name
    Object.const_set(name, model_class)
    @test_models << name

    model_class
  end
end
