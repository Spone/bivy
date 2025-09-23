# frozen_string_literal: true

require "active_support/concern"
require "set"

module Bivy
  module Indexable
    extend ActiveSupport::Concern

    included do
      # When this concern is included in a class, add it to the tracked models
      Indexable.add_model(self)

      # Add callbacks for indexing operations using callback classes
      after_save_commit Bivy::Callbacks::AfterSaveCommit
      after_destroy_commit Bivy::Callbacks::AfterDestroyCommit
    end

    class << self
      def models
        @models ||= Set.new
      end

      def add_model(klass)
        models << klass
      end
    end
  end
end
