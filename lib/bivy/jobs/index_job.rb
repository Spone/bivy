# frozen_string_literal: true

module Bivy
  module Jobs
    class IndexJob < Bivy::Jobs::BaseJob
      def perform(index, method, params = {})
        index.constantize.send(method, params)
      end
    end
  end
end
