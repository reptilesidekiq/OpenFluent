require_relative '../helper'
require 'fluent/test/driver/parser'
require 'fluent/plugin/parser'

class Apache2ParserTest < ::Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @parser = Fluent::TextParser::ApacheParser.new
    @expected = {
      'user'    => nil,
      'method'  => 'GET',
      'code'    => 200,
      'size'    => 777,
      'host'    => '192.168.0.1',
      'path'    => '/',
      'referer' => nil,
      'agent'   => 'Opera/12.0'
    }
  end

  def test_parse
    @parser.parse('192.168.0.1 - - [28/Feb/2013:12:00:00 +0900] "GET / HTTP/1.1" 200 777 "-" "Opera/12.0"') { |time, record|
      assert_equal(str2time('28/Feb/2013:12:00:00 +0900', '%d/%b/%Y:%H:%M:%S %z'), time)
      assert_equal(@expected, record)
    }
    assert_equal(Fluent::TextParser::ApacheParser::REGEXP, @parser.patterns['format'])
    assert_equal(Fluent::TextParser::ApacheParser::TIME_FORMAT, @parser.patterns['time_format'])
  end

  def test_parse_without_http_version
    @parser.parse('192.168.0.1 - - [28/Feb/2013:12:00:00 +0900] "GET /" 200 777 "-" "Opera/12.0"') { |time, record|
      assert_equal(str2time('28/Feb/2013:12:00:00 +0900', '%d/%b/%Y:%H:%M:%S %z'), time)
      assert_equal(@expected, record)
    }
  end
end
