def connect_to_databse
  ::ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
end

def initialize_schema
  ::ActiveRecord::Schema.define do
    create_table :todo_lists do |t|
      t.string :title
    end

    create_table :todo_items do |t|
      t.string :title
      t.decimal :rank
      t.string :scope_string
      t.boolean :scope_boolean
      t.integer :scope_integer
      t.references :todo_list

      t.timestamps
    end

    create_table :non_default_todo_items do |t|
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

class TodoList < ::ActiveRecord::Base
  has_many :todo_items
end

class TodoItem < ::ActiveRecord::Base
  abstract_class

  belongs_to :todo_list
end

class DefaultTodoItem < TodoItem
  acts_as_ranked_list
end

class UnrankedTodoItem < TodoItem
  acts_as_ranked_list new_item_at: :unranked
end

class ScopedIntegerTodoItem < TodoItem
  acts_as_ranked_list scopes: { scope_integer: 0 }
end

class ScopedStringTodoItem < TodoItem
  acts_as_ranked_list scopes: { scope_string: "work" }
end

class ScopedStringPersonalTodoItem < TodoItem
  acts_as_ranked_list scopes: { scope_string: "personal" }
end

class ScopedStringViaSymbolTodoItem < TodoItem
  acts_as_ranked_list scopes: { scope_string: :work }
end

class ScopedBooleanTodoItem < TodoItem
  acts_as_ranked_list scopes: { scope_boolean: true }
end

class ScopedMultipleTodoItem < TodoItem
  enum scope_integer: {
    monday: 0,
    tuesday: 1
  }
  before_create :initialize_values
  acts_as_ranked_list scopes: { scope_string: :gardening, scope_integer: nil }

  def initialize_values
    self.scope_string ||= :gardening
    self.scope_integer ||= :monday
  end
end

class ScopedListTodoItem < TodoItem
  acts_as_ranked_list scopes: { todo_list: nil }
end

class NonDefaultTodoItem < ::ActiveRecord::Base
  acts_as_ranked_list column: "position", step_increment: 128, new_item_at: :highest
end

class InvalidColumnNameTodoItem < ::ActiveRecord::Base
  acts_as_ranked_list
end

class InvalidColumnTypeTodoItem < ::ActiveRecord::Base
  acts_as_ranked_list
end
