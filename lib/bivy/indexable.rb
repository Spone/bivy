# frozen_string_literal: true

require "active_support/concern"
require "set"

module Bivy
  module Indexable
    extend ActiveSupport::Concern

    class << self
      def models
        @models ||= Set.new
      end

      def add_model(klass)
        models << klass
      end
    end

    included do
      # When this concern is included in a class, add it to the tracked models
      Indexable.add_model(self)

      # Add callbacks for indexing operations using callback classes
      after_save_commit Bivy::Callbacks::AfterSaveCommit
      after_destroy_commit Bivy::Callbacks::AfterDestroyCommit

      @bivy_indexes ||= []
      @bivy_conditions ||= {}
      @bivy_serializers ||= {}
    end

    class_methods do
      attr_reader :bivy_conditions
      attr_reader :bivy_serializers

      def bivy_index_in(indexes, **opts)
        Array.wrap(indexes).each do |index|
          @bivy_indexes << index
          @bivy_conditions[index.to_s] = opts[:if] unless opts[:if].nil?
          @bivy_serializers[index.to_s] = opts[:serializer] unless opts[:serializer].nil?
        end
      end

      def for_each_bivy_index(&block)
        @bivy_indexes.each(&block)
      end

      def bivy_model_name
        model_name
      end
    end

    delegate :for_each_bivy_index,
      :bivy_serializers,
      :bivy_model_name,
      to: :class

    def bivy_model_id
      id
    end

    def bivy_object_tid
      "#{bivy_model_name}##{bivy_model_id}"
    end

    def bivy_object_id(fraction = nil)
      "#{bivy_object_tid}#{"/#{fraction}" if fraction}"
    end

    def bivy_indexable?
      true
    end

    def bivy_object(index: nil)
      if bivy_serializers.key?(index.to_s)
        serializer = bivy_serializers[index.to_s].new(self)
        attrs = serializer.records if serializer.respond_to?(:records)
        attrs ||= serializer.record
      end
      attrs ||= bivy_attributes if respond_to?(:bivy_attributes)
      attrs ||= attributes

      if attrs.is_a?(Array)
        attrs.map.with_index do |attr, i|
          attr.merge(
            objectID: bivy_object_id(i),
            model_name: bivy_model_name,
            model_id: bivy_model_id
          )
        end
      else
        attrs.merge(
          objectID: bivy_object_id,
          model_name: bivy_model_name,
          model_id: bivy_model_id
        )
      end
    end

    def bivy_save
      bivy_destroy

      for_each_bivy_index do |index|
        condition = self.class.bivy_conditions[index.to_s]

        if bivy_indexable? && (condition.nil? || condition&.call(self))
          objects = Array.wrap(bivy_object(index: index))
          index.save_objects!(objects) unless objects.empty?
        end
      end
    end

    def bivy_destroy
      for_each_bivy_index do |index|
        records_to_delete = index.browse_objects(bivy_destroy_browse_params).pluck(:objectID)
        index.delete_objects!(records_to_delete) unless records_to_delete.empty?
      end
    end

    def bivy_destroy_later
      for_each_bivy_index do |index|
        Bivy::Jobs::IndexJob.perform_later(
          index.to_s,
          :browse_and_delete_objects!,
          params: bivy_destroy_browse_params
        )
      end
    end

    private

    def bivy_destroy_filters
      "model_name:'#{bivy_model_name}' AND model_id:#{bivy_model_id}"
    end

    def bivy_destroy_browse_params
      {
        filters: bivy_destroy_filters,
        attributesToRetrieve: %w[objectID],
        responseFields: %w[hits]
      }
    end
  end
end
