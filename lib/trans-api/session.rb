require 'singleton'


module Trans
  module Api

    #
    # Session class
    #

    class Session

      include Singleton

      ENCRYPTION = [ :required, :preferred, :tolerated ]


      def initialize
        self.reload!
      end

      def fields
        @fields.map{|k,v| k}
      end

      def fields_and_values
        @fields
      end

      def errors
        @last_error
      end

      def stats!
        @client.connect.session_stats
      end

      def save!
        # reject unchanged fields
        changed = @fields.reject{|k,v| @old_fields[k] == v }
        if changed.size > 0
          # call api, and store changed fields
          @client.connect.session_set changed
          # refresh
          self.reset!
        end
      end

      # reload current object
       def reset!
        @fields = @client.connect.session_get
        @old_fields = @fields.clone
        @last_error = {error: "", message: ""}
        nil
      end

      def reload!
        @client = Client.new
        self.reset!

        # map fields to accessors
        @fields.each do |k, v|
          # setter
          self.metaclass.send(:define_method, "#{k}=") do |value|
            if v.class == value.class || value.is_a?(::Boolean)
              @fields[k] = value
            else
              msg = "invalid type: #{value.class}, expected: #{v.class}"
              @last_error[:message] = msg
              raise msg
            end
          end
          # getter
          self.metaclass.send(:define_method, "#{k}") do
            @fields[k]
          end
        end
      end

      def update_blocklist!
        @client.connect.blocklist_update
      end

      def connected?
        begin
          s = self.stats!
          return s.is_a?(Hash)
        rescue StandardError
          false
        end
      end

      # blocklist-update


      def metaclass
        class << self; self; end
      end

      class << self
        def alt_speed_time_day_options
          ret = []
          ret << ["Sunday", 1]
          ret << ["Monday", 2]
          ret << ["Tuesday", 4]
          ret << ["Wednesday", 8]
          ret << ["Thursday", 16]
          ret << ["Friday", 32]
          ret << ["Weekdays", 62]
          ret << ["Saturday", 64]
          ret << ["Weekends", 65]
          ret << ["Every Day", 127]
          ret.sort{|a,b| a.last <=> b.last}
        end

        def encryption_levels
          ["required", "preferred", "tolerated"].map{|t| [t.humanize, t]}
        end
      end
    end

  end
end
