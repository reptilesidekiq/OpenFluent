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

module Fluent
  module Test
    class ParserTestDriver
      def initialize(klass, &block)
        if klass.is_a?(Class)
          if block
            # Create new class for test w/ overwritten methods
            #   klass.dup is worse because its ancestors does NOT include original class name
            klass = Class.new(klass)
            klass.module_eval(&block)
          end
          @instance = klass.new
        else
          @instance = klass
        end
        @config = Config.new
      end

      attr_reader :instance, :config

      def configure(conf, use_v1 = false)
        if conf.is_a?(Fluent::Config::Element)
          @config = conf
        else
          @config = Config::Element.new('ROOT', '', conf, [])
        end
        @instance.configure(@config)
        self
      end

      def parse(text)
        @instance.parse(text)
      end
    end
  end
end
