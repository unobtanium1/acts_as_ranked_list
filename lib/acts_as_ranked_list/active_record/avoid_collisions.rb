# frozen_string_literal: true

module ActsAsRankedList #:nodoc:
  module ActiveRecord #:nodoc:
    module AvoidCollisions # Refer to {AvoidCollisions::ClassMethods} for docs.

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Pass a block to this method to avoid collisions to an `::ActiveRecord`
        # model's table. You may pass a boolean argument to change the behaviour.
        #
        # @example with an `::ActiveRecord` model of the name `TodoItem`:
        #   TodoItem.with_avoid_collisions do
        #     TodoItem.find(4).update(rank: 200)
        #     TodoItem.find(5).update(rank: 200)
        #   end
        # @since 0.2.0
        # @scope class
        # @param [Array<Class>] avoid_collisions argument to avoid or allow collisions
        # @yield the block to execute with changes to the instances
        # @return [void]
        def with_avoid_collisions(avoid_collisions = true, &blk)
          AvoidCollisions.with_applied_klasses(self, avoid_collisions) do
            yield
          end
        end

        private

        def active_record_objects?(klasses)
          klasses.all? { |klass| klass.ancestors.include?(::ActiveRecord::Base) }
        end
      end

      class << self
        def with_applied_klasses(caller_class, avoid_collisions, &blk)
          original_avoid_collisions = caller_class.avoid_collisions
          caller_class.avoid_collisions = avoid_collisions
          yield
        ensure
          caller_class.avoid_collisions = original_avoid_collisions
        end

        def applied_to?(klass)
          klass.avoid_collisions
        end
      end

      private

      def avoid_collisions?
        AvoidCollisions.applied_to?(self.class)
      end
    end
  end
end
