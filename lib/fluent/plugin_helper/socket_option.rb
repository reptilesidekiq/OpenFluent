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

require 'socket'

# this module is only for Socket/Server plugin helpers
module Fluent
  module PluginHelper
    module SocketOption
      FORMAT_STRUCT_LINGER  = 'I!I!' # { int l_onoff; int l_linger; }
      FORMAT_STRUCT_TIMEVAL = 'L!L!' # { time_t tv_sec; suseconds_t tv_usec; }

      def socket_option_validate!(protocol, resolve_name: nil, linger_timeout: nil, recv_timeout: nil, send_timeout: nil, certopts: nil)
        unless resolve_name.nil?
          if protocol != :tcp && protocol != :udp && protocol != :tls
            raise ArgumentError, "BUG: resolve_name in available for tcp/udp/tls"
          end
        end
        if linger_timeout
          if protocol != :tcp && protocol != :tls
            raise ArgumentError, "BUG: linger_timeout is available for tcp/tls"
          end
        end
        if certopts
          if protocol != :tls
            raise ArgumentError, "BUG: certopts is available only for tls"
          end
        else
          if protocol == :tls
            raise ArgumentError, "BUG: certopts (certificate options) not specified for TLS"
            socket_option_certopts_validate!(certopts)
          end
        end
      end

      def socket_option_certopts_validate!(certopts)
        raise "not implemented yet"
      end

      def socket_option_set(sock, resolve_name: nil, linger_timeout: nil, recv_timeout: nil, send_timeout: nil, certopts: nil)
        unless resolve_name.nil?
          sock.do_not_reverse_lookup = !resolve_name
        end
        if linger_timeout
          optval = [1, linger_timeout.to_i].pack(FORMAT_STRUCT_LINGER)
          socket_option_set_one(sock, :SO_LINGER, optval)
        end
        if recv_timeout
          optval = [recv_timeout.to_i, 0].pack(FORMAT_STRUCT_TIMEVAL)
          socket_option_set_one(sock, :SO_RCVTIMEO, optval)
        end
        if send_timeout
          optval = [send_timeout.to_i, 0].pack(FORMAT_STRUCT_TIMEVAL)
          socket_option_set_one(sock, :SO_SNDTIMEO, optval)
        end
        # TODO: certopts for TLS
        sock
      end

      def socket_option_set_one(sock, option, value)
        sock.setsockopt(Socket::SOL_SOCKET, option, value)
      rescue => e
        log.warn "failed to set socket option", sock: sock.class, option: option, value: value, error: e
      end
    end
  end
end
