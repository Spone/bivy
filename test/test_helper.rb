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
