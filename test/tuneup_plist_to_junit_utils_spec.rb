require 'tuneup_plist_to_junit_utils'

describe TuneUpPlistToJunitUtils, '#generate_reports' do
  it 'generates the correct output for no tests' do
    utils = TuneUpPlistToJunitUtils.new
    utils.generate_reports('test/test_plists/no_tests.plist', 'UIAutomation').should eq(File.read('test/expected_outputs/no_tests.xml'))
  end
end

describe TuneUpPlistToJunitUtils, '#generate_reports' do
  it 'generates the correct output for no tests, but with log messages' do
    utils = TuneUpPlistToJunitUtils.new
    utils.generate_reports('test/test_plists/no_tests_with_crud.plist', 'UIAutomation').should eq(File.read('test/expected_outputs/no_tests_with_crud.xml'))
  end
end

describe TuneUpPlistToJunitUtils, '#generate_reports' do
  it 'generates the correct output for a single failure with children' do
    utils = TuneUpPlistToJunitUtils.new
    utils.generate_reports('test/test_plists/single_fail_with_children.plist', 'UIAutomation').should eq(File.read('test/expected_outputs/single_fail_with_children.xml'))
  end
end

describe TuneUpPlistToJunitUtils, '#generate_reports' do
  it 'generates the correct output for a single passing test' do
    utils = TuneUpPlistToJunitUtils.new
    utils.generate_reports('test/test_plists/single_passing.plist', 'UIAutomation').should eq(File.read('test/expected_outputs/single_passing.xml'))
  end
end

describe TuneUpPlistToJunitUtils, '#generate_reports' do
  it 'generates the correct output for a lots of tests with failures/successes' do
    utils = TuneUpPlistToJunitUtils.new
    utils.generate_reports('test/test_plists/all.plist', 'UIAutomation').should eq(File.read('test/expected_outputs/all.xml'))
  end
end