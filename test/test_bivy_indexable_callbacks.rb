# frozen_string_literal: true

require "test_helper"
require "active_record"

class TestBivyIndexableCallbacks < Minitest::Test
  include IndexableTestHelper

  def test_including_indexable_adds_after_save_commit_callback
    model_class = create_test_model("HikingBoot") do
      include Bivy::Indexable
    end

    callbacks = model_class._commit_callbacks.select { |cb| cb.kind == :after && cb.filter == Bivy::Callbacks::AfterSaveCommit }
    assert callbacks.any?, "Should have AfterSaveCommit callback when Bivy::Indexable is included"
  end

  def test_including_indexable_adds_after_destroy_commit_callback
    model_class = create_test_model("WaterBottle") do
      include Bivy::Indexable
    end

    callbacks = model_class._commit_callbacks.select { |cb| cb.kind == :after && cb.filter == Bivy::Callbacks::AfterDestroyCommit }
    assert callbacks.any?, "Should have AfterDestroyCommit callback when Bivy::Indexable is included"
  end

  def test_model_without_indexable_has_no_bivy_callbacks
    model_without_indexable = create_test_model("RainJacket")

    # Should have no commit callbacks at all for a basic model
    callbacks = model_without_indexable._commit_callbacks
    assert callbacks.empty?, "Model without Bivy::Indexable should not have any commit callbacks"
  end

  def test_indexable_uses_callback_classes_for_commits
    model_class = create_test_model("CampingChair") do
      include Bivy::Indexable
    end

    # Check that callbacks are using callback classes
    callbacks = model_class._commit_callbacks
    save_callback = callbacks.find { |cb| cb.kind == :after && cb.filter == Bivy::Callbacks::AfterSaveCommit }
    destroy_callback = callbacks.find { |cb| cb.kind == :after && cb.filter == Bivy::Callbacks::AfterDestroyCommit }

    assert save_callback, "Should have AfterSaveCommit callback"
    assert destroy_callback, "Should have AfterDestroyCommit callback"
  end

  def test_after_save_commit_callback_class_exists
    assert defined?(Bivy::Callbacks::AfterSaveCommit), "Bivy::Callbacks::AfterSaveCommit class should be defined"
  end

  def test_after_destroy_commit_callback_class_exists
    assert defined?(Bivy::Callbacks::AfterDestroyCommit), "Bivy::Callbacks::AfterDestroyCommit class should be defined"
  end

  def test_after_save_commit_callback_class_is_callable
    assert_respond_to Bivy::Callbacks::AfterSaveCommit, :after_commit, "AfterSaveCommit should respond to after_commit class method"
  end

  def test_after_destroy_commit_callback_class_is_callable
    assert_respond_to Bivy::Callbacks::AfterDestroyCommit, :after_commit, "AfterDestroyCommit should respond to after_commit class method"
  end

  def test_after_save_commit_callback_receives_model_instance
    model_class = create_test_model("GPS") do
      include Bivy::Indexable
    end

    instance = model_class.new(name: "Test GPS")

    # The callback class method should accept the model instance as a parameter
    begin
      Bivy::Callbacks::AfterSaveCommit.after_commit(instance)
      assert true, "Callback should accept model instance without raising"
    rescue => e
      flunk "Callback raised an error: #{e.message}"
    end
  end

  def test_after_destroy_commit_callback_receives_model_instance
    model_class = create_test_model("FirstAidKit") do
      include Bivy::Indexable
    end

    instance = model_class.new(name: "Test First Aid Kit")

    # The callback class method should accept the model instance as a parameter
    begin
      Bivy::Callbacks::AfterDestroyCommit.after_commit(instance)
      assert true, "Callback should accept model instance without raising"
    rescue => e
      flunk "Callback raised an error: #{e.message}"
    end
  end

  def test_indexable_uses_callback_classes_instead_of_methods
    model_class = create_test_model("FireStarter") do
      include Bivy::Indexable
    end

    # Should not have the old instance methods, and should use callback classes
    instance = model_class.new
    refute_respond_to instance, :bivy_after_save_commit,
      "Should not have bivy_after_save_commit instance method when using callback classes"
    refute_respond_to instance, :bivy_after_destroy_commit,
      "Should not have bivy_after_destroy_commit instance method when using callback classes"

    # Should have the callback classes registered
    callbacks = model_class._commit_callbacks
    assert callbacks.any? { |cb| cb.filter == Bivy::Callbacks::AfterSaveCommit },
      "Should have AfterSaveCommit callback registered"
    assert callbacks.any? { |cb| cb.filter == Bivy::Callbacks::AfterDestroyCommit },
      "Should have AfterDestroyCommit callback registered"
  end

  def test_after_save_commit_enqueues_record_job
    # Verify that the callback calls RecordJob.perform_later
    model_class = create_test_model("AlpineStove") do
      include Bivy::Indexable
    end

    instance = model_class.new(name: "Test Stove")

    # Mock the job to verify it gets called
    job_mock = Minitest::Mock.new
    job_mock.expect :call, nil, [instance, :bivy_save]

    Bivy::Jobs::RecordJob.stub :perform_later, job_mock do
      instance.save!
    end

    job_mock.verify
  end

  def test_after_destroy_commit_enqueues_record_job
    fake_index = Class.new

    # Verify that the callback calls RecordJob.perform_later
    model_class = create_test_model("WalkingStick") do
      include Bivy::Indexable

      bivy_index_in fake_index
    end

    instance = model_class.new(name: "Test Walking Stick")

    # Mock the job to verify it gets called for both save and destroy
    job_calls = []
    job_mock = ->(record, action) { job_calls << action }

    Bivy::Jobs::RecordJob.stub :perform_later, job_mock do
      instance.save!
      instance.destroy!
    end

    assert_equal 2, job_calls.size, "Should call RecordJob.perform_later twice (save and destroy)"
    assert_equal :bivy_save, job_calls[0], "First call should be for save"
    assert_equal :bivy_destroy, job_calls[1], "Second call should be for destroy"
  end
end
