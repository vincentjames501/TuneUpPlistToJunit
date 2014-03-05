# TuneUpPlistToJunit

Utility to simply convert a TuneupJS UIAutomation plist file into a JUnit
style xml output to be parsed by a CI server such as Jenkins.

## Installation

Add this line to your application's Gemfile:

    gem 'tuneup-plist-to-junit'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tuneup-plist-to-junit

## Testing

simply run:

    $ rspec test/tuneup_plist_to_junit_utils_spec.rb

## Usage

To use, simply use

    $ tuneup_plist_to_junit_parser

    Usage: TuneUpPlistToJunit.rb [options]

    Specific options:
        -i, --input FILE                 UIAutomation plist generated with TuneupJS.  Default: Automation Results.plist
        -o, --output FILE                Output location of JUnit test report.  Default: test_report.xml
        -c, --class-name CLASSNAME       The class name to use on the test case.  Default: UIAutomation

    Common options:
        -h, --help                       Show this message
        -v, --version                    Show version


## Contributing

Contributions are welcome and greatly encouraged as I don't have a whole lot of time
to dedicate to maintaining this project.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
