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

require 'fluent/plugin_helper/http/server'
require 'fluent/plugin_helper/thread'

module Fluent
  module PluginHelper
    module Http
      include Fluent::PluginHelper::Thread

      # @param addr [String] Listen address
      # @param port [String] Listen port
      # @param logger [Logger] logger used in this server
      # @param default_app [Object] This method must have #call.
      def create_http_server(addr:, port:, logger:, default_app: nil)
        unless block_given?
          raise ArgumentError, 'BUG: callback not specified'
        end

        @_http_server = Http::Server.new(addr: addr, port: port, logger: logger, default_app: default_app) do |serv|
          yield(serv)
        end

        _block_until_http_server_start do |notify|
          thread_create(:plugin_helper_http_server) do
            @_http_server.start(notify)
          end
        end
      end

      def stop_http_server
        if @_http_server
          @_http_server.stop
        end
      end

      private

      # To block until server is ready to listen
      def _block_until_http_server_start
        que = Queue.new
        yield(que)
        que.pop
      end
    end
  end
end
