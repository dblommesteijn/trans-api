
require 'rubygems'
require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../../lib/trans-api")



#
# Unit test for Transmission RPC+json
# https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt
# Revision: 13328 (2012/11/16)
#

class TransTorrentObject < Test::Unit::TestCase

  CONFIG = { host: "localhost", port: 9091, user: "admin", pass: "admin", path: "/transmission/rpc" }

	def setup
    Trans::Api::Client.config = CONFIG

		# add a testing torrent
		file = File.expand_path(File.dirname(__FILE__) + "/torrents/1.torrent")
		@torrent = Trans::Api::Torrent.add_file file, paused: true
		sleep 1
	end

	def teardown
    Trans::Api::Client.config = CONFIG

		# remove the testing torrent
		id = @torrent.id
		@torrent.delete! delete_local_data: true
		self.signal_wait_until(lambda{|t| t.nil?}) do
			Trans::Api::Torrent.find id
		end
	end


  def test_torrent_list_inspect_methods
    # load global configuration
    Trans::Api::Client.config = CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

    # session object
    torrents = Trans::Api::Torrent.all

    #NOTE: only :id, :status, :name are preloaded!!

    unless torrents.empty?
      # loop all available files
      torrents.each do |torrent|
        assert torrent.name.class == String
        assert torrent.status_name.class == Symbol
        assert torrent.activityDate.class == Fixnum
        assert torrent.addedDate.class == Fixnum
        assert torrent.bandwidthPriority.class == Fixnum
        assert torrent.comment.class == String
        assert torrent.corruptEver.class == Fixnum
        assert torrent.creator.class == String
        assert torrent.dateCreated.class == Fixnum
        assert torrent.desiredAvailable.class == Fixnum
        assert torrent.doneDate.class == Fixnum
        assert torrent.downloadDir.class == String
        assert torrent.downloadedEver.class == Fixnum
        assert torrent.downloadLimit.class == Fixnum
        assert torrent.downloadLimited.kind_of? Object
        assert torrent.error.class == Fixnum
        assert torrent.eta.class == Fixnum
        assert torrent.files.class == Array
        assert torrent.fileStats.class == Array
        assert torrent.hashString.class == String
        assert torrent.haveUnchecked.class == Fixnum
        assert torrent.haveValid.class == Fixnum
        assert torrent.honorsSessionLimits.kind_of? Object
        assert torrent.id.class == Fixnum
        assert torrent.isFinished.kind_of? Object
        assert torrent.isPrivate.kind_of? Object
        assert torrent.isStalled.kind_of? Object
        assert torrent.leftUntilDone.class == Fixnum
        assert torrent.magnetLink.class == String
        assert torrent.manualAnnounceTime.class == Fixnum
        assert torrent.maxConnectedPeers.class == Fixnum
        assert torrent.metadataPercentComplete.class == Fixnum
        assert torrent.name.class == String
  #      puts torrent.peer_limit.class #?? returns nilclass BROKEN!!
        assert torrent.peers.class == Array
        assert torrent.peersConnected.class == Fixnum
        assert torrent.peersFrom.class == Hash
        assert torrent.peersGettingFromUs.class == Fixnum
        assert torrent.peersSendingToUs.class == Fixnum
        assert torrent.percentDone.class == Fixnum
        assert torrent.pieces.class == String
        assert torrent.pieceCount.class == Fixnum
        assert torrent.pieceSize.class == Fixnum
        assert torrent.priorities.class == Array
        assert torrent.queuePosition.class == Fixnum
        assert torrent.rateDownload.class == Fixnum
        assert torrent.rateUpload.class == Fixnum
#        assert torrent.recheckProgress.class == Fixnum
        assert torrent.secondsDownloading.class == Fixnum
        assert torrent.secondsSeeding.class == Fixnum
        assert torrent.seedIdleLimit.class == Fixnum
        assert torrent.seedIdleMode.class == Fixnum
        assert torrent.seedRatioLimit.class == Fixnum
        assert torrent.seedRatioMode.class == Fixnum
        assert torrent.sizeWhenDone.class == Fixnum
        assert torrent.startDate.class == Fixnum
        assert torrent.status.class == Fixnum
        assert torrent.trackers.class == Array
        assert torrent.trackerStats.class == Array
        assert torrent.totalSize.class == Fixnum
        assert torrent.torrentFile.class == String
        assert torrent.uploadedEver.class == Fixnum
        assert torrent.uploadLimit.class == Fixnum
        assert torrent.uploadLimited.kind_of? Object
