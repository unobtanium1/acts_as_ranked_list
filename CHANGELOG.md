# Changelog

All notable changes to this project will be documented in this file.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [0.2.2] - 2023-04-24

- ~~Allows unranked items in list by having `nil` values.~~ Implicitly allowed behaviour since v0.2.0, also able to add new items can also be added as unranked. Adds documentation to this feature.
- Allows any number of different scopes on the items by referencing another column, of type:
  - a relationship.
  - a string, symbol, boolean or number.
  - a custom-defined scope.
- Fixes class method `spread_ranks` to ignore unranked items.

## [0.2.1] - 2023-04-21

- Bumps gem version to reflect changes in `.gemspec` file. No gem functionality changes.

## [0.2.0] - 2023-04-21

- Adds gem documentation
- Adds gem tests
- Adds gem functionality to rank `::ActiveRecord` objects.
  - Adds AvoidsCollisions
  - Adds SkipPersistence
  - Adds PersistenceCallback
  - Adds RankColumn
  - Adds Service
- Adds Base error

## [0.1.0] - 2023-04-11

- Initial release
