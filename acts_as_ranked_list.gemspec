# frozen_string_literal: true

require_relative "lib/acts_as_ranked_list/version"

Gem::Specification.new do |spec|
  spec.name = "acts_as_ranked_list"
  spec.version = ActsAsRankedList::VERSION
  spec.authors = ["Farbafe"]
  spec.email = ["yehyapal@gmail.com"]

  spec.summary = "Orders ActiveRecord items by ranks. Influenced by gem ActsAsList."
  spec.description = "Orders ActiveRecord items by floating ranks for spaces in-between items. Influenced by gem ActsAsList. The floating rank allows inserting items at arbitrary positions without reordering items. Thus, reducing the number of WRITE queries."
  spec.homepage = "https://github.com/Farbafe/acts_as_ranked_list"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "http://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Farbafe/acts_as_ranked_list/blob/master"
  spec.metadata["changelog_uri"] = "https://github.com/Farbafe/acts_as_ranked_list/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "rails", "~> 6.0.3", ">= 6.0.3.6" 
  spec.add_dependency "rake", "~> 13.0"
  spec.add_dependency "rspec", "~> 3.0"
  spec.add_dependency "standard", "~> 1.3"
  spec.add_dependency "rspec-rails", "5.1.2"
  spec.add_development_dependency "byebug", "11.1.3"
  spec.add_development_dependency "yard", "0.9.34"
  spec.add_development_dependency "redcarpet", "3.6.0"
  spec.add_development_dependency "sqlite3", "1.6.2"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
