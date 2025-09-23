# frozen_string_literal: true

require "test_helper"
require "active_record"

class TestBivyIndexable < Minitest::Test
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

  def test_bivy_indexable_concern_exists
    assert defined?(Bivy::Indexable), "Bivy::Indexable concern should be defined"
  end

  def test_can_include_bivy_indexable_in_activerecord_model
    model_class = create_test_model("Tent") do
      include Bivy::Indexable
    end

    assert model_class.ancestors.include?(Bivy::Indexable),
      "ActiveRecord model should be able to include Bivy::Indexable"
  end

  def test_bivy_indexable_models_returns_set
    result = Bivy::Indexable.models
    assert_instance_of Set, result, "Bivy::Indexable.models should return a Set"
  end

  def test_bivy_indexable_models_starts_empty
    result = Bivy::Indexable.models
    assert result.empty?, "Bivy::Indexable.models should start with an empty set"
  end

  def test_single_model_with_indexable_is_tracked
    model_class = create_test_model("Backpack") do
      include Bivy::Indexable
    end

    indexable_models = Bivy::Indexable.models
    assert indexable_models.include?(model_class),
      "Model with Bivy::Indexable should be tracked in indexable_models"
    assert_equal 1, indexable_models.size,
      "Should have exactly one indexable model"
  end

  def test_multiple_models_with_indexable_are_tracked
    model1 = create_test_model("SleepingBag") do
      include Bivy::Indexable
    end

    model2 = create_test_model("Compass") do
      include Bivy::Indexable
    end

    indexable_models = Bivy::Indexable.models
    assert indexable_models.include?(model1), "First model should be tracked"
    assert indexable_models.include?(model2), "Second model should be tracked"
    assert_equal 2, indexable_models.size, "Should have exactly two indexable models"
  end

  def test_models_without_indexable_are_not_tracked
    model_without_indexable = create_test_model("Flashlight")

    model_with_indexable = create_test_model("Campfire") do
      include Bivy::Indexable
    end

    indexable_models = Bivy::Indexable.models
    refute indexable_models.include?(model_without_indexable),
      "Model without Bivy::Indexable should not be tracked"
    assert indexable_models.include?(model_with_indexable),
      "Model with Bivy::Indexable should be tracked"
    assert_equal 1, indexable_models.size,
      "Should have exactly one indexable model"
  end

  def test_indexable_models_returns_same_set_instance
    set1 = Bivy::Indexable.models
    set2 = Bivy::Indexable.models
    assert_same set1, set2, "Should return the same Set instance on multiple calls"
  end

  def test_indexable_models_persists_across_calls
    model_class = create_test_model("Trail") do
      include Bivy::Indexable
    end

    first_call = Bivy::Indexable.models
    second_call = Bivy::Indexable.models

    assert first_call.include?(model_class), "First call should include the model"
    assert second_call.include?(model_class), "Second call should still include the model"
  end

  private

  def create_test_model(name, &block)
    # Create a new ActiveRecord model class for testing
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "campgrounds"
      class_eval(&block) if block_given?
    end

    # Assign it to a constant so it has a name
    Object.const_set(name, model_class)
    @test_models << name

    model_class
  end
end
