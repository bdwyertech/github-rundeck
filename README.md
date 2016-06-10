# Github-RunDeck

## GitHub Options Provider
This gem delivers RunDeck options in the supported JSON format

* List of User Repos - `GET` - *http://localhost:9125/github/v1/repos/user/${ORGNAME}*
* List of Organization Repos - `GET` - *http://localhost:9125/github/v1/repos/org/${ORGNAME}*
* List of Branch/Tag Names for a Repo - `GET` - *http://localhost:9125/github/v1/revisions/${ORGNAME}/${REPONAME}*

### OAuth Key
You can feed a GitHub OAuth key via local configuration, or as the Query Parameter `oauth_token`


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'github-rundeck'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install github-rundeck


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bdwyertech/github-rundeck. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

