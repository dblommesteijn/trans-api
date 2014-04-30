module Trans
  module Api

    class Client
      DEFAULT = {scheme: "http", host: "localhost", port: 9091, path: "/transmission/rpc", user: "admin", pass: "admin", timeout: 5}

      # construct

      def initialize(options={})
        # @@config ||= {}
        args = @@config || {}
        args.merge!(options)
        @conn = Connect.new args
      end

      def connect
        @conn
      end

      class << self
        def config=(config = {})
          config[:port] = config[:port].to_i if config.include? :port
          if config.include? :timeout
            config[:timeout] = config[:timeout].to_i
          else
            config[:timeout] = DEFAULT[:timeout]
          end
          @@config = config
        end
      end


    end


  end
end
