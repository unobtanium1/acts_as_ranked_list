# frozen_string_literal: true

::RSpec.describe ::ActsAsRankedList::ActiveRecord::SkipPersistence do
  let(:mocked_model) { double("MyModel", ancestors: [::ActiveRecord::Base]) }

  describe ".with_skip_persistence" do
    before do
      described_class.included(described_class)
    end

    context "called with invalid arguments" do
      it "raises error" do
        expect { described_class.with_skip_persistence([mocked_model]) { nil } }.to raise_error(::ArgumentError)
      end
    end

    context "called with valid arguments" do
      before do
        expect(described_class).to receive(:ancestors).and_return([::ActiveRecord::Base])
      end

      it "not raises error" do
        expect { described_class.with_skip_persistence([mocked_model]) { nil } }.not_to raise_error
      end
    end
  end

  describe ".with_applied_klasses" do
    context "when klasses is an array" do
      it "adds klasses to Thread.current" do
        expect(described_class).to receive(:add_klass).with(mocked_model).and_call_original
        expect(described_class).to receive(:remove_klass).with(mocked_model)
        described_class.with_applied_klasses([mocked_model]) { nil }
        extracted_klasses = described_class.send(:extracted_klasses)
        expect(extracted_klasses[mocked_model]).to eq(1)
      end

      it "removes klasses from Thread.current" do
        expect(described_class).to receive(:remove_klass).with(mocked_model).and_call_original
        described_class.with_applied_klasses([mocked_model]) { nil }
        extracted_klasses = described_class.send(:extracted_klasses)
        expect(extracted_klasses[mocked_model]).to be_nil
      end
    end
  end
end
