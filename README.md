# ActsAsRankedList

This gem is based off of the ActsAsList gem. It rewrites the gem using floating point position (or rank) for items. The benefit of using floating point positions is the ability to insert an item inbetween items without updating the other items' positions.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add acts_as_ranked_list

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install acts_as_ranked_list

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Farbafe/acts_as_ranked_list.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