#        assert torrent.uploadRatio.class == Float broken!!!
        assert torrent.wanted.class == Array
        assert torrent.webseeds.class == Array
        assert torrent.webseedsSendingToUs.class == Fixnum
      end
    else
      assert false, "no torrent files available!"
    end


  end

  def test_torrent_get_set_methods
    # load global configuration
    Trans::Api::Client.config = CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

    # get all available objects
    torrents = Trans::Api::Torrent.all

    unless torrents.empty?
      torrents.each do |torrent|
        # get current value
        oldpos = torrent.uploadLimit
        newpos = oldpos + 1

        # set new value
        torrent.uploadLimit = newpos
        torrent.save!

        # sync file to its resource
        torrent.reset!
        assert torrent.uploadLimit == newpos, "no new value set #{oldpos} -> #{newpos} for: #{torrent.name}"

        # save old value
        torrent.uploadLimit = oldpos
        torrent.save!

        # sync file to its resource
        torrent.reset!
        assert torrent.uploadLimit == oldpos, "no new value set #{oldpos} -> #{newpos} for: #{torrent.name}"
      end
    else
      assert false, "no torrent files available!"
    end
  end


  def test_torrent_get_single
    # load global configuration
    Trans::Api::Client.config = CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

		torrent_ref = Trans::Api::Torrent.all.first

    torrent = Trans::Api::Torrent.find torrent_ref.id
    assert !torrent.nil?, "no torrent with id #{torrent_ref.id}"
  end

  def test_torrent_start_stop_single
    # load global configuration
    Trans::Api::Client.config = CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

		torrent_ref = Trans::Api::Torrent.all.first

    torrent = Trans::Api::Torrent.find torrent_ref.id
    assert !torrent.nil?, "no torrent with id #{torrent_ref.id}"

    #TODO: wait until status indicates start!

    torrent.start!
    torrent.stop!
  end


  def test_torrent_start_stop_multiple
    # load global configuration
    Trans::Api::Client.config = CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

    #TODO: wait until status indicates start!
    torrents = Trans::Api::Torrent.start_all
    torrents = Trans::Api::Torrent.stop_all
  end

  def test_torrent_add_remove_single
    # load global configuration
    Trans::Api::Client.config = CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

    # add file
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/2.torrent")
    torrent = Trans::Api::Torrent.add_file file, paused: true
    assert torrent.id

		# remove the testing torrent
		id = torrent.id
		torrent.delete! delete_local_data: true
		self.signal_wait_until(lambda{|t| t.nil?}) do
			Trans::Api::Torrent.find id
		end
  end


  def test_torrent_add_remove_multiple
		# load global configuration
    Trans::Api::Client.config = CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]


    file = File.expand_path(File.dirname(__FILE__) + "/torrents/2.torrent")
    torrent = Trans::Api::Torrent.add_file file, paused: true

		torrents = Trans::Api::Torrent.all
		ids = torrents.map{|t| t.id}

		assert ids.size > 0, "no loaded torrents found"
    torrent = Trans::Api::Torrent.delete_all ids: ids, delete_local_data: true

		#TODO: add assert here!!

  end


	def test_torrent_select_files_for_download
		# load global configuration
    Trans::Api::Client.config = CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

    torrent = Trans::Api::Torrent.all.first

		# mark files, unwant
		torrent.files_objects.each do |file|
			file.unwant
			assert !file.wanted?
		end

		torrent.save!
		torrent.reset!

		torrent.files_objects.each do |file|
			assert !file.wanted?
		end

	end

	def test_torrent_verify
		# load global configuration
    Trans::Api::Client.config = CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

    torrent = Trans::Api::Torrent.all.first
		torrent.verify!
		assert torrent.recheckProgress > 0
	end


	def test_torrent_reannounce
		# load global configuration
    Trans::Api::Client.config = CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

    torrent = Trans::Api::Torrent.all.first
		torrent.reannounce!

		#TODO: check peers here!

	end


	def test_torrent_set_location
		# load global configuration
    Trans::Api::Client.config = CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

    file = File.expand_path(File.dirname(__FILE__) + "/torrents/tmp/download_tmp/")
    torrent = Trans::Api::Torrent.all.first
		torrent.set_location file, true

		torrent.reset!
		assert torrent.downloadDir == file
	end



	protected


  # UTILS, probe block as long as pr callback returns false

  def signal_wait_until(pr, &block)
    #NOTE: busy waiting!!!
    while true do
      torrent = yield
      break if pr.call torrent
    end
  end


end
