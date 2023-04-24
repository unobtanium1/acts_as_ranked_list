# frozen_string_literal: true

module ActsAsRankedList #:nodoc:
  module ActiveRecord #:nodoc:
    module RankColumn
      # Sets the methods to rank `::ActiveRecord` objects. Please refer to 
      # the {file:README.md} file for usage and examples.
      def self.call(caller_class, rank_column, touch_on_update, step_increment, avoid_collisions, new_item_at, scopes)
        caller_class.class_eval do

          private

          define_singleton_method :scope_query do
            @scope_query ||= 
              begin
                @named_scopes = []
                scopes.map do |key, value|
                  case value
                  when ::Symbol
                    if respond_to?(value)
                      @named_scopes << value
                      next
                    end
                    "#{caller_class.quoted_table_name}.#{connection.quote_column_name(key)} = \"#{value}\""
                  when ::String, ::Integer, ::TrueClass, ::FalseClass, ::Float
                    "#{caller_class.quoted_table_name}.#{connection.quote_column_name(key)} = \"#{value}\""
                  when nil
                    casted_key = key.to_s
                    key_column_name = column_names.include?(casted_key) ? casted_key : "#{casted_key}_id"

                    @grouped_scopes ||= []
                    @grouped_scopes << key_column_name.to_sym
                    next
                  when ::Proc
                    called_value = value.call
                    if called_value.is_a?(::String)
                      next called_value
                    else
                      @anonymous_scopes ||= all
                      @anonymous_scopes.merge!(called_value)
                      next
                    end
                  end
                end.compact.join(" AND ") || "1 = 1"
              end
          end
          scope_query # initializes variables

          define_singleton_method :new_item_at do
            new_item_at
          end

          define_singleton_method :step_increment do
            step_increment
          end

          define_singleton_method :avoid_collisions= do |avoid_collisions_input|
            @avoid_collisions = avoid_collisions_input
          end
          @avoid_collisions = avoid_collisions

          define_singleton_method :avoid_collisions do
            @avoid_collisions
          end

          define_singleton_method :acts_as_ranked_list_query do
            @acts_as_ranked_list_query ||= 
              begin
                query = @named_scopes.inject(default_scoped.unscope(:select, :where).where("#{scope_query}")) do |chain, scope|
                  chain.send(*scope)
                end
                query.merge!(@anonymous_scopes) if @anonymous_scopes.present?
                @named_scopes = nil
                @anonymous_scopes = nil

                query
              end
          end

          define_singleton_method :quoted_rank_column do
            @_quoted_rank_column ||= connection.quote_column_name(rank_column)
          end

          define_singleton_method :quoted_rank_column_with_table_name do
            @_quoted_rank_column_with_table_name ||= "#{caller_class.quoted_table_name}.#{quoted_rank_column}"
          end

          define_singleton_method :order_by_columns do |order = "ASC"|
            @order_by_columns ||= {}
            @order_by_columns[order] ||= <<~ORDER_BY_COLUMNS.squish
              #{
                [ *@grouped_scopes,
                  quoted_rank_column,
                  *quoted_timestamp_attributes_for_update_in_model,
                  primary_key
                ].compact.join(" #{order}, ")
              } #{order}
            ORDER_BY_COLUMNS
          end

          define_singleton_method :spread_ranks do
            @spread_ranks_sql ||= 
              begin
                scope_query_presence = scope_query.present? ? "AND #{scope_query}" : ""
                <<~SQL.squish
                  WITH ORDERED_ROW_NUMBER_CTE AS (
                    SELECT #{caller_class.primary_key}, 
                      ROW_NUMBER() OVER (ORDER BY #{order_by_columns("ASC")}) AS rn
                    FROM #{caller_class.quoted_table_name}
                  )
                  UPDATE #{caller_class.quoted_table_name}
                  SET #{quoted_rank_column} = ORDERED_ROW_NUMBER_CTE.rn * #{step_increment} #{with_touch}
                  FROM ORDERED_ROW_NUMBER_CTE
                  WHERE #{caller_class.quoted_table_name}.#{caller_class.primary_key} = ORDERED_ROW_NUMBER_CTE.#{caller_class.primary_key}
                  AND #{quoted_rank_column_with_table_name} IS NOT NULL #{scope_query_presence}
                SQL
              end

            connection.execute(@spread_ranks_sql)
          end

          define_singleton_method :with_touch do
            touch_record if touch_on_update
          end

          define_singleton_method :quoted_timestamp_attributes_for_update_in_model do
            @_quoted_timestamp_attributes_for_update_in_model ||= timestamp_attributes_for_update_in_model.map do |attribute|
              connection.quote_column_name(attribute)
            end
          end

          define_singleton_method :touch_record do
            cached_quoted_now = quoted_current_time_from_proper_timezone

            quoted_timestamp_attributes_for_update_in_model.map do |attribute|
              ", #{attribute} = #{cached_quoted_now}"
            end.join
          end

          define_singleton_method :quoted_current_time_from_proper_timezone do
            connection.quote(connection.quoted_date(current_time_from_proper_timezone))
          end

          define_singleton_method :get_highest_items do |limit = 0|
            @get_highest_items_query ||= acts_as_ranked_list_query
              .where("#{quoted_rank_column} IS NOT NULL")
              .order(order_by_columns)

            return @get_highest_items_query if limit == 0

            @get_highest_items_query.limit(limit)
          end

          define_singleton_method :get_lowest_items do |limit = 0|
            @get_lowest_items_query ||= acts_as_ranked_list_query
              .where("#{quoted_rank_column} IS NOT NULL")
              .order(order_by_columns("DESC"))

            return @get_lowest_items_query if limit == 0

            @get_lowest_items_query.limit(limit)
          end
        end

        caller_class.class_eval do
          define_method :rank_column do
            rank_column
          end

          define_method :"#{rank_column}=" do |rank|
            self[rank_column] = rank
            @rank_changed = true
          end

          define_method :current_rank do
            self[rank_column]
          end

          define_method :rank_changed? do
            @rank_changed
          end

          define_method :is_ranked? do
            self[rank_column].present?
          end

          define_method :swap_rank_with do |item|
            temp_rank = current_rank
            with_persistence([self, item]) do
              self[rank_column] = item.current_rank
              item[rank_column] = temp_rank
            end
          end

          define_method :set_rank_between do |item_a, item_b|
            set_rank_below(item_a)
          end

          define_method :set_rank_above do |item|
            higher_items = get_higher_items(2, "DESC", item.current_rank, true, true)
            padded_array = pad_array(higher_items.pluck(rank_column), 0)
            new_rank = padded_array.sum / 2

            with_persistence do
              self[rank_column] = new_rank
            end
          end

          define_method :set_rank_below do |item|
            # effectively the same as, without the padding of arrays
            # sql = <<~SQL.squish
            #   with CTE AS (
            #     SELECT DISTINCT #{self.class.quoted_rank_column_with_table_name} AS dis
            #     FROM #{caller_class.quoted_table_name}
            #     WHERE (#{self.class.quoted_rank_column_with_table_name} >= #{item.current_rank}::numeric)
            #     GROUP BY #{self.class.quoted_rank_column_with_table_name}
            #     ORDER BY #{self.class.quoted_rank_column_with_table_name}
            #     LIMIT 2
            #   )
            #   SELECT AVG(CTE.dis)
            #   FROM CTE
            # SQL
            # new_rank = ::ActiveRecord::Base.connection.execute(sql).to_a.first.values.first

            lower_items = get_lower_items(2, "ASC", item.current_rank, true, true)
            padded_array = pad_array(lower_items.pluck(rank_column))
            new_rank = padded_array.sum / 2

            with_persistence do
              self[rank_column] = new_rank
            end
          end

          define_method :increase_rank do |count = 1|
            higher_items = get_higher_items(count + 1, "DESC")
            return if higher_items.blank?

            padded_array = pad_array(higher_items.pluck(rank_column), 0)
            new_rank = padded_array.sum / 2

            with_persistence do
              self[rank_column] = new_rank
            end
          end

          define_method :decrease_rank do |count = 1|
            lower_items = get_lower_items(count + 1, "ASC")
            return if lower_items.blank?

            padded_array = pad_array(lower_items.pluck(rank_column))
            new_rank = padded_array.sum / 2

            with_persistence do
              self[rank_column] = new_rank
            end
          end

          define_method :get_higher_items do |limit = 0, order = "DESC", rank = nil, distinct = false, include_self_rank = false|
            return if current_rank.nil?

            operator = include_self_rank ? "<=" : "<"
            rank ||= current_rank

            query = self.class.acts_as_ranked_list_query
              .where("#{self.class.quoted_rank_column} #{operator} #{rank}")

            self.class.instance_variable_get(:@grouped_scopes)&.each do |grouped_scope|
              query = query.where(grouped_scope => self.send(grouped_scope))
            end

            query = query.order(self.class.order_by_columns(order))

            query = query.distinct(self.class.quoted_rank_column) if distinct

            return query if limit == 0

            query.limit(limit)
          end

          define_method :get_lower_items do |limit = 0, order = "ASC", rank = nil, distinct = false, include_self_rank = false|
            return if current_rank.nil?

            operator = include_self_rank ? ">=" : ">"
            rank ||= current_rank

            query = self.class.acts_as_ranked_list_query
              .where("#{self.class.quoted_rank_column} #{operator} #{rank}")

            self.class.instance_variable_get(:@grouped_scopes)&.each do |grouped_scope|
              query = query.where(grouped_scope => self.send(grouped_scope))
            end

            query = query.order(self.class.order_by_columns(order))

            query = query.distinct(self.class.quoted_rank_column) if distinct

            return query if limit == 0

            query.limit(limit)
          end

          define_method :highest_item? do
            !get_higher_items.exists?
          end

          define_method :lowest_item? do
            !get_lower_items.exists?
          end

          private

          define_method :with_persistence do |items = [self], &blk|
            blk.call

            items.each(&:save!) unless skip_persistence?
          end

          define_method :pad_array do |array, value = nil, size = 2|
            current_array_value = array[0] || self.class.step_increment
            value ||= current_array_value + self.class.step_increment
            array + ::Array.new(size - array.size, value)
          end
        end
      end
    end
  end
end
