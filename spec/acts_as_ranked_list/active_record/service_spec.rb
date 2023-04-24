# frozen_string_literal: true

::RSpec.describe ::ActsAsRankedList::ActiveRecord::Service do
  describe "#current_rank" do
    context "when using a decimal column called rank" do
      let(:todo_item) { ::DefaultTodoItem.create!(title: "title", rank: 20) }

      it "gets the current rank" do
        expect(todo_item.current_rank).to eq(20.0)
      end
    end

    context "when using an integer column not called rank" do
      let(:non_default_todo_item) { ::NonDefaultTodoItem.create!(title: "advanced title", position: 20) }

      it "gets the current rank" do
        expect(non_default_todo_item.current_rank).to eq(20)
      end
    end
  end

  describe ".create!" do
    context "when called and not passing in arguments" do
      let(:todo_item) { ::DefaultTodoItem.create! }

      it "creates a new record using defaults" do
        expect(todo_item.current_rank).not_to be_nil
      end
    end

    context "when called and passing in arguments" do
      let(:todo_item) { ::DefaultTodoItem.create!(rank: nil) }

      it "creates a new record using passed in arguments" do
        expect(todo_item.current_rank).not_to be_nil
      end
    end

    context "when new items should be unranked" do
      let(:todo_item) { ::UnrankedTodoItem.create! }

      it "creates a new unranked object" do
        expect(todo_item.current_rank).to be_nil
      end
    end
  end

  describe "#increase_rank" do
    context "when used on an unscoped model" do
      before do
        ::DefaultTodoItem.delete_all
        ::NonDefaultTodoItem.delete_all
      end
  
      context "when adding items at the bottom of the list" do
        let!(:todo_item_a) { ::DefaultTodoItem.create! }
        let!(:todo_item_b) { ::DefaultTodoItem.create! }
  
        it "puts item higher in the list" do
          expect(todo_item_a.current_rank < todo_item_b.current_rank).to be_truthy
          todo_item_b.increase_rank
          expect(todo_item_a.current_rank < todo_item_b.current_rank).to be_falsey
        end
      end
  
      context "when adding items at the top of the list" do
        let!(:non_default_todo_item_a) { ::NonDefaultTodoItem.create! }
        let!(:non_default_todo_item_b) { ::NonDefaultTodoItem.create! }
  
        it "puts item higher in the list" do
          expect(non_default_todo_item_a.current_rank < non_default_todo_item_b.current_rank).to be_falsey
          non_default_todo_item_a.increase_rank
          expect(non_default_todo_item_a.current_rank < non_default_todo_item_b.current_rank).to be_truthy
        end
      end
  
      context "when current item is unranked" do
        let!(:todo_item_a) { ::UnrankedTodoItem.create! }
        let!(:todo_item_b) { ::UnrankedTodoItem.create! }
  
        it "not raises error" do
          expect(todo_item_b.current_rank).to be_nil
          expect { todo_item_b.increase_rank }.not_to raise_error
        end
      end
    end

    context "when used on a scoped model" do
      let(:todo_list_soon) { ::TodoList.create!(title: "300 ft plans") }
      let(:todo_list_later) { ::TodoList.create!(title: "1_000 ft plans") }
      let(:todo_list_never) { ::TodoList.create!(title: "50_000 ft plans") }
      let(:todo_item_soon_a) { ::ScopedListTodoItem.create!(todo_list: todo_list_soon, rank: 200) }
      let(:todo_item_soon_b) { ::ScopedListTodoItem.create!(todo_list: todo_list_soon, rank: 400) }
      let(:todo_item_later_a) { ::ScopedListTodoItem.create!(todo_list: todo_list_later, rank: 600) }
      let(:todo_item_never_a) { ::ScopedListTodoItem.create!(todo_list: todo_list_never, rank: 200) }
      let(:todo_item_never_b) { ::ScopedListTodoItem.create!(todo_list: todo_list_never, rank: 600) }

      before (:each) do
        ::DefaultTodoItem.destroy_all

        # creates todo items
        todo_item_soon_a
        todo_item_soon_b
        todo_item_later_a
        todo_item_never_a
        todo_item_never_b
      end

      it "increases rank for scope" do
        expect { todo_item_soon_b.increase_rank }.to change(todo_item_soon_b, :rank).from(400).to(100)
        expect { todo_item_later_a.increase_rank }.not_to change(todo_item_later_a, :rank)
        expect { todo_item_never_b.increase_rank }.to change(todo_item_never_b, :rank).from(600).to(100)
      end
    end
  end

  describe "#decrease_rank" do
    before do
      ::DefaultTodoItem.delete_all
      ::NonDefaultTodoItem.delete_all
    end

    context "when adding items at the bottom of the list" do
      let!(:todo_item_a) { ::DefaultTodoItem.create! }
      let!(:todo_item_b) { ::DefaultTodoItem.create! }

      it "puts item higher in the list" do
        expect(todo_item_a.current_rank < todo_item_b.current_rank).to be_truthy
        todo_item_a.decrease_rank
        expect(todo_item_a.current_rank < todo_item_b.current_rank).to be_falsey
      end
    end

    context "when adding items at the top of the list" do
      let!(:non_default_todo_item_a) { ::NonDefaultTodoItem.create! }
      let!(:non_default_todo_item_b) { ::NonDefaultTodoItem.create! }

      it "puts item higher in the list" do
        expect(non_default_todo_item_a.current_rank < non_default_todo_item_b.current_rank).to be_falsey
        non_default_todo_item_b.decrease_rank
        expect(non_default_todo_item_a.current_rank < non_default_todo_item_b.current_rank).to be_truthy
      end
    end

    context "when current item is unranked" do
      let!(:todo_item_a) { ::UnrankedTodoItem.create! }
      let!(:todo_item_b) { ::UnrankedTodoItem.create! }

      it "not raises error" do
        expect(todo_item_a.current_rank).to be_nil
        expect { todo_item_a.decrease_rank }.not_to raise_error
      end
    end
  end

  describe ".get_highest_items" do
    before (:each) do
      ::DefaultTodoItem.delete_all
      ::NonDefaultTodoItem.delete_all
    end

    context "when called without arguments" do
      let!(:highest_items) do
        3.times.each_with_index.map do |index|
          ::DefaultTodoItem.create!
        end
      end

      it "gets highest items using defaults" do
        items = ::DefaultTodoItem.get_highest_items
        expect(items.count).to eq(highest_items.count)
        expect(items).to eq(highest_items)
      end
    end

    context "when called with arguments" do
      let!(:highest_items) do
        3.times.each_with_index.map do |index|
          ::DefaultTodoItem.create!
        end
      end

      it "gets highest item when limit is 1" do
        items = ::DefaultTodoItem.get_highest_items(1)
        expect(items.count).to eq(1)
        expect(items.first.current_rank).to eq(::DefaultTodoItem.minimum(:rank))
      end
    end
  end


  describe ".get_lowest_items" do
    before (:each) do
      ::DefaultTodoItem.delete_all
      ::NonDefaultTodoItem.delete_all
    end

    context "when called without arguments" do
      let!(:lowest_items) do
        3.times.each_with_index.map do |index|
          ::DefaultTodoItem.create!
        end
      end

      it "gets lowest items using defaults" do
        items = ::DefaultTodoItem.get_lowest_items
        expect(items.count).to eq(lowest_items.count)
        expect(items).to eq(lowest_items.reverse!)
      end
    end

    context "when called with arguments" do
      let!(:lowest_items) do
        3.times.each_with_index.map do |index|
          ::DefaultTodoItem.create!
        end
      end

      it "gets lowest item when limit is 1" do
        items = ::DefaultTodoItem.get_lowest_items(1)
        expect(items.count).to eq(1)
        expect(items.first.current_rank).to eq(::DefaultTodoItem.maximum(:rank))
      end
    end
  end

  describe "#highest_item?" do
    context "when used on an unscoped model" do
      let(:todo_item_a) { ::DefaultTodoItem.create!(title: "Legend", rank: 20) }
      let(:todo_item_b) { ::DefaultTodoItem.create!(title: "Normal", rank: 50) }

      before do
        ::DefaultTodoItem.delete_all

        # creates todo items
        todo_item_a
        todo_item_b
      end

      context "when used on the highest item" do
        it "returns true" do
          expect(todo_item_a.highest_item?).to be_truthy
        end
      end

      context "when used on not the highest item" do
        it "returns false" do
          expect(todo_item_b.highest_item?).to be_falsey
        end
      end
    end

    context "when used on a scoped model" do
      before (:each) do
        ::DefaultTodoItem.delete_all
      end

      context "when scoping on an integer column" do
        let!(:todo_item) { ::DefaultTodoItem.create!(rank: 5) }
        let!(:scoped_integer_todo_item_a) { ::ScopedIntegerTodoItem.create!(scope_integer: 0, rank: 10) }
        let!(:scoped_integer_todo_item_b) { ::ScopedIntegerTodoItem.create!(scope_integer: 500, rank: 0) }
        let!(:scoped_integer_todo_item_c) { ::ScopedIntegerTodoItem.create!(scope_integer: 500, rank: 20) }

        it "evaluates correctly" do
          expect(scoped_integer_todo_item_a.highest_item?).to be_truthy
          expect(scoped_integer_todo_item_b.highest_item?).to be_truthy
          expect(scoped_integer_todo_item_c.highest_item?).to be_falsey
          expect(todo_item.highest_item?).to be_falsey
        end
      end

      context "when scoping on a string column" do
        context "when using a string to define the scope" do
          let!(:todo_item) { ::DefaultTodoItem.create!(rank: 5) }
          let!(:scoped_string_todo_item_a) { ::ScopedStringTodoItem.create!(scope_string: "work", rank: 10) }
          let!(:scoped_string_todo_item_b) { ::ScopedStringTodoItem.create!(scope_string: "personal", rank: 0) }
          let!(:scoped_string_todo_item_c) { ::ScopedStringTodoItem.create!(scope_string: "personal", rank: 20) }
  
          it "evaluates correctly" do
            expect(scoped_string_todo_item_a.highest_item?).to be_truthy
            expect(scoped_string_todo_item_b.highest_item?).to be_truthy
            expect(scoped_string_todo_item_c.highest_item?).to be_falsey
            expect(todo_item.highest_item?).to be_falsey
          end
        end

        context "when using a symbol to define the scope" do
          let!(:todo_item) { ::DefaultTodoItem.create!(rank: 5) }
          let!(:scoped_string_todo_item_a) { ::ScopedStringViaSymbolTodoItem.create!(scope_string: :work, rank: 10) }
          let!(:scoped_string_todo_item_b) { ::ScopedStringViaSymbolTodoItem.create!(scope_string: :personal, rank: 0) }
          let!(:scoped_string_todo_item_c) { ::ScopedStringViaSymbolTodoItem.create!(scope_string: :personal, rank: 20) }
  
          it "evaluates correctly" do
            expect(scoped_string_todo_item_a.highest_item?).to be_truthy
            expect(scoped_string_todo_item_b.highest_item?).to be_truthy
            expect(scoped_string_todo_item_c.highest_item?).to be_falsey
            expect(todo_item.highest_item?).to be_falsey
          end
        end
      end

      context "when scoping on multiple columns" do
        context "when using a symbol and integer to define the scopes" do
          let!(:todo_item) { ::DefaultTodoItem.create!(rank: 5) }
          let!(:scoped_multiple_todo_item_monday_a) { ::ScopedMultipleTodoItem.create!(title: "water the plants", rank: 10) }
          let!(:scoped_multiple_todo_item_monday_b) { ::ScopedMultipleTodoItem.create!(title: "sing to the lilies", rank: 20) }
          let!(:scoped_multiple_todo_item_tuesday_a) { ::ScopedMultipleTodoItem.create!(title: "sing to the lilies", scope_integer: :tuesday, rank: 15) }
          let!(:scoped_multiple_todo_item_tuesday_b) { ::ScopedMultipleTodoItem.create!(title: "water the plants", scope_integer: :tuesday, rank: 22) }

          it "evaluates item relative to scope" do
            expect(scoped_multiple_todo_item_monday_a.highest_item?).to be_truthy
            expect(scoped_multiple_todo_item_tuesday_a.highest_item?).to be_truthy
            expect(scoped_multiple_todo_item_monday_b.highest_item?).to be_falsey
            expect(scoped_multiple_todo_item_tuesday_b.highest_item?).to be_falsey
          end
        end
      end
    end
  end

  describe "#lowest_item?" do
    context "when used on an unscoped model" do
      let(:todo_item_a) { ::DefaultTodoItem.create!(title: "top", rank: 20) }
      let(:todo_item_b) { ::DefaultTodoItem.create!(title: "bottom", rank: 50) }

      before do
        ::DefaultTodoItem.delete_all

        # creates todo items
        todo_item_a
        todo_item_b
      end

      context "when used on the lowest item" do
        it "returns true" do
          expect(todo_item_b.lowest_item?).to be_truthy
        end
      end

      context "when used on not the lowest item" do
        it "returns false" do
          expect(todo_item_a.lowest_item?).to be_falsey
        end
      end
    end

    context "when used on a scoped model" do
      before (:each) do
        ::DefaultTodoItem.delete_all
      end

      context "when scoping on an integer column" do
        let!(:todo_item) { ::DefaultTodoItem.create!(rank: 5) }
        let!(:scoped_integer_todo_item_a) { ::ScopedIntegerTodoItem.create!(scope_integer: 0, rank: 10) }
        let!(:scoped_integer_todo_item_b) { ::ScopedIntegerTodoItem.create!(scope_integer: 500, rank: 0) }
        let!(:scoped_integer_todo_item_c) { ::ScopedIntegerTodoItem.create!(scope_integer: 500, rank: 20) }

        it "evaluates correctly" do
          expect(scoped_integer_todo_item_a.lowest_item?).to be_truthy
          expect(scoped_integer_todo_item_b.lowest_item?).to be_falsey
          expect(scoped_integer_todo_item_c.lowest_item?).to be_truthy
          expect(todo_item.lowest_item?).to be_falsey
        end
      end

      context "when scoping on a string column" do
        context "when using a string to define the scope" do
          let!(:todo_item) { ::DefaultTodoItem.create!(rank: 5) }
          let!(:scoped_string_todo_item_a) { ::ScopedStringTodoItem.create!(scope_string: "work", rank: 10) }
          let!(:scoped_string_todo_item_b) { ::ScopedStringTodoItem.create!(scope_string: "personal", rank: 0) }
          let!(:scoped_string_todo_item_c) { ::ScopedStringTodoItem.create!(scope_string: "personal", rank: 20) }
  
          it "evaluates correctly" do
            expect(scoped_string_todo_item_a.lowest_item?).to be_truthy
            expect(scoped_string_todo_item_b.lowest_item?).to be_falsey
            expect(scoped_string_todo_item_c.lowest_item?).to be_truthy
            expect(todo_item.lowest_item?).to be_falsey
          end
        end

        context "when using a symbol to define the scope" do
          let!(:todo_item) { ::DefaultTodoItem.create!(rank: 5) }
          let!(:scoped_string_todo_item_a) { ::ScopedStringViaSymbolTodoItem.create!(scope_string: :work, rank: 10) }
          let!(:scoped_string_todo_item_b) { ::ScopedStringViaSymbolTodoItem.create!(scope_string: :personal, rank: 0) }
          let!(:scoped_string_todo_item_c) { ::ScopedStringViaSymbolTodoItem.create!(scope_string: :personal, rank: 20) }
  
          it "evaluates correctly" do
            expect(scoped_string_todo_item_a.lowest_item?).to be_truthy
            expect(scoped_string_todo_item_b.lowest_item?).to be_falsey
            expect(scoped_string_todo_item_c.lowest_item?).to be_truthy
            expect(todo_item.lowest_item?).to be_falsey
          end
        end
      end

      context "when scoping on multiple columns" do
        context "when using a symbol and integer to define the scopes" do
          let!(:todo_item) { ::DefaultTodoItem.create!(rank: 5) }
          let!(:scoped_multiple_todo_item_monday_a) { ::ScopedMultipleTodoItem.create!(title: "water the plants", rank: 10) }
          let!(:scoped_multiple_todo_item_monday_b) { ::ScopedMultipleTodoItem.create!(title: "sing to the lilies", rank: 20) }
          let!(:scoped_multiple_todo_item_tuesday_a) { ::ScopedMultipleTodoItem.create!(title: "sing to the lilies", scope_integer: :tuesday, rank: 15) }
          let!(:scoped_multiple_todo_item_tuesday_b) { ::ScopedMultipleTodoItem.create!(title: "water the plants", scope_integer: :tuesday, rank: 22) }

          it "evaluates item relative to scope" do
            expect(scoped_multiple_todo_item_monday_a.lowest_item?).to be_falsey
            expect(scoped_multiple_todo_item_tuesday_a.lowest_item?).to be_falsey
            expect(scoped_multiple_todo_item_monday_b.lowest_item?).to be_truthy
            expect(scoped_multiple_todo_item_tuesday_b.lowest_item?).to be_truthy
          end
        end
      end
    end
  end

  describe "#get_higher_items" do
    let(:todo_item_group) do
      4.times.each_with_index.map do |index|
        ::DefaultTodoItem.create!(rank: (index + 1) * 100)
      end
    end
    let(:todo_item) { ::DefaultTodoItem.create!(title: "middle", rank: 250) }

    before do
      ::DefaultTodoItem.delete_all

      # creates todo items
      todo_item_group
      todo_item
    end

    context "when called without arguments" do
      it "returns lower items in ASC order" do
        expect(todo_item.get_lower_items).to eq(::DefaultTodoItem.get_lowest_items(2).reverse)
      end
    end

    context "when called with arguments" do
      it "returns the lower items in DESC order" do
        expect(todo_item.get_lower_items(0, "DESC")).to eq(::DefaultTodoItem.get_lowest_items(2).to_a)
      end

      it "returns the lower item" do
        expect(todo_item.get_lower_items(1).first).to eq(::DefaultTodoItem.get_lowest_items(2).last)
      end
    end
  end

  describe "#get_lower_items" do
    let(:todo_item_group) do
      4.times.each_with_index.map do |index|
        ::DefaultTodoItem.create!(rank: (index + 1) * 100)
      end
    end
    let(:todo_item) { ::DefaultTodoItem.create!(title: "middle", rank: 250) }

    before do
      ::DefaultTodoItem.delete_all

      # creates todo items
      todo_item_group
      todo_item
    end

    context "when called without arguments" do
      it "returns higher items in DESC order" do
        expect(todo_item.get_higher_items).to eq(::DefaultTodoItem.get_highest_items(2).reverse)
      end
    end

    context "when called with arguments" do
      it "returns the higher items in ASC order" do
        expect(todo_item.get_higher_items(0, "ASC")).to eq(::DefaultTodoItem.get_highest_items(2).to_a)
      end

      it "returns the higher item" do
        expect(todo_item.get_higher_items(1).first).to eq(::DefaultTodoItem.get_highest_items(2).last)
      end
    end
  end

  describe "#is_ranked?" do
    context "when item's rank is nil" do
      let(:todo_item) { ::DefaultTodoItem.with_skip_persistence { ::DefaultTodoItem.create!(rank: nil) } }

      it "returns false" do
        expect(todo_item.is_ranked?).to be_falsey
      end
    end

    context "when item's rank is not nil" do
      let(:todo_item) { ::DefaultTodoItem.create!(rank: 20) }

      it "returns false" do
        expect(todo_item.is_ranked?).to be_truthy
      end
    end
  end

  describe "#set_rank_above" do
    context "when used on an unscoped model" do
      let(:todo_item_group) do
        4.times.each_with_index.map do |index|
          ::DefaultTodoItem.create!(rank: (index + 1) * 100)
        end
      end
      let(:todo_item) { ::DefaultTodoItem.create!(title: "gonna make it!", rank: 250) }

      before do
        ::DefaultTodoItem.delete_all

        # creates todo items
        todo_item_group
        todo_item
      end

      context "when moving to top of list" do
        it "sets as highest item" do
          expect(::DefaultTodoItem.get_highest_items(1)).not_to eq([todo_item])
          todo_item.set_rank_above(::DefaultTodoItem.get_highest_items(2).first)
          expect(::DefaultTodoItem.get_highest_items(1)).to eq([todo_item])
        end
      end

      context "when moving to not top of list" do
        it "sets as not highest item" do
          expect(::DefaultTodoItem.get_highest_items(1)).not_to eq([todo_item])
          todo_item.set_rank_above(::DefaultTodoItem.get_highest_items(2).second)
          expect(::DefaultTodoItem.get_highest_items(1)).not_to eq([todo_item])
        end
      end
    end

    context "when used on a scoped model" do
      let(:todo_list_soon) { ::TodoList.create!(title: "300 ft plans") }
      let(:todo_list_never) { ::TodoList.create!(title: "50_000 ft plans") }
      let(:todo_item_soon_a) { ::ScopedListTodoItem.create!(todo_list: todo_list_soon, rank: 200) }
      let(:todo_item_soon_b) { ::ScopedListTodoItem.create!(todo_list: todo_list_soon, rank: 400) }
      let(:todo_item_never_a) { ::ScopedListTodoItem.create!(todo_list: todo_list_never, rank: 200) }
      let(:todo_item_never_b) { ::ScopedListTodoItem.create!(todo_list: todo_list_never, rank: 600) }

      before (:each) do
        ::DefaultTodoItem.destroy_all

        # creates todo items
        todo_item_soon_a
        todo_item_soon_b
        todo_item_never_a
        todo_item_never_b
      end

      it "increases rank for scope" do
        expect { todo_item_soon_b.set_rank_above(todo_item_soon_a) }.to change(todo_item_soon_b, :rank).from(400).to(100)
        expect { todo_item_never_b.set_rank_above(todo_item_never_a) }.to change(todo_item_never_b, :rank).from(600).to(100)
      end
    end
  end

  describe "#set_rank_below" do
    context "when used on an unscoped model" do
      let(:todo_item_group) do
        4.times.each_with_index.map do |index|
          ::DefaultTodoItem.create!(rank: (index + 1) * 100)
        end
      end
      let(:todo_item) { ::DefaultTodoItem.create!(title: "oh no!", rank: 250) }
  
      before do
        ::DefaultTodoItem.delete_all
  
        # creates todo items
        todo_item_group
        todo_item
      end
  
      context "when moving to bottom of list" do
        it "sets as lowest item" do
          expect(::DefaultTodoItem.get_lowest_items(1)).not_to eq([todo_item])
          todo_item.set_rank_below(::DefaultTodoItem.get_lowest_items(2).first)
          expect(::DefaultTodoItem.get_lowest_items(1)).to eq([todo_item])
        end
      end
  
      context "when moving to not bottom of list" do
        it "sets as not lowest item" do
          expect(::DefaultTodoItem.get_lowest_items(1)).not_to eq([todo_item])
          todo_item.set_rank_below(::DefaultTodoItem.get_lowest_items(2).second)
          expect(::DefaultTodoItem.get_lowest_items(1)).not_to eq([todo_item])
        end
      end
    end
  end

  describe "persistence callbacks" do
    context "when skipping persistence callbacks" do
      it "does not call persistence callback methods" do
        expect_any_instance_of(::DefaultTodoItem).not_to receive(:ranked_list_after_destroy_callback)
        expect_any_instance_of(::DefaultTodoItem).to receive(:ranked_list_after_save_callback).twice
        expect_any_instance_of(::DefaultTodoItem).not_to receive(:ranked_list_after_update_callback)
        expect_any_instance_of(::DefaultTodoItem).not_to receive(:ranked_list_before_create_callback)
        expect_any_instance_of(::DefaultTodoItem).not_to receive(:ranked_list_before_destroy_callback)
        expect_any_instance_of(::DefaultTodoItem).not_to receive(:ranked_list_before_update_callback)
        expect_any_instance_of(::DefaultTodoItem).not_to receive(:ranked_list_before_validation_callback)
        ::DefaultTodoItem.with_skip_persistence do
          todo_item = ::DefaultTodoItem.create!
          todo_item.update!(rank: 2)
          todo_item.destroy!
        end
      end
    end

    context "when not skipping persistence callbacks" do
      it "does call persistence callback methods" do
        expect_any_instance_of(::DefaultTodoItem).to receive(:ranked_list_after_destroy_callback)
        expect_any_instance_of(::DefaultTodoItem).to receive(:ranked_list_after_save_callback).twice
        expect_any_instance_of(::DefaultTodoItem).to receive(:ranked_list_after_update_callback)
        expect_any_instance_of(::DefaultTodoItem).to receive(:ranked_list_before_create_callback)
        expect_any_instance_of(::DefaultTodoItem).to receive(:ranked_list_before_destroy_callback)
        expect_any_instance_of(::DefaultTodoItem).to receive(:ranked_list_before_update_callback)
        expect_any_instance_of(::DefaultTodoItem).to receive(:ranked_list_before_validation_callback).twice
        todo_item = ::DefaultTodoItem.create!
        todo_item.update!(rank: 2)
        todo_item.destroy!
      end
    end
  end

  describe ".avoid_collisions" do
    before do
      ::DefaultTodoItem.delete_all
    end

    context "when avoiding collisions" do
      it "updates persisted collisions" do
        ::DefaultTodoItem.with_avoid_collisions(true) do
          6.times.each do |index|
            ::DefaultTodoItem.create!(rank: 100.0)
          end
        end
        counts = ::DefaultTodoItem.group(:rank).count
        expect(counts.values).to eq([1] * 6)
      end
    end

    context "when not avoiding collisions" do
      it "not updates persisted collisions" do
        ::DefaultTodoItem.with_avoid_collisions(false) do
          6.times.each do |index|
            ::DefaultTodoItem.create!(rank: 100.0)
          end
        end
        counts = ::DefaultTodoItem.group(:rank).count
        expect(counts.values).to eq([6])
      end
    end
  end

  describe ".spread_ranks" do
    context "when used on an unscoped class" do
      before (:each) do
        ::DefaultTodoItem.delete_all
      end

      context "when no ranks are in collision" do
        let!(:todo_item_group) do
          4.times.map do |index|
            ::DefaultTodoItem.create!(rank: index)
          end
        end

        it "spreads rank by rank" do
          ::DefaultTodoItem.spread_ranks
          expect(::DefaultTodoItem.get_highest_items(4).pluck(:id)).to eq(todo_item_group.map(&:id))
        end
      end

      context "when ranks are in collision" do
        let!(:todo_item_group) do
          ::DefaultTodoItem.with_skip_persistence do
            4.times.each_with_index.map do |index|
              ::DefaultTodoItem.create!(rank: 42, updated_at: ::Time.now + (4 - index).minute)
            end
          end
        end

        it "spreads rank by updated_at" do
          ::DefaultTodoItem.spread_ranks
          expect(::DefaultTodoItem.get_highest_items(4).pluck(:id)).to eq(todo_item_group.reverse.map(&:id))
        end

        it "spreads rank by step_increment amount" do
          sql = <<~SQL
            SELECT rank, (lag(rank, 0, 0) OVER (order by rank)) AS diff_value FROM todo_items
          SQL
          value_before_spread = ::ActiveRecord::Base.connection.execute(sql).to_a.map { |diff| diff["diff_value"] }
          ::DefaultTodoItem.spread_ranks
          value_after_spread = ::ActiveRecord::Base.connection.execute(sql).to_a.map { |diff| diff["diff_value"] }
          expect(value_before_spread.uniq).to eq([42])
          expect(value_after_spread).to eq((::DefaultTodoItem.step_increment .. ::DefaultTodoItem.step_increment * 4).step(::DefaultTodoItem.step_increment).to_a)
        end
      end

      context "when items are not ranked" do
        let!(:todo_item_group) do
          ::DefaultTodoItem.with_skip_persistence do
            4.times.each_with_index do |index|
              ::DefaultTodoItem.create!(rank: nil)
            end
          end
        end

        it "ignores unranked items" do
          ::DefaultTodoItem.spread_ranks
          expect(::DefaultTodoItem.pluck(:rank).compact).to be_blank
        end
      end
    end

    context "when used on a scoped class" do
      before (:each) do
        ::DefaultTodoItem.delete_all
      end

      context "when items belong to different scopes" do
        let!(:todo_item_group) do
          4.times.map do |index|
            ::ScopedMultipleTodoItem.create!(rank: index, scope_integer: index % 2)
          end
        end

        it "spreads rank by rank" do
          ::ScopedMultipleTodoItem.spread_ranks
          expected_todo_items = [todo_item_group[0], todo_item_group[2], todo_item_group[1], todo_item_group[3]].map(&:id)
          expect(::ScopedMultipleTodoItem.get_highest_items(4).pluck(:id)).to eq(expected_todo_items)
        end
      end

      context "when scoped items are not ranked" do
        let!(:todo_item_group_a) do
          ::ScopedMultipleTodoItem.with_skip_persistence([DefaultTodoItem]) do
            2.times.each_with_index do |index|
              ::ScopedMultipleTodoItem.create!(rank: index % 2 == 0 ? 42 : nil, scope_integer: 0)
            end
            2.times.each_with_index do |index|
              ::ScopedMultipleTodoItem.create!(rank: index % 2 == 0 ? 42 : nil, scope_integer: 1)
            end
            2.times.each_with_index do |index|
              ::DefaultTodoItem.create!(rank: index % 2 == 0 ? 42 : nil, scope_integer: nil) # for visibility that this item is not scoped
            end
          end
        end

        it "ignores unranked items" do
          ::DefaultTodoItem.spread_ranks
          expect(::DefaultTodoItem.get_highest_items.count).to eq(3)
        end
      end
    end
  end
end
