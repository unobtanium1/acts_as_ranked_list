# frozen_string_literal: true

module ActsAsRankedList #:nodoc:
  module ActiveRecord #:nodoc:
    module PersistenceCallback
      # @!method ranked_list_before_validation_callback
      #   Callback on `::ActiveRecord` before validation. Skipped with {SkipPersistence}
      #   @!scope class
      #   @since 0.2.0

      # @!method ranked_list_before_destroy_callback
      #   Callback on `::ActiveRecord` before destroy. Skipped with {SkipPersistence}
      #   @!scope class
      #   @since 0.2.0

      # @!method ranked_list_after_destroy_callback
      #   Callback on `::ActiveRecord` after destroy. Skipped with {SkipPersistence}
      #   @!scope class
      #   @since 0.2.0

      # @!method ranked_list_before_update_callback
      #   Callback on `::ActiveRecord` before update. Skipped with {SkipPersistence}
      #   @!scope class
      #   @since 0.2.0

      # @!method ranked_list_after_update_callback
      #   Callback on `::ActiveRecord` after update. Skipped with {SkipPersistence}
      #   @!scope class
      #   @since 0.2.0

      # @!method ranked_list_after_save_callback
      #   Callback on `::ActiveRecord` after save.
      #   @!scope class
      #   @since 0.2.0

      # @!method ranked_list_before_create_callback
      #   Callback on `::ActiveRecord` before create. Skipped with {SkipPersistence}.
      #   @!scope class
      #   @since 0.2.0

      # Sets the callback handlers for {ActsAsRankedList}. Used internally.
      # You may use the callback methods if you want to add your handlers.
      # Call super at the end of your callback handlers. Do **not** update records
      # within an update callback.
      def self.call(caller_class)
        caller_class.class_eval do
          before_validation :ranked_list_before_validation_callback, unless: :skip_persistence?

          before_destroy :ranked_list_before_destroy_callback, unless: :skip_persistence?
          after_destroy :ranked_list_after_destroy_callback, unless: :skip_persistence?

          before_update :ranked_list_before_update_callback, unless: :skip_persistence?
          after_update :ranked_list_after_update_callback, unless: :skip_persistence?

          after_save :ranked_list_after_save_callback

          before_create :ranked_list_before_create_callback, unless: :skip_persistence?
        end
      end
    end
  end
end
