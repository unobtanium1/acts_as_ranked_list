# frozen_string_literal: true

module ActsAsRankedList
  module ActiveRecord #:nodoc:
    module Service

      # Add `acts_as_ranked_list` to an `::ActiveRecord` model to use this gem.
      # Please refer to the {file:README.md} for complete usage and examples.
      #
      # @example with an `::ActiveRecord` model of the name `TodoItem`. Works when inheriting from `::ApplicationRecord`.
      #   class TodoItem << ::ActiveRecord::Base
      #     acts_as_ranked_list
      #   end
      #
      # @example when changing default options
      #   class TodoItem << ::ActiveRecord::Base
      #     acts_as_ranked_list column: "position", touch_on_update: false, step_increment: 0.5, avoid_collisions: false, new_item_at: :highest
      #   end
      #
      # @example when using scope 
      #   class TodoItem << ::ActiveRecord::Base
      #     belongs_to :todo_list
      #     scope :recently_added, -> { where(created_at: ::Time.now - 12.hours..) }
      #     acts_as_ranked_list scopes: do # you may use as many scopes together
      #       column_name_one: "work", # items that have value `work` in column `column_name_one` are scoped together
      #       column_name_two: :personal, # using a symbol is overloaded, check parameters and example for more info
      #       column_name_three: 0, # this could be used to sub-rank items within a rank
      #       column_name_four: true,
      #       column_name_five: :recently_added, # ranks items within the `recently_added` scope
      #       column_name_six: ::Proc.new { "column_name = 'value'" }, # useful for complex scopes, you may pass any valid SQL scopes
      #       column_name_seven: ::Proc.new { where(column_name: value) }, # anonymous scopes
      #       todo_list(_id): nil # ranks items scoped to their respective todo lists, works with or without `(_id)`
      #     end
      #   end
      #
      # @since 0.2.0
      # @scope class
      # @param [Hash] user_options options
      # @option user_options [String] :column The column name to use for ranking
      # @option user_options [Boolean] :touch_on_update Controls updating table's columns
      #   updated fields on any write operation
      # @option user_options [Float/Integer] :step_increment The value to use for spreading ranks
      # @option user_options [Boolean] :avoid_collisions Controls avoiding rank collisions
      # @option user_options [Symbol] :new_item_at Controls where to add new items
      # @option user_options [Hash] :scopes Scopes ranked items based on a column, and optional value
      #   * :any_key [String/Integer/Boolean/Float] Uses passed value in column <any_key> to scope items
      #   * :any_key [Symbol] Uses passed value in column <any_key> to scope items, or a named scope
      #   * :any_key [Proc] Calls passed block's value in column <any_key> to scope items, or an anonymous scope
      #   * :any_key [NilClass] Scopes items to a relationship, by querying non-nil values in column <any_key> or <any_key_id>
      # @return [void]
      def acts_as_ranked_list(user_options = {})
        options = {
          column: "rank",
          touch_on_update: true,
          step_increment: 1024,
          avoid_collisions: true,
          new_item_at: :lowest,
          scopes: {}
        }
        options.update(user_options)

        ::ActsAsRankedList::ActiveRecord::PersistenceCallback.call(self)
        ::ActsAsRankedList::ActiveRecord::RankColumn.call(self, options[:column], options[:touch_on_update], options[:step_increment], options[:avoid_collisions], options[:new_item_at], options[:scopes])

        include ::ActsAsRankedList::ActiveRecord::Service::InstanceMethods
        include ::ActsAsRankedList::ActiveRecord::SkipPersistence
        include ::ActsAsRankedList::ActiveRecord::AvoidCollisions
      end

      module InstanceMethods
        def ranked_list_before_validation_callback
          nil
        end

        def ranked_list_before_destroy_callback
          nil
        end

        def ranked_list_after_destroy_callback
          nil
        end

        def ranked_list_before_update_callback
          update_ranks
        end

        def ranked_list_after_update_callback
          nil
        end

        def ranked_list_after_save_callback
          @rank_changed = nil
        end

        def ranked_list_before_create_callback
          set_new_item_rank
          update_ranks
        end

        private

        def update_ranks
          return unless avoid_collisions?

          return if rank_changed? == false

          return unless current_rank

          query_count = self.class.acts_as_ranked_list_query
            .where("#{self.class.quoted_rank_column_with_table_name} = #{current_rank}")

          self.class.instance_variable_get(:@grouped_scopes)&.each do |grouped_scope|
            query_count = query_count.where(grouped_scope => self.send(grouped_scope))
          end

          query_count = query_count.count

          if query_count < 1
            return
          end

          self.class.with_skip_persistence do
            self.class.spread_ranks
          end
        end

        def set_new_item_rank
          return if current_rank.present?

          case self.class.new_item_at
          when :highest
            highest_item_rank = self.class.get_highest_items(1).first&.current_rank || self.class.step_increment
            self[rank_column] = [highest_item_rank, 0].sum / 2
          when :lowest
            lowest_item_rank = self.class.get_lowest_items(1).first&.current_rank || self.class.step_increment
            self[rank_column] = [lowest_item_rank, lowest_item_rank + self.class.step_increment].sum / 2
          end
        end
      end
    end
  end
end
