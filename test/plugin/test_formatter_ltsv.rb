require_relative '../helper'
require 'fluent/test/driver/formatter'
require 'fluent/plugin/formatter_ltsv'

class LabeledTSVFormatterTest < ::Test::Unit::TestCase
  def setup
    @time = event_time
  end

  def create_driver(conf = "")
    Fluent::Test::Driver::Formatter.new(Fluent::Plugin::LabeledTSVFormatter).configure(conf)
  end

  def tag
    "tag"
  end

  def record
    {'message' => 'awesome'}
  end

  def test_config_params
    d = create_driver
    assert_equal "\t", d.instance.delimiter
    assert_equal  ":", d.instance.label_delimiter

    d = create_driver(
      'delimiter'       => ',',
      'label_delimiter' => '=',
    )

    assert_equal ",", d.instance.delimiter
    assert_equal "=", d.instance.label_delimiter
  end

  def test_format
    d = create_driver({})
    formatted = d.instance.format(tag, @time, record)

    assert_equal("message:awesome\n", formatted)
  end

  def test_format_with_tag
    d = create_driver('include_tag_key' => 'true')
    formatted = d.instance.format(tag, @time, record)

    assert_equal("message:awesome\ttag:tag\n", formatted)
  end

  def test_format_with_time
    d = create_driver('include_time_key' => 'true', 'time_format' => '%Y')
    formatted = d.instance.format(tag, @time, record)

    assert_equal("message:awesome\ttime:#{Time.now.year}\n", formatted)
  end

  def test_format_with_customized_delimiters
    d = create_driver(
      'include_tag_key' => 'true',
      'delimiter'       => ',',
      'label_delimiter' => '=',
    )
    formatted = d.instance.format(tag, @time, record)

    assert_equal("message=awesome,tag=tag\n", formatted)
  end
end

