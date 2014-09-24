module Trans
  module Api


    class Connect

      require 'base64'
      require 'json'
      require 'nokogiri'
      require 'net/http'
      require 'timeout'


      METHODS = {
        session_get: {method: "session-get", tag: 0},
        session_set: {method: "session-set", tag: 1},
        session_stats: {method: "session-stats", tag: 2},
        session_close: {method: "session-close", tag: 3},
        torrent_get: {method: "torrent-get", tag: 4},
        torrent_set: {method: "torrent-set", tag: 5},
        torrent_start: {method: "torrent-start", tag: 6},
        torrent_start_now: {method: "torrent-start-now", tag: 7},
        torrent_stop: {method: "torrent-stop", tag: 8},
        torrent_add: {method: "torrent-add", tag: 9},
        torrent_remove: {method: "torrent-remove", tag: 10},
        torrent_verify: {method: "torrent-verify", tag: 11},
        torrent_reannounce: {method: "torrent-reannounce", tag: 12},
        torrent_set_location: {method: "torrent-set-location", tag: 13},
        blocklist_update: {method: "blocklist-update", tag: 14},
        port_test: {method: "port-test", tag: 15},
        queue_move_top: {method: "queue-move-top", tag: 16},
        queue_move_up: {method: "queue-move-up", tag: 17},
        queue_move_down: {method: "queue-move-down", tag: 18},
        queue_move_bottom: {method: "queue-move-bottom", tag: 19}
      }



      def initialize(options={})
        if options.empty?
          @conn = Client::DEFAULT
        elsif !options.nil?
          @conn = options
        end
        self.reset_conn
      end


      def reset_conn
        @conn[:headers] = {}
        # authentication
        secret = ::Base64.encode64("#{@conn[:user]}:#{@conn[:pass]}")
        @conn[:headers]["Authorization"]= "Basic #{secret}" if @conn.include?(:user) && @conn.include?(:pass)
        # placeholder
        @conn[:headers]["X-Transmission-Session-Id"] = ""
        self
      end


      # handles

      def session_get
        self.get_method(:session_get) {|b| b.gsub("-","_")}
      end

      def session_stats
        self.get_method(:session_stats) {|b| b.gsub("-","_")}
      end

      def session_set(arguments={})
        self.get_method(:session_set, arguments)
      end

      def session_close
        self.get_method(:session_close)
      end

      def torrent_get(fields = [:id, :name, :status], ids = [])
        arguments = { fields: fields }
        arguments[:ids] = ids unless ids.empty?
        args = self.get_method(:torrent_get, arguments)
        args[:torrents]
      end

      def torrent_set(arguments={}, ids = [])
        arguments[:ids] = ids unless ids.empty?
        args = self.get_method(:torrent_set, arguments)
        args[:torrents]
      end

      def torrent_start(ids = [])
        arguments = {}
        arguments[:ids] = ids unless ids.empty?
        args = self.get_method(:torrent_start, arguments)
        args[:torrents]
      end

      def torrent_start_now(ids = [])
        arguments = {}
        arguments[:ids] = ids unless ids.empty?
        args = self.get_method(:torrent_start_now, arguments)
        args[:torrents]
      end

      def torrent_stop(ids = [])
        arguments = {}
        arguments[:ids] = ids unless ids.empty?
        args = self.get_method(:torrent_stop, arguments)
        args[:torrents]
      end

      def torrent_add(arguments={})
        args = self.get_method(:torrent_add, arguments) {|b| b.gsub("-","_")}
        # omiting BUG: https://trac.transmissionbt.com/ticket/5614
        return args[:torrent_duplicate] if args.include?(:torrent_duplicate)
        args[:torrent_added]
      end

      def torrent_remove(arguments={}, ids=[])
        arguments[:ids] = ids unless ids.empty?
        self.get_method(:torrent_remove, arguments) {|b| b.gsub("-","_")}
      end

      def torrent_verify(ids = [])
        arguments = {}
        arguments[:ids] = ids unless ids.empty?
        self.get_method(:torrent_verify, arguments)
      end

      def torrent_reannounce(ids=[])
        arguments = {}
        arguments[:ids] = ids unless ids.empty?
        self.get_method(:torrent_reannounce, arguments)
      end

      def torrent_set_location(arguments={}, ids=[])
        arguments[:ids] = ids unless ids.empty?
        self.get_method(:torrent_set_location, arguments) {|b| b.gsub("-","_")}
      end

      def blocklist_update
        tm = @conn[:timeout]
        @conn[:timeout] = (@conn[:timeout] + 5) * 3
        arg = self.get_method(:blocklist_update) {|b| b.gsub("-","_")}
        @conn[:timeout] = tm
        arg
      end

      def port_test
        self.get_method(:port_test) {|b| b.gsub("-","_")}
      end


      def queue_move_top(ids=[])
        arguments = {}
        arguments[:ids] = ids unless ids.empty?
        self.get_method(:queue_move_top, arguments) {|b| b.gsub("-","_")}
      end

      def queue_move_up(ids=[])
        arguments = {}
        arguments[:ids] = ids unless ids.empty?
        self.get_method(:queue_move_up, arguments) {|b| b.gsub("-","_")}
      end

      def queue_move_down(ids=[])
        arguments = {}
        arguments[:ids] = ids unless ids.empty?
        self.get_method(:queue_move_down, arguments) {|b| b.gsub("-","_")}
      end

      def queue_move_bottom(ids=[])
        arguments = {}
        arguments[:ids] = ids unless ids.empty?
        self.get_method(:queue_move_bottom, arguments) {|b| b.gsub("-","_")}
      end




      # request


      protected

      def get_method(method_name, arguments=nil, &block)
        data = METHODS[method_name]
        data[:arguments] = argument_name_to_api(arguments) unless arguments.nil?
        ret = self.do(:post, data)
        body = ret[:response].body
        # call block with body data (for gsub etc.)
        body = block.call(body) if block.is_a?(Proc)
        session = JSON.parse(body, {symbolize_names: true})
        # puts session
        raise session[:result] unless valid? session, data[:tag]
        session[:arguments]
      end

      def do(method = :get, data = nil)
        headers = @conn[:headers]
        uri = URI.parse "http://localhost/"
        uri.scheme = @conn[:scheme]
        uri.host = @conn[:host]
        uri.port = @conn[:port]
        uri.path = @conn[:path]
        # request
        http = Net::HTTP.new uri.host, uri.port
        resp = nil
        Timeout::timeout(@conn[:timeout]) do
          # sleep 5
          if method == :get
            resp = http.get(uri.request_uri, data.to_json, headers)
          elsif method == :post
            resp = http.post(uri.request_uri, data.to_json, headers)
          else
            raise "not implemented #{method} request!!"
          end
        end
        # authorize via session id
        if resp.code.to_i == 409
          tmp = Nokogiri::HTML resp.body
          session_id = tmp.search('p code', '//X-Transmission-Session-Id').first.text.gsub("X-Transmission-Session-Id: ",'')
          @conn[:headers]["X-Transmission-Session-Id"] = session_id
          # recursion!!!!
          return self.do(:post, data)
        end
        ret = {request: http, response: resp}
        handle_request_error(ret, data)
        ret
      end

      def valid?(body, tag)
        body[:result] == "success" && body[:tag] == tag
      end

      def argument_name_to_api(options = {})
        #TODO: fix nested arguments
        ret = {}
        options.each do |k,v|
          ret[k.to_s.gsub('_','-')] = v
        end
        ret
      end

      # error handling
      def handle_request_error(ret, data)
        raise "error handling: #{data[:method]}, #{request_str ret[:response]}" if ret[:response].code.to_i != 200
      end

      def request_str(response)
        ret = []
        ret << "[code: #{response.code}]"
        ret << "[body: #{response.body}]"
        ret.join "\n"
      end

    end

  end
end
