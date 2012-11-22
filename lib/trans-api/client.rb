module Trans
  module Api

    class Client
      DEFAULT = {scheme: "http", host: "localhost", port: 9091, path: "/transmission/rpc", user: "admin", pass: "admin"}

      # construct

      def initialize(options={})
        args = @@config
        args.merge!(options)
        @conn = Connect.new args
      end

      def connect
        @conn
      end

      class << self
        def config=(config = {})
          @@config = config
        end
      end


    end


  end
end
