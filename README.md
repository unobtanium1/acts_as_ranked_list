# ActsAsRankedList

This gem is based off of the [ActsAsList](https://github.com/brendon/acts_as_list) gem. It rewrites the gem using floating point position (or rank) for items. The benefit of using floating point ranks is the ability to insert an item inbetween items without updating the other items' positions.

Also supports having a(n) (float/integer) step between ranks that achieves the same thing. Can also use a step <1.0 to rank more items than is allowed by a database's max float/integer column restrictions.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add acts_as_ranked_list

or by adding `gem "acts_as_ranked_list"` to the Gemfile and running `bundle install`.

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install acts_as_ranked_list

## Usage

### Basic usage

This gem allows you to easily rank `::ActiveRecord` items without worrying about the underlying logic. After installing the gem, add the following `acts_as_ranked_list` to the `::ActiveRecord` model, for example:

```ruby
class MyModelName << ::ActiveRecord::Base
    acts_as_ranked_list
end
```

When you create a new `MyModelName` item, it will be ranked among the list of existing `MyModelName` items. You can increase/decrease the item's rank by the following methods:

```ruby
item_a = MyModelName.create!
item_a.increase_rank
item_a.decrease_rank
```

You can get the current rank of the item by the following:

```ruby
item_a = MyModelName.create! # is at the bottom of the list, highest rank item
item_b = MyModelName.create! # is at the bottom of the list, lowest rank item
item_a.current_rank # 1
item_b.current_rank # 2
```

Note that the list is viewed as ascending order of `rank, last updated at, id`. So `item_b` with rank 2 is lower in the list than `item_a` with rank 1.

You may get the highest items in the list sorted by rank by the following methods:

```ruby
my_existing_item = MyModelName.create! # placed top in the list
my_new_item = MyModelName.create! # placed bottom in the list
MyModelName.get_highest_items # ActiveRecord::Relation with results [my_existing_item, my_new_item]
```

You may get the highest/lowest item by specifying a number as the first argument to the `get_highest_items`/`get_lowest_items` methods, such as:

```ruby
my_existing_item = MyModelName.create! # placed top in the list
my_new_item = MyModelName.create! # placed bottom in the list
MyModelName.get_highest_items(1) # ActiveRecord::Relation with results [my_existing_item] # Note the result is an array
MyModelName.get_lowest_items(1) # ActiveRecord::Relation with results [my_new_item]
MyModelName.get_lowest_items(2) # ActiveRecord::Relation with results [my_new_item, my_existing_item] # Note the order of the returned results
MyModelName.get_highest_items(50000) # ActiveRecord::Relation with results [my_existing_item, my_new_item] # Note the number of requested results
```

### Advanced Usage

For the next examples, each will be initialized to the following:

```ruby
class TodoItem << ::ApplicationRecord
    # the rank column is named "priority" (without quotation marks) for this table
    # new items are added as highest priority
    acts_as_ranked_list column: "priority", adds_new_at: :highest, step_increment: 1.0
end

design_reusable_plastic_bag_graphic = TodoItem.create!(title: "Design the front and back graphic on the reusable plastic bag")
exercise = TodoItem.create!(title: "Run for 8 miles")
health_check = TodoItem.create!(title: "Drink lemon water")
print_on_shirt = TodoItem.create!(title: "Print a prototype design on the shrit to check quality")
# items and their priorities in ascending order: (the actual result is an array of the items, but the variable name and rank are shown here for simplicity)
#   [["print_on_shirt" ... , 0.125], ["health_check" ... , 0.25], ["exercise" ... , 0.5], ["design_reusable_plastic_bag_graphic" ... , 1.0]]
# the highest prioritised item is "print_on_shirt"
# the lowest prioritised item is "design_reusable_plastic_bag_graphic"
```

### Query position of current item

You can check if an item is the highest item or the lowest item in the list by using the `highest_item?` or `lowest_item?` instance methods.

```ruby
design_reusable_plastic_bag_graphic.lowest_item? # true
design_reusable_plastic_bag_graphic.highest_item? # false
print_on_shirt.highest_item? # true
```

#### Get higher or lower items

You can get the higher/lower items by using the instance methods `get_higher_items` or `get_lower_items`:

```ruby
exercise.get_higher_items # items and their priorities (note the order): [["health_check", 0.25], ["print_on_shirt", 0.125]]
```

You may pass in optional arguments to control how the results are returned. If the first argument is `0`, it will return all higher/lower items.

```ruby
design_reusable_plastic_bag_graphic.get_higher_items(2, "ASC") # [["health_check", 0.25], ["exercise", 0.5]]
```

#### Check if the current item is ranked

If the value of the rank column for the instance is `nil` then the item is not ranked. This item will still interact with the list when running queries such as `highest_item?` and so on. This item will be given a rank when [spreading ranks](spread-ranks).

```ruby
design_reusable_plastic_bag_graphic.is_ranked? # true
```

You may create a new item with nil rank as follows:

```ruby
## this persists the record, but skips callbacks
::TodoItem.with_skip_persistence { ::TodoItem.create!(rank: nil) }
```

#### Move rank relative to another item

Instead of updating rank one or down one position at a time, you can move above/below another item, using `set_rank_above` or `set_rank_below` instance methods:

```ruby
design_reusable_plastic_bag_graphic.set_rank_above(health_check)
```

This can be used together with the `get_highest_items(1)` class method to move item to the top of the list.

```ruby
design_reusable_plastic_bag_graphic.set_rank_above(TodoItem.get_highest_items(1).first)
```

#### Persistence and persistence callbacks

Each model with the `acts_as_ranked_list` has class methods to skip persistence to the database, and persistence callbacks.

Skipping persistence is useful if you want to mass update items, and persist once at the end. Persistence callbacks is useful for hooking into the life cycle of the updated item with regards to its rank, for example to send a webhook to all subscribers notifying them of an updated rank.

You can use the class method `with_skip_persistence` as follows:

```ruby
TodoItem.with_skip_persistence do
    design_reusable_plastic_bag_graphic.update(rank: 20.3)
    exercise.update(rank: 5.2)
    health_check.update(rank: 7.1)
    print_on_shirt.update(rank: 92.1)
end
::TodoItem.bulk_import!(
    [design_reusable_plastic_bag_graphic, exercise, health_check, print_on_shirt],
    on_duplicate_key_update: {
        conflict_target: [:id],
        columns: [:priority, :updated_at]
    }
) # uses the `activerecord_import` gem, or any other bulk update method to mass save changes to the database in 1 query
```

You may also pass in an array of classes to the `with_skip_persistence` method to skip persistence for these `::ActiveRecord` models which use the `acts_as_ranked_list` concern.

```ruby
TodoItem.with_skip_persistence([FootballTeam]) do # the calling class is added by default, in this case: `TodoItem`
    design_reusable_plastic_bag_graphic.increase_rank
    exercise.increase_rank
    health_check.set_rank_below(print_on_shirt)
    print_on_shirt.set_rank_below(design_reusable_plastic_bag_graphic)

    instance_of_other_model = FootballTeam.create(name: "MineerPul")
    instance_of_other_model.decrease_rank
end
::TodoItem.bulk_import!(
    [design_reusable_plastic_bag_graphic, exercise, health_check, print_on_shirt],
    on_duplicate_key_update: {
        conflict_target: [:id],
        columns: [:priority, :updated_at]
    }
) # uses the `activerecord_import` gem, or any other bulk update method to mass save changes to the database in 1 query

::FootballTeam.bulk_import!(
    [instance_of_other_model],
    on_duplicate_key_update: {
        conflict_target: [:id],
        columns: [:rank, :updated_at]
    }
)
```

#### Avoiding collisions

You can control whether to spread ranks or not on collisions by using the option `avoid_collisions: true` (by default) on using the concern in your `::ActiveRecord` model. You can change this setting on a per-block per-class basis by using the following class method:

```ruby
# disallows collisions
TodoItem.with_avoid_collisions(true) do # do spread ranks on collisions
    TodoItem.find(1).update(rank: 1)
    ... # you may update more than one record too
end # items with their new ranks [["health_check", 1.0], ["exercise", 2.0], ["print_on_shirt", 3.0], ["design_reusable_plastic_bag_graphic", 4.0]]
```

```ruby
# allows collisions
TodoItem.with_avoid_collisions(false) do # do not spread ranks on collisions
    TodoItem.find(1).update(rank: 1)
end # items with their new ranks [["health_check", 0.25], ["exercise", 0.5], ["print_on_shirt", 1.0], ["design_reusable_plastic_bag_graphic", 1.0]]
```

#### Spread ranks

You can spread ranks so that the difference between each rank and the next is set to the `step_increment`. This is useful for:

- Being able to rerank items again without overflowing column's max precision.
- Human-readable viewing purposes. This is not recommended. The rank should be human-readable (or not viewable) at the view (presentation) layer.

If `avoid_collisions = true (by default)`. Then you do not have to use spread ranks manually. If the database raises an overflow error when mutating a rank, then it could be time to recalibrate the ranks in the table. You should handle this case in your code, and spread ranks. This is very infrequent. For example, in postgres this error will be raised when using the default precision of `16_383` digits after the decimal of a `decimal` column type in postgres versions `9.1+`:

```ruby
ActiveRecord::RangeError: PG::NumericValueOutOfRange: ERROR:  value overflows numeric format
```

Items are spread in, ascending order of each, by:

1. rank
2. time updated columns (`updated_at` for example)
3. primary key (`id` for example)

To spread ranks:

```ruby
TodoItem.spread_ranks
TodoItem.get_highest_items # items with their new ranks [["print_on_shirt", 1.0], ["health_check", 2.0], ["exercise", 3.0], ["design_reusable_plastic_bag_graphic", 4.0]]
```

## Things to beware of

### Ranking more items in a databse than the max integer column

Imagine the scenario where you have 199 records to rank, and you must rank them in a `decision/numeric` column that allows 2 digits before the decimal point, and 2 digits after the decimal point. I.e the max number that can be stored is `99.99`.

If you use a `step_increment` of 1 you will be faced with a max float/integer overflow error by the database, as some of the ranks are more than 2 digits before the decimal point. You may use a decimal `step_increment` that is less than 1, and suitable for this scenario, and ranking will work as expected, without errors.

```ruby
class CrammedTodoItem << ::ActiveRecord::Base
    acts_as_ranked_list step_increment: 0.5
end

crammed_todo_items = []
CrammedTodoItem.with_skip_persistence do
    199.times { crammed_todo_items << CrammedTodoItem.create }
end

CrammedTodoItem.bulk_import!(crammed_todo_items) # persist 199 records in a mass insert method using gem `activerecord-import` or other method

CrammedTodoItem.spread_ranks # ensures every step is 0.5

CrammedTodoItem.get_highest_items.pluck(:rank) # [0.50 .. 99.50]
```

### Floating point precision and rounding, and max float/integer column overflow

Not all software can handle the precision handled by the database. The weakest link will cause issues to the entire flow of ranking items using floating-point precision. You may wish to convert to string and back to float if you need to. This **must** be done by the database layer as you'd have already lost precision if you let any other layer cast the values.

An alternative solution is to use a high `step_increment` to not get into rounding errors. This also brings its own problems of max integer overflow, but that is usually easier to plan in advance for, and does not fail silently. If you do this, it is best to use a large number that is a power of 2. This helps reduce the number of collisions as much as possible.

Some database services do not fail loudly and will persist a rounded or incorrect value altogether. You may set up an `::ActiveRecord` validation on the model to check for the precision before saving, and raise your own validation error, and handle recalibrating ranks.

### Performance

For best results, it is recommended to benchmark and compare with real life scenarios. Depending on your use case, different strategies may be faster. Using a large `step_increment` that's a power of 2 in an integer-based column (i.e no decimals) may be faster. The gem will continue to work as expected, but there may be more frequent collisions, which would be handled automatically but may slow down performance. So experiment and kindly share your learnings :pray:. You should also check other ruby gems that rank and sort `::ActiveRecord` models.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec ./spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

You may also run `yardoc` to build the docs locally. And `yard server` to serve the built docs.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Farbafe/acts_as_ranked_list.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
