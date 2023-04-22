def connect_to_databse
  ::ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
end

def initialize_schema
  ::ActiveRecord::Schema.define do
    create_table :todo_items do |t|
      t.string :title
      t.decimal :rank

      t.timestamps
    end

    create_table :advanced_todo_items do |t|
      t.string :title
      t.integer :position

      t.timestamps
    end

    create_table :invalid_column_name_todo_items do |t|
      t.string :title
      t.integer :position

      t.timestamps
    end

    create_table :invalid_column_type_todo_items do |t|
      t.string :title
      t.string :rank

      t.timestamps
    end
  end
end

connect_to_databse

initialize_schema

class TodoItem < ::ActiveRecord::Base
  abstract_class
end

class DefaultTodoItem < TodoItem
  acts_as_ranked_list
end

class UnrankedTodoItem < TodoItem
  acts_as_ranked_list new_item_at: :unranked
end

class AdvancedTodoItem < ::ActiveRecord::Base
  acts_as_ranked_list column: "position", step_increment: 128, new_item_at: :highest
end

class InvalidColumnNameTodoItem < ::ActiveRecord::Base
  acts_as_ranked_list
end

class InvalidColumnTypeTodoItem < ::ActiveRecord::Base
  acts_as_ranked_list
end
