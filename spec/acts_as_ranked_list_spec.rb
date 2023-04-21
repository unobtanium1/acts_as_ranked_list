# frozen_string_literal: true

::RSpec.describe ::ActsAsRankedList do
  it "has a semantic versioninig string version" do
    expect(::ActsAsRankedList::VERSION).not_to be nil
    expect(::ActsAsRankedList::VERSION).to be_a(::String)
    expect(::ActsAsRankedList::VERSION.split(".").length).to eq(3)
  end
end
