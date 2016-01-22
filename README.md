# Guard::SlimLint

Guard::SlimLint gem helps developers to automatically runs slim-lint every time a slim file is saved.


## Installation

Add this line to your application's Gemfile:

```ruby
group :development do
  gem 'guard-slimlint'
end
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install guard-slimlint


## Usage
After gem instalation generate an empty ```Guardfile``` with:

    $ bundle exec guard init
    
and run guard through Bundler with:

    $ bundle exec guard


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/guard-slimlint. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

