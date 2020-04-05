module Sunspot
  module Rails
    class LogSubscriber < ActiveSupport::LogSubscriber
      def self.runtime=(value)
        Thread.current['sorl_runtime'] = value
      end

      def self.runtime
        Thread.current['sorl_runtime'] ||= 0
      end

      def self.reset_runtime
        rt = runtime
        self.runtime = 0
        rt
      end

      class << self
        attr_writer :logger
      end

      def self.logger
        @logger if defined?(@logger)
      end

      def logger
        self.class.logger || ::Rails.logger
      end

      def request(event)
        self.class.runtime += event.duration
        return unless logger.debug?

        name = '%s (%.1fms)' % ['SOLR Request', event.duration]

        # produces: path=select parameters={
        #   fq: ["type:Tag"], q: "rossi", fl: "* score", qf: "tag_name_text", defType: "edismax", start: 0, rows: 20
        # }
        path = color(event.payload[:path], BOLD, true)
        parameters = event.payload[:parameters].map do |k, v|
          v = "\"#{v}\"" if v.is_a? String
          v = v.to_s.gsub(/\\/, '') # unescape
          "#{k}: #{color(v, BOLD, true)}"
        end.join(', ')
        request = "path=#{path} parameters={#{parameters}}"

        debug "  #{color(name, GREEN, true)}  [ #{request} ]"
        debug "===> SOLR REQUEST EVENT: #{event.inspect}"
      end
    end
  end
end

Sunspot::Rails::LogSubscriber.attach_to :rsolr
