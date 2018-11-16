# Guard::Eslint

Guard::Eslint allows you to automatically run eslint when you change a Javascript/ES6 file.
This is best when run after your Javascript tests pass.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'guard-eslint'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install guard-eslint

## Usage

Please read [Guard usage doc](https://github.com/guard/guard#readme).

## Guardfile

For a typical Rails app with webpack:

``` ruby
guard :eslint, formatter: 'codeframe' do
  watch(%r{^app/javascript/.+\.(js|es6)$})
  watch(%r{^spec/javascript/.+\.(js|es6)$})
end
```

### List of available options:

``` ruby
all_on_start: true                     # Run all specs after changed specs pass.
keep_failed: false                     # Keep failed files until they pass (add them to new ones)
notification: :failed                  # Display notification when eslint reports an issue.
                                       # If you want to always notify, set to true.
cli: nil                               # Additional command-line options to pass to eslint.
                                       # Don't use the '-f' or '--format' option here.
formatter: nil                         # Formatter to use for output to the console.
command: 'eslint'                      # Specify a custom path to the eslint command.
default_paths: ['**/*.js', '**/*.es6'] # The default paths that will be used for "all_on_start".
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RobinDaugherty/guard-eslint.

* Please create a topic branch for every separate change you make.
* Make sure your patches are well-tested.
* Update the README to reflect your changes.
* Please **do not change** the version number.
* Open a pull request. 
