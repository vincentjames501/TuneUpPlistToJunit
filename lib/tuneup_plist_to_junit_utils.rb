require 'TuneUpPlistToJunit/version'
require 'plist'
require 'nokogiri'
require 'JSON'

class TuneUpPlistToJunitUtils
  #Constants that refer to the <Type> plist tag
  LOG_DEBUG = 0
  LOG_DEFAULT = 1
  LOG_ERROR = 3
  START_TEST = 4
  END_SUCCESS = 5
  END_FAILURE = 7
  SCREENSHOT = 8

  private_constant :LOG_DEBUG
  private_constant :LOG_DEFAULT
  private_constant :LOG_ERROR
  private_constant :START_TEST
  private_constant :END_SUCCESS
  private_constant :END_FAILURE
  private_constant :SCREENSHOT

  private

  # Parses the plist file and returns just the test results array (log messages)
  #
  # @param [String] plist_file_or_xml file name or xml of the UIAutomation plist file
  # @return [Array] the unprocessed plist test results array, aka log messages
  def parse_plist(plist_file_or_xml)
    plist_hash = Plist::parse_xml(plist_file_or_xml)

    # We want the 'All Samples' plist key which contains our test results
    plist_hash['All Samples']
  end

  # Converts the log messages from the plist into an intermediate test array so that
  # it can be processed with the (see #generate_junit_report) method.  The test hash should
  # be similar to:
  # {:name => 'test name',
  #  :log_type => 'Pass|Fail|etc',
  #  :log_message_type => 4|5|7,
  #  :timestamp => '2014',
  #  :messages => [ {:message => 'debug message',
  #                  :log_type => 0|3|8,
  #                  :log_message_type => 'ERROR|SCREENSHOT|DEBUG|ETC',
  #                  :timestamp => '2014'} ]}
  #
  # @param [Array] log_messages the unprocessed log messages from the plist
  # @return [Array] the list of tests in an understandable format
  def convert_log_messages_to_tests(log_messages)
    # The tests array to return
    tests = []

    # The current test we are processing
    current_test = nil

    log_messages.each do |log_message|
      # Pull our relevant fields from the log message in from the plist
      message = log_message['Message']
      log_type = log_message['LogType']
      timestamp = log_message['Timestamp']
      screenshot = log_message['Screenshot']
      log_message_type = log_message['Type']
      children = log_message['children']

      # If our log message type is the START type, initialize a new current test for us to use
      if !current_test && log_message_type == START_TEST
        current_test = {:name => message,
                        :log_type => log_type,
                        :log_message_type => log_message_type,
                        :timestamp => timestamp,
                        :messages => []}

        # In order to add a message to our current test, the message type can't be a begin or end node
      elsif current_test && log_message_type != END_FAILURE && log_message_type != END_SUCCESS && log_message_type != START_TEST
        message = log_message_type == SCREENSHOT ? screenshot : message
        message = "#{message} \nView Dump: \n#{JSON.pretty_generate(children)}\n" if children
        current_test[:messages] << {:message => message,
                                    :log_type => log_type,
                                    :log_message_type => log_message_type,
                                    :timestamp => timestamp}

        # If the current test is present and the message type is an end node, then add the current test to our tests and
        # reset the current test
      elsif current_test && (log_message_type == END_FAILURE || log_message_type == END_SUCCESS)
        current_test[:end_message_type] = log_message_type
        current_test[:elapsed_time] = timestamp.to_time - current_test[:timestamp].to_time
        tests << current_test
        current_test = nil
      end
    end

    tests
  end

  # After the tests have been processed into an intermediate state from (@see #convert_log_messages_to_tests),
  # the tests can then me transformed into a junit style xml output
  #
  # @param tests [Array] array of processed plist tests as generated from (@see #convert_log_messages_to_tests)
  # @param [String] junit_class_name the class name to append to each <testcase/> tag
  # @return [String] a junit xml string
  def generate_junit_report(tests, junit_class_name)
    # Gather our root <testsuite/> tag information
    total_tests = tests.size
    total_errors = tests.reduce(0) { |sum, t| sum + t[:messages].count { |m| m[:log_message_type] == LOG_ERROR } }
    total_failures = tests.count { |t| t[:end_message_type] == END_FAILURE }
    starting_time = tests.empty? ? '' : tests[0][:timestamp]
    total_time = tests.reduce(0) { |sum, t| sum + t[:elapsed_time] }

    # Begin building our junit xml using Nokogiri
    builder = Nokogiri::XML::Builder.new do |xml|
      # Our root xml tag should be a <testsuite/> tag with the number of tests, duration, failures, etc
      xml.testsuite(:tests => total_tests, :errors => total_errors, :failures => total_failures, :timestamp => starting_time, :time => total_time) {
        # For each of our tests we want to create a <testcase/> tag
        tests.each do |test|
          xml.testcase(:name => test[:name], :time => test[:elapsed_time], :classname => junit_class_name) {

            # If the test case ended in a failure, we want to add a <failure/> tag
            if test[:end_message_type] == END_FAILURE
              xml.failure(:message => test[:name], :type => test[:log_type])
            end

            # Add the messages from the test to the test case tag
            test[:messages].each do |message|
              case message[:log_message_type]

                # For debug and screenshot, we'll convert the messages to a <system-out/> tag
                when LOG_DEBUG, LOG_DEFAULT, SCREENSHOT
                  xml.send(:"system-out") {
                    xml.text message[:message]
                  }

                # This is likely the LOG_ERROR case which we'll record it as an <error/> tag
                else
                  xml.error(:message => message[:message], :type => message[:log_type])
              end
            end
          }
        end
      }
    end

    builder.to_xml
  end

  public

  # Process the plist file and generates a JUnit style xml string
  #
  # @param [String] plist_file_or_xml file name or xml of the UIAutomation plist file
  # @param [String] junit_class_name the class name to append to each <testcase/> tag
  # @return [String] the JUnit style xml
  def generate_reports(plist_file_or_xml, junit_class_name)
    log_messages = parse_plist(plist_file_or_xml)
    tests = convert_log_messages_to_tests(log_messages)
    generate_junit_report(tests, junit_class_name)
  end

end
