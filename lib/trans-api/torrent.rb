module Trans
  module Api


    #
    # Torrent class
    #

    class Torrent

      # torrent status value
      STATUS = [ :stopped, :checkQueue, :checkFiles, :downloadQueue, :downloading, :seedQueue, :seeding, :isolated ]

      # torrent get fields
      ACCESSOR_FIELDS = [
        :activityDate, :addedDate, :bandwidthPriority, :comment, :corruptEver, :creator, :dateCreated, :desiredAvailable,
        :doneDate, :downloadDir, :downloadedEver, :downloadLimit, :downloadLimited, :error, :errorString, :eta, :files,
        :fileStats, :hashString, :haveUnchecked, :haveValid, :honorsSessionLimits, :id, :isFinished, :isPrivate, :isStalled,
        :leftUntilDone, :magnetLink, :manualAnnounceTime, :maxConnectedPeers, :metadataPercentComplete, :name, :peer_limit,
        :peers, :peersConnected, :peersFrom, :peersGettingFromUs, :peersSendingToUs, :percentDone, :pieces, :pieceCount,
        :pieceSize, :priorities, :queuePosition, :rateDownload, :rateUpload, :recheckProgress, :secondsDownloading,
        :secondsSeeding, :seedIdleLimit, :seedIdleMode, :seedRatioLimit, :seedRatioMode, :sizeWhenDone, :startDate, :status,
        :trackers, :trackerStats, :totalSize, :torrentFile, :uploadedEver, :uploadLimit, :uploadLimited, :uploadRatio,
        :wanted, :webseeds, :webseedsSendingToUs ]

      # torrent set fields
      MUTATOR_FIELDS = [ :bandwidthPriority, :downloadLimit, :downloadLimited, :files_wanted, :files_unwanted, :honorsSessionLimits,
        :ids, :location, :peer_limit, :priority_high, :priority_low, :priority_normal, :queuePosition, :seedIdleLimit,
        :seedIdleMode, :seedRatioLimit, :seedRatioMode, :trackerAdd, :trackerRemove, :trackerReplace, :uploadLimit, :uploadLimited ]

      # torrent add fields
      ADD = [ :cookies, :download_dir, :filename, :metainfo, :paused, :peer_limit, :bandwidthPriority, :files_wanted,
        :files_unwanted, :priority_high, :priority_low, :priority_normal ]

      DELETE = [ :ids, :delete_local_data ]

			LOCATION = [ :ids, :move, :location ]


      @@default_fields = [ :id, :name, :status ]


      # constructor
      def initialize(options={})
        @client = Client.new
        @fields = options[:torrent] if options.include? :torrent
        @old_fields = @fields.clone
        @last_error = {error: "", message: ""}

        self.attach_methods!

      end

      # placeholder for fields
      def metaclass
        class << self; self; end
      end

      def status_name
        STATUS[self.status]
      end

      def save!
        # reject unchanged fields
        changed = @fields.reject{|k,v| @old_fields[k] == v}
				changed.reject!{|k,v| !MUTATOR_FIELDS.include?(k) }
				changed.reject!{|k,v| v.class == Array && v.empty? }
        if changed.size > 0
          # call api, and store changed fields
          @client.connect.torrent_set changed, [self.id]
          @old_fields = @fields.clone
        end
      end

			def fields
				@fields
			end

			def files_objects
				ret = []
				i = -1
				torrent = @client.connect.torrent_get([:files, :fileStats], [self.id]).first
				@fields[:files] = torrent[:files]
				@fields[:fileStatus] = torrent[:fileStats]
				self.files.each{ |f| ret << Trans::Api::File.new( torrent: self, fields: @fields,
																												 file: f.merge(id: (i+=1)).merge(fileStat: torrent[:fileStats][i])) }
				ret
			end

      def reset!
        @fields = @client.connect.torrent_get( @fields.map{|k,v| k}, [self.id]).first
        @old_fields = @fields.clone
        @last_error = {error: "", message: ""}
      end

      def start!
        @client.connect.torrent_start [self.id]
      end

      def stop!
        @client.connect.torrent_stop [self.id]
      end

			def verify!
        @client.connect.torrent_verify [self.id]
			end

			def reannounce!
        @client.connect.torrent_reannounce [self.id]
			end

			def set_location(file, move = false)
        @client.connect.torrent_set_location({location: file, move: move}, [self.id])
			end

      def delete!(options={})
        options[:delete_local_data] = false unless options.include? :delete_local_data # optional
        @client.connect.torrent_remove options, [self.id]
      end

      class << self
        def all
          torrents = Client.new.connect.torrent_get( @@default_fields )
          torrents.map{|t| Torrent.new torrent: t}
        end

        def find(id)
          torrents = Client.new.connect.torrent_get( @@default_fields , [id])
          remap = torrents.map{|t| Torrent.new torrent: t }
          return remap.first if torrents.size == 1
          return nil if torrents.empty?
          remap
        end

        def start_all
          torrents = Client.new.connect.torrent_get [:id, :status]
          remap = torrents.map{ |t| Torrent.new torrent: t }
          Client.new.connect.torrent_start remap.map{|t| t.id}
        end

        def stop_all
          torrents = Client.new.connect.torrent_get [:id, :status]
          remap = torrents.map{ |t| Torrent.new torrent: t }
          Client.new.connect.torrent_stop remap.map{|t| t.id}
        end

				def delete_all(options={})
					client = Client.new
					options[:delete_local_data] = false unless options.include? :delete_local_data # optional
					client.connect.torrent_remove options
				end

        def add_file(filename, options={})
          raise "file not found: #{filename}" unless ::File.exists? filename
          client = Client.new
          options[:filename] = filename
          torrent = client.connect.torrent_add options
          torrent = client.connect.torrent_get( @@default_fields, [torrent[:id]]).first
          Torrent.new torrent: torrent
        end

        def default_fields=(list=[])
          @@default_fields << :id unless list.include? :id
          @@default_fields |= list
        end
      end


      protected

      # define helper methods for setting and getting field information
      def attach_methods!

        # NOTE: not all accessor fields are mutators as well!!

        MUTATOR_FIELDS.each do |k|
          # setter
          self.metaclass.send(:define_method, "#{k}=") do |value|
            unless @fields.include? k
              fields = @client.connect.torrent_get([k], [self.id]).first
              @fields.merge! fields
              @old_fields.merge! fields
            end
            @fields[k] = value
          end
        end


        ACCESSOR_FIELDS.each do |k|
          # getter
          self.metaclass.send(:define_method, "#{k}") do
            # request handler to get new field
            unless @fields.include? k
              fields = @client.connect.torrent_get([k], [self.id]).first
              @fields.merge! fields
              @old_fields.merge! fields
            end
            @fields[k]
          end
        end
      end

    end
  end
end
