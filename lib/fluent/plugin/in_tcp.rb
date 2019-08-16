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

require 'fluent/plugin/input'

module Fluent::Plugin
  class TcpInput < Input
    Fluent::Plugin.register_input('tcp', self)

    helpers :server, :parser, :extract, :compat_parameters

    desc 'Tag of output events.'
    config_param :tag, :string
    desc 'The port to listen to.'
    config_param :port, :integer, default: 5170
    desc 'The bind address to listen to.'
    config_param :bind, :string, default: '0.0.0.0'

    desc "The field name of the client's hostname."
    config_param :source_host_key, :string, default: nil, deprecated: "use source_hostname_key instead."
    desc "The field name of the client's hostname."
    config_param :source_hostname_key, :string, default: nil
    desc "The field name of the client's address."
    config_param :source_address_key, :string, default: nil

    config_param :blocking_timeout, :time, default: 0.5

    desc 'The payload is read up to this character.'
    config_param :delimiter, :string, default: "\n" # syslog family add "\n" to each message and this seems only way to split messages in tcp stream

    def configure(conf)
      compat_parameters_convert(conf, :parser)
      parser_config = conf.elements('parse').first
      unless parser_config
        raise Fluent::ConfigError, "<parse> section is required."
      end
      super
      @_event_loop_blocking_timeout = @blocking_timeout
      @source_hostname_key ||= @source_host_key if @source_host_key

      @parser = parser_create(conf: parser_config)
    end

    def multi_workers_ready?
      true
    end

    def start
      super

      del_size = @delimiter.length
      if @_extract_enabled && @_extract_tag_key
        server_create(:in_tcp_server_single_emit, @port, bind: @bind, resolve_name: !!@source_hostname_key) do |data, conn|
          conn.buffer << data
          buf = conn.buffer
          pos = 0
          while i = buf.index(@delimiter, pos)
            msg = buf[pos...i]
            pos = i + del_size

            @parser.parse(msg) do |time, record|
              unless time && record
                log.warn "pattern not matched", message: msg
                next
              end

              tag = extract_tag_from_record(record)
              tag ||= @tag
              time ||= extract_time_from_record(record) || Fluent::EventTime.now
              record[@source_address_key] = conn.remote_addr if @source_address_key
              record[@source_hostname_key] = conn.remote_host if @source_hostname_key
              router.emit(tag, time, record)
            end
          end
          buf.slice!(0, pos) if pos > 0
        end
      else
        server_create(:in_tcp_server_batch_emit, @port, bind: @bind, resolve_name: !!@source_hostname_key) do |data, conn|
          conn.buffer << data
          buf = conn.buffer
          pos = 0
          es = Fluent::MultiEventStream.new
          while i = buf.index(@delimiter, pos)
            msg = buf[pos...i]
            pos = i + del_size

            @parser.parse(msg) do |time, record|
              unless time && record
                log.warn "pattern not matched", message: msg
                next
              end

              time ||= extract_time_from_record(record) || Fluent::EventTime.now
              record[@source_address_key] = conn.remote_addr if @source_address_key
              record[@source_hostname_key] = conn.remote_host if @source_hostname_key
              es.add(time, record)
            end
          end
          router.emit_stream(@tag, es)
          buf.slice!(0, pos) if pos > 0
        end
      end
    end
  end
end
