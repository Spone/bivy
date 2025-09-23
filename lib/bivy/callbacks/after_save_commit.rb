# frozen_string_literal: true

module Bivy
  module Callbacks
    class AfterSaveCommit
      def self.after_commit(model)
        # Default implementation - override in subclasses or configure per model
        # This is where indexing logic for saves would go
      end
    end
  end
end
