# frozen_string_literal: true

::RSpec.describe ::ActsAsRankedList::ActiveRecord::Service do
  describe "#current_rank" do
    context "when using a decimal column called rank" do
      let(:todo_item) { ::TodoItem.create!(title: "title", rank: 20) }

      it "gets the current rank" do
        expect(todo_item.current_rank).to eq(20.0)
      end
    end

    context "when using an integer column not called rank" do
      let(:advanced_todo_item) { ::AdvancedTodoItem.create!(title: "advanced title", position: 20) }

      it "gets the current rank" do
        expect(advanced_todo_item.current_rank).to eq(20)
      end
    end
  end

  describe ".create!" do
    context "when called and not passing in arguments" do
      let(:todo_item) { ::TodoItem.create! }

      it "creates a new record using defaults" do
        expect(todo_item.current_rank).not_to be_nil
      end
    end

    context "when called and passing in arguments" do
      let(:todo_item) { ::TodoItem.create!(rank: nil) }

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
    before do
      ::TodoItem.delete_all
      ::AdvancedTodoItem.delete_all
    end

    context "when adding items at the bottom of the list" do
      let!(:todo_item_a) { ::TodoItem.create! }
      let!(:todo_item_b) { ::TodoItem.create! }

      it "puts item higher in the list" do
        expect(todo_item_a.current_rank < todo_item_b.current_rank).to be_truthy
        todo_item_b.increase_rank
        expect(todo_item_a.current_rank < todo_item_b.current_rank).to be_falsey
      end
    end

    context "when adding items at the top of the list" do
      let!(:advanced_todo_item_a) { ::AdvancedTodoItem.create! }
      let!(:advanced_todo_item_b) { ::AdvancedTodoItem.create! }

      it "puts item higher in the list" do
        expect(advanced_todo_item_a.current_rank < advanced_todo_item_b.current_rank).to be_falsey
        advanced_todo_item_a.increase_rank
        expect(advanced_todo_item_a.current_rank < advanced_todo_item_b.current_rank).to be_truthy
      end
    end
  end

  describe ".get_highest_items" do
    before (:each) do
      ::TodoItem.delete_all
      ::AdvancedTodoItem.delete_all
    end

    context "when called without arguments" do
      let!(:highest_items) do
        3.times.each_with_index.map do |index|
          ::TodoItem.create!
        end
      end

      it "gets highest items using defaults" do
        items = ::TodoItem.get_highest_items
        expect(items.count).to eq(highest_items.count)
        expect(items).to eq(highest_items)
      end
    end

    context "when called with arguments" do
      let!(:highest_items) do
        3.times.each_with_index.map do |index|
          ::TodoItem.create!
        end
      end

      it "gets highest item when limit is 1" do
        items = ::TodoItem.get_highest_items(1)
        expect(items.count).to eq(1)
        expect(items.first.current_rank).to eq(::TodoItem.minimum(:rank))
      end
    end
  end


  describe ".get_lowest_items" do
    before (:each) do
      ::TodoItem.delete_all
      ::AdvancedTodoItem.delete_all
    end

    context "when called without arguments" do
      let!(:lowest_items) do
        3.times.each_with_index.map do |index|
          ::TodoItem.create!
        end
      end

      it "gets lowest items using defaults" do
        items = ::TodoItem.get_lowest_items
        expect(items.count).to eq(lowest_items.count)
        expect(items).to eq(lowest_items.reverse!)
      end
    end

    context "when called with arguments" do
      let!(:lowest_items) do
        3.times.each_with_index.map do |index|
          ::TodoItem.create!
        end
      end

      it "gets lowest item when limit is 1" do
        items = ::TodoItem.get_lowest_items(1)
        expect(items.count).to eq(1)
        expect(items.first.current_rank).to eq(::TodoItem.maximum(:rank))
      end
    end
  end

  describe "#highest_item?" do
    let(:todo_item_a) { ::TodoItem.create!(title: "Legend", rank: 20) }
    let(:todo_item_b) { ::TodoItem.create!(title: "Normal", rank: 50) }

    before do
      ::TodoItem.delete_all

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

  describe "#lowest_item?" do
    let(:todo_item_a) { ::TodoItem.create!(title: "top", rank: 20) }
    let(:todo_item_b) { ::TodoItem.create!(title: "bottom", rank: 50) }

    before do
      ::TodoItem.delete_all

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

  describe "#get_higher_items" do
    let(:todo_item_group) do
      4.times.each_with_index.map do |index|
        ::TodoItem.create!(rank: (index + 1) * 100)
      end
    end
    let(:todo_item) { ::TodoItem.create!(title: "middle", rank: 250) }

    before do
      ::TodoItem.delete_all

      # creates todo items
      todo_item_group
      todo_item
    end

    context "when called without arguments" do
      it "returns lower items in ASC order" do
        expect(todo_item.get_lower_items).to eq(::TodoItem.get_lowest_items(2).reverse)
      end
    end

    context "when called with arguments" do
      it "returns the lower items in DESC order" do
        expect(todo_item.get_lower_items(0, "DESC")).to eq(::TodoItem.get_lowest_items(2).to_a)
      end

      it "returns the lower item" do
        expect(todo_item.get_lower_items(1).first).to eq(::TodoItem.get_lowest_items(2).last)
      end
    end
  end

  describe "#get_lower_items" do
    let(:todo_item_group) do
      4.times.each_with_index.map do |index|
        ::TodoItem.create!(rank: (index + 1) * 100)
      end
    end
    let(:todo_item) { ::TodoItem.create!(title: "middle", rank: 250) }

    before do
      ::TodoItem.delete_all

      # creates todo items
      todo_item_group
      todo_item
    end

    context "when called without arguments" do
      it "returns higher items in DESC order" do
        expect(todo_item.get_higher_items).to eq(::TodoItem.get_highest_items(2).reverse)
      end
    end

    context "when called with arguments" do
      it "returns the higher items in ASC order" do
        expect(todo_item.get_higher_items(0, "ASC")).to eq(::TodoItem.get_highest_items(2).to_a)
      end

      it "returns the higher item" do
        expect(todo_item.get_higher_items(1).first).to eq(::TodoItem.get_highest_items(2).last)
      end
    end
  end

  describe "#is_ranked?" do
    context "when item's rank is nil" do
      let(:todo_item) { ::TodoItem.with_skip_persistence { ::TodoItem.create!(rank: nil) } }

      it "returns false" do
        expect(todo_item.is_ranked?).to be_falsey
      end
    end

    context "when item's rank is not nil" do
      let(:todo_item) { ::TodoItem.create!(rank: 20) }

      it "returns false" do
        expect(todo_item.is_ranked?).to be_truthy
      end
    end
  end

  describe "#set_rank_above" do
    let(:todo_item_group) do
      4.times.each_with_index.map do |index|
        ::TodoItem.create!(rank: (index + 1) * 100)
      end
    end
    let(:todo_item) { ::TodoItem.create!(title: "gonna make it!", rank: 250) }

    before do
      ::TodoItem.delete_all

      # creates todo items
      todo_item_group
      todo_item
    end

    context "when moving to top of list" do
      it "sets as highest item" do
        expect(::TodoItem.get_highest_items(1)).not_to eq([todo_item])
        todo_item.set_rank_above(::TodoItem.get_highest_items(2).first)
        expect(::TodoItem.get_highest_items(1)).to eq([todo_item])
      end
    end

    context "when moving to not top of list" do
      it "sets as not highest item" do
        expect(::TodoItem.get_highest_items(1)).not_to eq([todo_item])
        todo_item.set_rank_above(::TodoItem.get_highest_items(2).second)
        expect(::TodoItem.get_highest_items(1)).not_to eq([todo_item])
      end
    end
  end

  describe "#set_rank_below" do
    let(:todo_item_group) do
      4.times.each_with_index.map do |index|
        ::TodoItem.create!(rank: (index + 1) * 100)
      end
    end
    let(:todo_item) { ::TodoItem.create!(title: "oh no!", rank: 250) }

    before do
      ::TodoItem.delete_all

      # creates todo items
      todo_item_group
      todo_item
    end

    context "when moving to bottom of list" do
      it "sets as lowest item" do
        expect(::TodoItem.get_lowest_items(1)).not_to eq([todo_item])
        todo_item.set_rank_below(::TodoItem.get_lowest_items(2).first)
        expect(::TodoItem.get_lowest_items(1)).to eq([todo_item])
      end
    end

    context "when moving to not bottom of list" do
      it "sets as not lowest item" do
        expect(::TodoItem.get_lowest_items(1)).not_to eq([todo_item])
        todo_item.set_rank_below(::TodoItem.get_lowest_items(2).second)
        expect(::TodoItem.get_lowest_items(1)).not_to eq([todo_item])
      end
    end
  end

  describe "persistence callbacks" do
    context "when skipping persistence callbacks" do
      it "does not call persistence callback methods" do
        expect_any_instance_of(::TodoItem).not_to receive(:ranked_list_after_destroy_callback)
        expect_any_instance_of(::TodoItem).to receive(:ranked_list_after_save_callback).twice
        expect_any_instance_of(::TodoItem).not_to receive(:ranked_list_after_update_callback)
        expect_any_instance_of(::TodoItem).not_to receive(:ranked_list_before_create_callback)
        expect_any_instance_of(::TodoItem).not_to receive(:ranked_list_before_destroy_callback)
        expect_any_instance_of(::TodoItem).not_to receive(:ranked_list_before_update_callback)
        expect_any_instance_of(::TodoItem).not_to receive(:ranked_list_before_validation_callback)
        ::TodoItem.with_skip_persistence do
          todo_item = ::TodoItem.create!
          todo_item.update!(rank: 2)
          todo_item.destroy!
        end
      end
    end

    context "when not skipping persistence callbacks" do
      it "does call persistence callback methods" do
        expect_any_instance_of(::TodoItem).to receive(:ranked_list_after_destroy_callback)
        expect_any_instance_of(::TodoItem).to receive(:ranked_list_after_save_callback).twice
        expect_any_instance_of(::TodoItem).to receive(:ranked_list_after_update_callback)
        expect_any_instance_of(::TodoItem).to receive(:ranked_list_before_create_callback)
        expect_any_instance_of(::TodoItem).to receive(:ranked_list_before_destroy_callback)
        expect_any_instance_of(::TodoItem).to receive(:ranked_list_before_update_callback)
        expect_any_instance_of(::TodoItem).to receive(:ranked_list_before_validation_callback).twice
        todo_item = ::TodoItem.create!
        todo_item.update!(rank: 2)
        todo_item.destroy!
      end
    end
  end

  describe ".avoid_collisions" do
    before do
      ::TodoItem.delete_all
    end

    context "when avoiding collisions" do
      it "updates persisted collisions" do
        ::TodoItem.with_avoid_collisions(true) do
          6.times.each do |index|
            ::TodoItem.create!(rank: 100.0)
          end
        end
        counts = ::TodoItem.group(:rank).count
        expect(counts.values).to eq([1] * 6)
      end
    end

    context "when not avoiding collisions" do
      it "not updates persisted collisions" do
        ::TodoItem.with_avoid_collisions(false) do
          6.times.each do |index|
            ::TodoItem.create!(rank: 100.0)
          end
        end
        counts = ::TodoItem.group(:rank).count
        expect(counts.values).to eq([6])
      end
    end
  end

  describe ".spread_ranks" do
    before (:each) do
      ::TodoItem.delete_all
    end

    context "when ranks are in collision" do
      let(:now) { ::Time.now }
      let!(:todo_item_group) do
        4.times.map do |index|
          ::TodoItem.create!(rank: index, updated_at: now)
        end
      end

      it "re-orders collisioned ranks by updated_at and primary_key" do
        ::TodoItem.spread_ranks
        expect(::TodoItem.get_highest_items(4)).to eq(todo_item_group)
      end

      it "re-orders collisioned ranks by updated_at" do
        ::TodoItem.get_highest_items.each_with_index do |todo_item, index|
          todo_item.update!(rank: 200, updated_at: ::Time.now + (4 - index).minute)
        end
        ::TodoItem.spread_ranks
        expect(::TodoItem.get_highest_items(4)).to eq(todo_item_group.reverse)
      end
    end

    context "when no ranks are in collision" do
      let!(:todo_item_group) do
        4.times.each_with_index do |index|
          ::TodoItem.create!(rank: index)
        end
      end

      it "spreads rank by step_increment amount" do
        sql = <<~SQL
          SELECT rank, (lag(rank, 0, 0) OVER (order by rank)) AS diff_value FROM todo_items
        SQL
        value_before_spread = ::ActiveRecord::Base.connection.execute(sql).to_a.map { |diff| diff["diff_value"] }
        ::TodoItem.spread_ranks
        value_after_spread = ::ActiveRecord::Base.connection.execute(sql).to_a.map { |diff| diff["diff_value"] }
        expect(value_before_spread).to eq((0..3).to_a)
        expect(value_after_spread).to eq((::TodoItem.step_increment .. ::TodoItem.step_increment * 4).step(::TodoItem.step_increment).to_a)
      end
    end

    context "when items are not ranked" do
      let!(:todo_item_group) do
        ::TodoItem.with_skip_persistence do
          4.times.each_with_index do |index|
            ::TodoItem.create!(rank: nil)
          end
        end
      end

      it "ignores those items" do
        ::TodoItem.spread_ranks
        expect(::TodoItem.pluck(:rank).compact).to be_blank
      end
    end
  end
end
