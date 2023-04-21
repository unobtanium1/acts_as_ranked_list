# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
begin
  ::Bundler.setup(:default, :development)
rescue ::Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

::RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require "active_record"
require "acts_as_ranked_list"
require "byebug"
::Dir[::File.join(::File.dirname(__FILE__), "support/**/*.rb")].each { |file| require file }
