module Trans
  module Api


    class Connect

      require 'base64'
      require 'json'
      require 'nokogiri'
      require 'net/http'


      METHODS = {
        session_get: {method: "session-get", tag: 0},
        session_set: {method: "session-set", tag: 1},
        session_stats: {method: "session-stats", tag: 2},
        session_close: {method: "session-close", tag: 3},
        torrent_get: {method: "torrent-get", tag: 4},
        torrent_set: {method: "torrent-set", tag: 5},
        torrent_start: {method: "torrent-start", tag: 6},
        torrent_stop: {method: "torrent-stop", tag: 7},
        torrent_add: {method: "torrent-add", tag: 8},
        torrent_remove: {method: "torrent-remove", tag: 9},
        torrent_verify: {method: "torrent-verify", tag: 10},
        torrent_reannounce: {method: "torrent-reannounce", tag: 11},
        torrent_set_location: {method: "torrent-set-location", tag: 12}
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
        data = METHODS[:session_get]
        ret = self.do(:post, data)
        # a little dirty, but works great :)
        session = JSON.parse ret[:response].body.gsub("-","_"), {symbolize_names: true}
        raise session[:result] unless valid? session, data[:tag]
        session[:arguments]
      end

      def session_stats
        data = METHODS[:session_stats]
        ret = self.do(:post, data)
        session = JSON.parse ret[:response].body.gsub("-","_"), {symbolize_names: true}
        raise session[:result] unless valid? session, data[:tag]
        session[:arguments]
      end

      def session_set(arguments={})
        data = METHODS[:session_set]
        data[:arguments] = argument_name_to_api arguments
        ret = self.do :post, data
        session = JSON.parse ret[:response].body, {symbolize_names: true}
        raise session[:result] unless valid? session, data[:tag]
        session[:arguments]
      end


      def session_close
        data = METHODS[:session_close]
        ret = self.do :post, data
        session = JSON.parse ret[:response].body, {symbolize_names: true}
        raise session[:result] unless valid? session, data[:tag]
        session[:arguments]
      end


      def torrent_get(fields = [:id, :name, :status], ids = [])
#        puts "-------------torrent-get request!!!! #{fields}"
        arguments = { fields: fields }
        arguments[:ids] = ids unless ids.empty?
        data = METHODS[:torrent_get]
        data[:arguments] = argument_name_to_api arguments
        ret = self.do(:post, data)
        torrents = JSON.parse ret[:response].body, {symbolize_names: true}
        raise torrents[:result] unless valid? torrents, data[:tag]
        torrents[:arguments][:torrents]
      end

      def torrent_set(arguments={}, ids = [])
#        puts "-------------torrent-set request!!!! #{arguments}"
        arguments[:ids] = ids unless ids.empty?
        data = METHODS[:torrent_set]
        data[:arguments] = argument_name_to_api arguments
        ret = self.do(:post, data)
        torrents = JSON.parse ret[:response].body, {symbolize_names: true}
        raise torrents[:result] unless valid? torrents, data[:tag]
        torrents[:arguments][:torrents]
      end

      def torrent_start(ids = [])
        arguments = {}
        arguments[:ids] = ids unless ids.empty?
        data = METHODS[:torrent_start]
        data[:arguments] = argument_name_to_api arguments
        ret = self.do(:post, data)
        torrents = JSON.parse ret[:response].body, {symbolize_names: true}
        raise torrents[:result] unless valid? torrents, data[:tag]
        torrents[:arguments][:torrents]
      end

      def torrent_start_now(ids = [])
				raise "Not Implemented!!!"
			end

      def torrent_stop(ids = [])
        arguments = {}
        arguments[:ids] = ids unless ids.empty?
        data = METHODS[:torrent_stop]
        data[:arguments] = argument_name_to_api arguments
        ret = self.do(:post, data)
        torrents = JSON.parse ret[:response].body, {symbolize_names: true}
        raise torrents[:result] unless valid? torrents, data[:tag]
        torrents[:arguments][:torrents]
      end

      def torrent_add(arguments={})
#        puts "-------------torrent-add request!!!! #{arguments}"
        data = METHODS[:torrent_add]
        data[:arguments] = argument_name_to_api arguments
        ret = self.do(:post, data)
        torrents = JSON.parse ret[:response].body.gsub("-","_"), {symbolize_names: true}
        raise torrents[:result] unless valid? torrents, data[:tag]
        torrents[:arguments][:torrent_added]
      end

      def torrent_remove(arguments={}, ids=[])
#        puts "-------------torrent-remove request!!!! #{arguments}"
        arguments[:ids] = ids unless ids.empty?
        data = METHODS[:torrent_remove]
        data[:arguments] = argument_name_to_api arguments
        ret = self.do(:post, data)
        torrents = JSON.parse ret[:response].body.gsub("-","_"), {symbolize_names: true}
        raise torrents[:result] unless valid? torrents, data[:tag]
        torrents[:arguments]
      end

			def torrent_verify(ids = [])
				arguments = {}
        arguments[:ids] = ids unless ids.empty?
        data = METHODS[:torrent_verify]
        data[:arguments] = argument_name_to_api arguments
        ret = self.do(:post, data)
        torrents = JSON.parse ret[:response].body, {symbolize_names: true}
        raise torrents[:result] unless valid? torrents, data[:tag]
        torrents[:arguments]
			end

			def torrent_reannounce(ids=[])
				arguments = {}
        arguments[:ids] = ids unless ids.empty?
        data = METHODS[:torrent_reannounce]
        data[:arguments] = argument_name_to_api arguments
        ret = self.do(:post, data)
        torrents = JSON.parse ret[:response].body, {symbolize_names: true}
        raise torrents[:result] unless valid? torrents, data[:tag]
        torrents[:arguments]
			end

			def torrent_set_location(arguments={}, ids=[])
        arguments[:ids] = ids unless ids.empty?
        data = METHODS[:torrent_set_location]
        data[:arguments] = argument_name_to_api arguments
        ret = self.do(:post, data)
        torrents = JSON.parse ret[:response].body.gsub("-","_"), {symbolize_names: true}
        raise torrents[:result] unless valid? torrents, data[:tag]
        torrents[:arguments]
      end

			def queue_move_top
				raise "Not Implemented!!!"
			end

			def queue_move_up
				raise "Not Implemented!!!"
			end

			def queue_move_down
				raise "Not Implemented!!!"
			end

			def queue_move_bottom
				raise "Not Implemented!!!"
			end

			def blocklist_update
				raise "Not Implemented!!!"
			end

			def port_test
				raise "Not Implemented!!!"
			end




      # request

      def do(method = :get, data = nil)
        headers = @conn[:headers]

        uri = URI.parse "http://localhost/"
        uri.scheme = @conn[:scheme]
        uri.host = @conn[:host]
        uri.port = @conn[:port]
        uri.path = @conn[:path]

        # request
        http = Net::HTTP.new uri.host, uri.port
        resp = http.get(uri.request_uri, data.to_json, headers) if method == :get
        resp = http.post(uri.request_uri, data.to_json, headers) if method == :post
        raise "not implemented #{method} request!!" if method != :get && method != :post

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


      private

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
