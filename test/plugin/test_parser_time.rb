require_relative '../helper'
require 'fluent/test/driver/parser'
require 'fluent/plugin/parser'

class TimeParserTest < ::Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  def test_call_with_parse
    parser = Fluent::TextParser::TimeParser.new(nil)

    assert(parser.parse('2013-09-18 12:00:00 +0900').is_a?(Fluent::EventTime))

    time = str2time('2013-09-18 12:00:00 +0900')
    assert_equal(time, parser.parse('2013-09-18 12:00:00 +0900'))
  end

  def test_parse_with_strptime
    parser = Fluent::TextParser::TimeParser.new('%d/%b/%Y:%H:%M:%S %z')

    assert(parser.parse('28/Feb/2013:12:00:00 +0900').is_a?(Fluent::EventTime))

    time = str2time('28/Feb/2013:12:00:00 +0900', '%d/%b/%Y:%H:%M:%S %z')
    assert_equal(time, parser.parse('28/Feb/2013:12:00:00 +0900'))
  end

  def test_parse_nsec_with_strptime
    parser = Fluent::TextParser::TimeParser.new('%d/%b/%Y:%H:%M:%S:%N %z')

    assert(parser.parse('28/Feb/2013:12:00:00:123456789 +0900').is_a?(Fluent::EventTime))

    time = str2time('28/Feb/2013:12:00:00:123456789 +0900', '%d/%b/%Y:%H:%M:%S:%N %z')
    assert_equal_event_time(time, parser.parse('28/Feb/2013:12:00:00:123456789 +0900'))
  end

  def test_parse_with_invalid_argument
    parser = Fluent::TextParser::TimeParser.new(nil)

    [[], {}, nil, true, 10000, //, ->{}, '', :symbol].each { |v|
      assert_raise Fluent::ParserError do
        parser.parse(v)
      end
    }
  end
end
