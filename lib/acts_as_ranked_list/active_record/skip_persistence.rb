# frozen_string_literal: true

module ActsAsRankedList #:nodoc:
  module ActiveRecord #:nodoc:
    module SkipPersistence # Refer to {SkipPersistence::ClassMethods} for docs.

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Pass a block to this method to prevent persisting `::ActiveRecord` updates and 
        # callbacks. You may pass an array of classes to prevent persisting. These
        # `::ActiveRecord` models _must_ include the `acts_as_ranked_list` concern.
        #
        # @example with an `::ActiveRecord` model of the name `TodoItem`:
        #   TodoItem.with_skip_persistence { TodoItem.find(4).increase_rank }
        # @since 0.2.0
        # @scope class
        # @param [Array<Class>] klasses array of klasses to prevent persisting
        # @yield the block to execute with changes to the instances
        # @raise [ArgumentError] raised if optional klasses argument is not an array of
        #   `::ActiveRecord` objects 
        # @return [void]
        def with_skip_persistence(klasses = [], &blk)
          raise ::ArgumentError unless klasses.is_a?(Array)

          klasses << self

          raise ::ArgumentError unless active_record_objects?(klasses)

          SkipPersistence.with_applied_klasses(klasses) do
            yield
          end
        end

        private

        def active_record_objects?(klasses)
          klasses.all? { |klass| klass.ancestors.include?(::ActiveRecord::Base) }
        end
      end

      class << self
        def with_applied_klasses(klasses, &blk)
          klasses.map {|klass| add_klass(klass)}
          yield
        ensure
          klasses.map {|klass| remove_klass(klass)}
        end

        def applied_to?(klass)
          !(klass.ancestors & extracted_klasses.keys).empty?
        end

        private

        def extracted_klasses
          ::Thread.current[:acts_as_ranked_list_skip_persistence] ||= {}
        end

        def add_klass(klass)
          extracted_klasses[klass] = 0 unless extracted_klasses.key?(klass)
          extracted_klasses[klass] += 1
        end

        def remove_klass(klass)
          extracted_klasses[klass] -= 1
          extracted_klasses.delete(klass) if extracted_klasses[klass] <= 0
        end
      end

      private

      def skip_persistence?
        SkipPersistence.applied_to?(self.class)
      end
    end
  end
end
