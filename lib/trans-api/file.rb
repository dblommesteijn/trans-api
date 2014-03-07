

module Trans
  module Api

    class File

      def initialize(options={})
        @torrent = options.delete :torrent
        @torrent_fields = options.delete :fields
        @fields = options[:file]

        # set default stats
        @torrent_fields[:files_unwanted] ||= []
        @torrent_fields[:files_wanted] ||= []
#       if @fields[:fileStat][:wanted] == false
#         @torrent_fields[:files_unwanted] << self.id
#       else
#         @torrent_fields[:files_wanted] << self.id
#       end

        @client = Client.new
      end

      def id
        @fields[:id]
      end

      def name
        @fields[:name]
      end

      def stat
        @fields[:fileStat]
      end

      def bytes_completed
        @fields[:bytesCompleted]
      end

      def bytes_total
        @fields[:length]
      end

      def priority
        @fields[:fileStat][:priority]
      end

      def unwant
        @torrent_fields[:files_wanted].delete self.id if @torrent_fields[:files_wanted].include? self.id
        @torrent_fields[:files_unwanted] << self.id unless @torrent_fields[:files_unwanted].include? self.id
        @fields[:fileStat][:wanted] = false
      end

      def want
        @torrent_fields[:files_wanted] << self.id unless @torrent_fields[:files_wanted].include? self.id
        @torrent_fields[:files_unwanted].delete self.id if @torrent_fields[:files_unwanted].include? self.id
        @fields[:fileStat][:wanted] = true
      end

      def wanted?
        @fields[:fileStat][:wanted]
      end

    end

  end
end
