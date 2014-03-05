
require 'rubygems'
require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../../lib/trans-api")



#
# Unit test for Transmission RPC+json
# https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt
# Revision: 13328 (2012/11/16)
#

class TransTorrentObject < Test::Unit::TestCase

  def setup
    @CONFIG = { host: "localhost", port: 9091, user: "admin", pass: "admin", path: "/transmission/rpc" }
    @CONFIG = JSON.parse(ENV["CONFIG"], symbolize_names: true) if ENV.include? "CONFIG"

    Trans::Api::Client.config = @CONFIG
    Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

    # add a testing torrent
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-1.iso.torrent")
    @torrent = Trans::Api::Torrent.add_file file, paused: true
    sleep 1
  end

  def teardown
    # remove the testing torrent
    id = @torrent.id
    @torrent.delete! delete_local_data: true
    self.signal_wait_until(lambda{|t| t.nil?}) do
      Trans::Api::Torrent.find id
    end
  end


  def test_torrent_list_inspect_methods
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
    torrent_ref = Trans::Api::Torrent.all.first

    torrent = Trans::Api::Torrent.find torrent_ref.id
    assert !torrent.nil?, "no torrent with id #{torrent_ref.id}"
  end

  def test_torrent_start_stop_single
    torrent_ref = Trans::Api::Torrent.all.first

    torrent = Trans::Api::Torrent.find torrent_ref.id
    assert !torrent.nil?, "no torrent with id #{torrent_ref.id}"

    #TODO: wait until status indicates start!

    torrent.start!
    torrent.stop!
  end


  def test_torrent_start_stop_multiple
    #TODO: wait until status indicates start!
    torrents = Trans::Api::Torrent.start_all
    torrents = Trans::Api::Torrent.stop_all
  end

  def test_torrent_add_remove_single
    # add file
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-2.iso.torrent")
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
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-2.iso.torrent")
    torrent = Trans::Api::Torrent.add_file file, paused: true

    torrents = Trans::Api::Torrent.all

    assert torrents.size > 0, "no loaded torrents found"
    torrent = Trans::Api::Torrent.delete_all torrents, delete_local_data: true

    #TODO: add assert here!!

  end


  def test_torrent_select_files_for_download
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
    torrent = Trans::Api::Torrent.all.first
    torrent.verify!
    assert torrent.recheckProgress > 0
  end


  def test_torrent_reannounce
    torrent = Trans::Api::Torrent.all.first
    torrent.reannounce!

    #TODO: check peers here!

  end


  def test_torrent_set_location
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/tmp/download_tmp/")
    torrent = Trans::Api::Torrent.all.first
    torrent.set_location! file, true

    torrent.reset!
    assert torrent.downloadDir == file
  end

  def test_duplicate_file_upload
    # add test torrents
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-2.iso.torrent")
    # hammer duplicate torrent
    torrent = nil
    10.times { |t| torrent = Trans::Api::Torrent.add_file(file, paused: true) }
    assert Trans::Api::Torrent.all.size == 2
    torrent.delete!
  end

  def test_queue_movement
    # get queueposition as well
    Trans::Api::Torrent.default_fields = [ :id, :status, :name, :queuePosition ]

    # add test torrents
    torrents = []
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-2.iso.torrent")
    torrents << Trans::Api::Torrent.add_file(file, paused: true)
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-3.iso.torrent")
    torrents << Trans::Api::Torrent.add_file(file, paused: true)
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-4.iso.torrent")
    torrents << Trans::Api::Torrent.add_file(file, paused: true)
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-5.iso.torrent")
    torrents << Trans::Api::Torrent.add_file(file, paused: true)
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-6.iso.torrent")
    torrents << Trans::Api::Torrent.add_file(file, paused: true)
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-7.iso.torrent")
    torrents << Trans::Api::Torrent.add_file(file, paused: true)

    # collect first and last
    all = Trans::Api::Torrent.all
    torrent_first = all.first
    torrent_last = all.last

    # move to bottom
    torrent_first.queue_bottom!
    torrent_first.reset!
    assert torrent_first.queuePosition == all.size - 1

    # move to top
    torrent_last.queue_top!
    torrent_last.reset!
    assert torrent_last.queuePosition == 0

    ref = Trans::Api::Torrent.find_by_field_value :queuePosition, 0
    assert ref.class == Trans::Api::Torrent


    # move down the queue list
    all = Trans::Api::Torrent.all
    i = 0
    while i < all.size
      all = Trans::Api::Torrent.all
      all.each do |t|
        if t.queuePosition == i
          assert ref.name == t.name
          t.queue_down!
        end
      end
      i += 1
    end

    # move up the queue list
    while i >= 0
      all = Trans::Api::Torrent.all
      all.each do |t|
        if t.queuePosition == i
          assert ref.name == t.name
          t.queue_up!
        end
      end
      i -= 1
    end

    sleep(1) # don't crash the rpc daemon!
    # cleanup
    Trans::Api::Torrent.delete_all torrents, delete_local_data: true

  end

  def test_torrent_waitfor_status

    assert @torrent.status_name == :stopped || @torrent.status_name == :checkFiles

    # mark start
    @torrent.waitfor( lambda{|t| t.status_name != :stopped} ).start!
    @torrent.reset!
    assert @torrent.status_name != :stopped

    # mark stop
    @torrent.waitfor( lambda{|t| t.status_name == :stopped} ).stop!
    @torrent.reset!
    assert @torrent.status_name == :stopped

  end


  def test_torrent_add_by_base
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-5.iso.torrent")

    metainfo = ""
    File.open(file, 'r') do |file|
      tmp = file.read
      metainfo += Base64.encode64 tmp
    end

    torrent = Trans::Api::Torrent.add_metainfo(metainfo, paused: true)
    assert torrent.name == "debian-6.0.6-amd64-CD-5.iso"
    torrent.delete!
  end

  def test_find_torrent_by_value_name
    torrent = Trans::Api::Torrent.find_by_field_value(:name, "debian-6.0.6-amd64-CD-1.iso")
    assert !torrent.nil?
    assert torrent.name == "debian-6.0.6-amd64-CD-1.iso"
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
