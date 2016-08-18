#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'optparse'
require 'msgpack'

require 'fluent/msgpack_factory'
require 'fluent/formatter'
require 'fluent/plugin'
require 'fluent/config/element'

class FluentUnpacker
  SUBCOMMAND = %w(cat head formats)
  HELP_TEXT = <<HELP
Usage: fluent-unpacker <command> [<args>]

Commands of fluent-unpacker:
   cat     :     Read files sequentially, writing them to standard output.
   haed    :     Display the beginning of a text file.
   foramts :     Display plugins that you can use.

See 'fluent-unpacker <command> --help' for more information on a specific command.
HELP

  def initialize(argv = ARGV)
    @argv = argv
  end

  def call
    command_class = Command.const_get(command)
    command_class.new(@argv).call
  end

  private

  def command
    command = @argv.shift
    if !command || !SUBCOMMAND.include?(command)
      usage "Required subcommand : #{SUBCOMMAND.join(' | ')}"
    end

    command.split('_').map(&:capitalize).join('')
  end

  def usage(msg = nil)
    puts HELP_TEXT
    puts "Error: #{msg}" if msg
    exit 1
  end
end

module Command
  class Base
    DEFAULT_OPTIONS = {
      format: :out_file
    }

    def initialize(argv = ARGV)
      @argv = argv
      @params = {}
      if i = @argv.index('--')
        @params = @argv[i+1..-1].reduce({}) do |acc, e|
          k, v = e[1..-1].split('=')
          acc.merge(k => v)
        end
        @argv = @argv[0...i]
      end

      @options = DEFAULT_OPTIONS.dup
      @opt_parser = OptionParser.new do |opt|
        opt.banner = "Usage: fluent-unpacker #{self.class.to_s.split('::').last.downcase} [options] file [-- <params>]"

        opt.separator 'Options:'

        opt.on('-f TYPE', '--format', 'configure output format') do |v|
          @options[:format] = v.to_sym
        end

        opt.on('-p DIR', '--plugins', 'add library path') do |v|
          @options[:plugins] = v
        end
      end
    end

    def call
      raise NotImplementedError, 'BUG: command  MUST implement this method'
    end

    private

    def unpacker(io)
      MessagePack::Unpacker.new(io)
    end

    def usage(msg = nil)
      puts @opt_parser.to_s
      puts "Error: #{msg}" if msg
      exit 1
    end

    def lookup_formatter(format, params)
      conf = Fluent::Config::Element.new('ROOT', '', params, [])
      formatter = Fluent::Plugin.new_formatter(format)

      if formatter.respond_to?(:configure)
        formatter.configure(conf)
      end
      formatter
    rescue => e
      usage e
    end
  end

  class Head < Base
    DEFAULT_HEAD_OPTIONS = {
      count: 5
    }

    def initialize(argv = ARGV)
      super
      @options.merge!(DEFAULT_HEAD_OPTIONS)
      @path = configure_option_parser
    end

    def call
      @formatter = lookup_formatter(@options[:format], @params)

      File.open(@path, 'r') do |io|
        i = 0
        unpacker(io).each do |(time, record)|
          break if i == @options[:count]
          i += 1
          puts @formatter.format(@path, time, record) # tag is use for tag
        end
      end
    end

    private

    def configure_option_parser
      @opt_parser.on('-n COUNT', 'Set the number of lines to display') do |v|
        @options[:count] = v.to_i
      end

      path = @opt_parser.parse(@argv)

      case
      when path.empty?
        usage 'Path is required'
      when !File.exist?(path.first)
        usage "#{path.first} is not found"
      when @options[:count] < 1
        usage "illegal line count -- #{@options[:count]}"
      else
        path.first
      end
    end
  end

  class Cat < Base
    def initialize(argv = ARGV)
      super
      @path = configure_option_parser
    end

    def call
      @formatter = lookup_formatter(@options[:format], @params)

      File.open(@path, 'r') do |io|
        unpacker(io).each do |(time, record)|
          puts @formatter.format(@path, time, record) # @path is use for tag
        end
      end
    end

    def configure_option_parser
      path = @opt_parser.parse(@argv)
      usage 'Path is required' if path.empty?
      usage "#{path.first} is not found" unless File.exist?(path.first)
      path.first
    end
  end

  class Formats < Base
    def call
      pf = Fluent::Plugin::FORMATTER_REGISTRY.paths.last

      if prefix = Fluent::Plugin::FORMATTER_REGISTRY.dir_search_prefix
        Dir.glob("#{pf}/#{prefix}*").each do |e|
          require File.absolute_path(e)
        end

        $LOAD_PATH.map do |lp|
          Dir.glob("#{lp}/#{prefix}*").each do |e|
            require e
          end
        end

        specs = Gem::Specification.flat_map { |spec| spec.lib_files }.select do |e|
          e.include?(prefix)
        end
        specs.each do |e|
          require File.absolute_path(e)
        end
      end

      puts Fluent::Plugin::FORMATTER_REGISTRY.map.keys
    end
  end
end
