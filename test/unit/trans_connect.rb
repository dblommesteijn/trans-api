require 'rubygems'
require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../../lib/trans-api")



#
# Unit test for Transmission RPC+json
# https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt
# Revision: 13328 (2012/11/16)
#

class TransConnect < Test::Unit::TestCase

  CONFIG = { host: "localhost", port: 9091, user: "admin", pass: "admin", path: "/transmission/rpc" }

  def setup
    Trans::Api::Client.config = CONFIG

    # add a testing torrent
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-1.iso.torrent")
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



  # SESSIONS

  def test_session_get
    tc = Trans::Api::Connect.new CONFIG
    session = tc.session_get
    assert session.size > 0, "no arguments found"
  end

  def test_session_stats
    tc = Trans::Api::Connect.new CONFIG
    session = tc.session_stats
    assert session.size > 0, "no arguments found"
  end

  def test_session_set
    tc = Trans::Api::Connect.new CONFIG

    # get session
    session_get = tc.session_get
    assert session_get.size > 0, "no arguments found"

    original_value = nil
    new_value = nil

    # loop all arguments until a suitable value is found
    while original_value.nil? && new_value.nil? do
      tmp_old = session_get.first
      tmp_new = [tmp_old.first,nil]

      # handle a fixnum change
      if tmp_old.last.kind_of? Fixnum
        tmp_new[1] = tmp_old[1] + 1
        original_value = tmp_old
        new_value = tmp_new
      end
    end

    assert new_value != original_value, "new and original value are the same"


    # set new session value
    session_set = tc.session_set(Hash[*new_value])
    session_get = tc.session_get

    assert session_get.first == new_value, "new value not stored (or being processed)"

    # set the original value
    session_set = tc.session_set(Hash[*original_value])
    session_get = tc.session_get

    assert session_get.first == original_value, "old value not stored (or being processed)"

  end

  def test_session_close
    tc = Trans::Api::Connect.new CONFIG
    session_get = tc.session_get
    #NOTE: will shut the daemon down!!
    #    session_close = tc.session_close
  end


  # TORRENTS

  def test_torrent_get
    tc = Trans::Api::Connect.new CONFIG

    # receive torrent list
    torrents = tc.torrent_get([:id, :name, :status])

    # test received torrents
    unless torrents.empty?
      torrents.each do |torrent|
        assert torrent.include?(:id), "torrent missing :id"
        assert torrent.include?(:status), "torrent missing :status"
        assert torrent.include?(:name), "torrent missing :name"

        # request same torrent from id of the last request
        t_new = tc.torrent_get([:id], [torrent[:id]])
        assert t_new.size == 1
        assert t_new.first[:id] == torrent[:id]
        # request caries only :id, no :name
        assert !t_new.include?(:name)
      end
    else
      assert false, "no torrent files found!"
    end
  end

  def test_torrent_set
    tc = Trans::Api::Connect.new CONFIG

    # get torrent list
    torrents = tc.torrent_get([:id, :name, :bandwidthPriority])

    unless torrents.empty?
      torrents.each do |torrent|
        assert torrent.include?(:bandwidthPriority), "torrent missing :bandwidthPriority"

        oldvalue = torrent[:bandwidthPriority]
        newvalue = oldvalue + 1

        # set new value
        tc.torrent_set({bandwidthPriority: newvalue}, [torrent[:id]])
        torrent_new = tc.torrent_get([:id, :bandwidthPriority], [torrent[:id]])
        assert torrent_new.first[:bandwidthPriority] == newvalue

        # set old value
        tc.torrent_set({bandwidthPriority: oldvalue}, [torrent[:id]])
        torrent_new = tc.torrent_get([:id, :bandwidthPriority], [torrent[:id]])
        assert torrent_new.first[:bandwidthPriority] == oldvalue

      end
    else
      assert false, "no torrent files found!"
    end
  end


  def test_torrent_start_stop_single
    tc = Trans::Api::Connect.new CONFIG

    torrents = tc.torrent_get([:id, :name, :status])

    tested = false

    unless torrents.empty?
      # loop all torrents
      torrents.each do |torrent|

        old_status = Trans::Api::Torrent::STATUS[torrent[:status]]

        if old_status == :stopped

          # toggle start
          tc.torrent_start([torrent[:id]])

          # wait until started
          new_torrent = nil
          self.signal_wait_until(lambda{|t| Trans::Api::Torrent::STATUS[t.first[:status]] != :stopped}) do
            new_torrent = tc.torrent_get([:id, :name, :status], [torrent[:id]])
          end
          assert Trans::Api::Torrent::STATUS[new_torrent.first[:status]] != :stopped, "torrent signaled for start (not seeding)"

          # toggle stop
          tc.torrent_stop([torrent[:id]])

          # wait until stopped
          new_torrent = nil
          self.signal_wait_until(lambda{|t| Trans::Api::Torrent::STATUS[t.first[:status]] == :stopped}) do
            new_torrent = tc.torrent_get([:id, :name, :status], [torrent[:id]])
          end
          assert Trans::Api::Torrent::STATUS[new_torrent.first[:status]] == :stopped, "torrent signaled for stop (not stopped)"

          tested = true
          break
        end

      end
    else
      assert false, "no torrent files found!"
    end
    assert tested, "no status :stopped found! (no tests ran)"
  end

  def test_torrent_start_stop_multi
    tc = Trans::Api::Connect.new CONFIG
    torrents = tc.torrent_get([:id, :name, :status])


    unless torrents.empty?

      # filter for stopped torrents only
      torrents.reject!{|t| Trans::Api::Torrent::STATUS[t[:status]] != :stopped }

      start_ids = torrents.map{|t| t[:id]}

      # start all stopped torrents
      tc.torrent_start(start_ids)

      # wait for all torrents to start
      started_torrents = []
      self.signal_wait_until(lambda{|t| t.reject{|q| Trans::Api::Torrent::STATUS[q[:status]] != :stopped }.size == 0 }) do
        started_torrents = tc.torrent_get([:id, :name, :status], start_ids)
      end
      assert started_torrents.reject{|t| Trans::Api::Torrent::STATUS[t[:status]] != :stopped }.size == 0, "still some unstarted torrents"


      # stop all started torrents
      tc.torrent_stop(start_ids)

      # wait for all torrents to stop
      stopped_torrents = []
      self.signal_wait_until(lambda{|t| t.reject{|q| Trans::Api::Torrent::STATUS[q[:status]] == :stopped }.size == 0 }) do
        stopped_torrents = tc.torrent_get([:id, :name, :status], start_ids)
      end
      assert stopped_torrents.reject{|t| Trans::Api::Torrent::STATUS[t[:status]] == :stopped }.size == 0, "still some running torrents"


    else
      assert false, "no torrent files found!"
    end
  end

  def test_torrent_add_remove_single
    tc = Trans::Api::Connect.new CONFIG

    # add test file
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-2.iso.torrent")
    torrent = tc.torrent_add filename: file, paused: true

    # get submitted torrent
    torrent_get = tc.torrent_get([:id, :name, :status], [torrent[:id]]).first
    assert torrent_get[:id] == torrent[:id]

    # remove torrent and cleanup
    torrent_remove = tc.torrent_remove({delete_local_data: true}, [torrent[:id]])


    torrent_get = nil
    self.signal_wait_until(lambda{|t| t.nil?}) do
      torrent_get = tc.torrent_get([:id, :name, :status], [torrent[:id]]).first
    end

    assert torrent_get.nil?

  end


  def test_torrent_files_unwatched
    tc = Trans::Api::Connect.new CONFIG
    torrents = tc.torrent_get([:id, :name, :status, :files, :fileStats])

    torrents.each do |torrent|
    end

    #TODO: add test here!

  end


  def test_torrent_start_now
    tc = Trans::Api::Connect.new CONFIG
    # get first torrent
    torrent = tc.torrent_get([:id, :name, :status]).first
    # start now
    tc.torrent_start_now([torrent[:id]])
    # reload first torrent
    torrent = tc.torrent_get([:id, :name, :status]).first
    # check started status
    assert Trans::Api::Torrent::STATUS[torrent[:status]] != :stopped
  end

  def test_torrent_verify
    tc = Trans::Api::Connect.new CONFIG
    torrents = tc.torrent_get([:id, :name, :status])

    torrents.each do |torrent|
      tc.torrent_verify([torrent[:id]])
      t = tc.torrent_get([:recheckProgress], [torrent[:id]]).first
      assert t[:recheckProgress] > 0
    end

  end

  def test_torrent_reannounce
    tc = Trans::Api::Connect.new CONFIG
    torrents = tc.torrent_get([:id, :name, :status])

    torrents.each do |torrent|
      tc.torrent_reannounce([torrent[:id]])
    end
    # TODO : check for peers
  end



  def test_torrent_set_location
    tc = Trans::Api::Connect.new CONFIG

    # new target
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/download_tmp/")

    # load torrent
    torrents = tc.torrent_get([:id, :name, :status, :downloadDir])
    assert torrents.size >0
    torrents.each do |torrent|
      tc.torrent_set_location({move: true, location: file} ,[torrent[:id]])
    end

    # reload torrent
    torrents = tc.torrent_get([:id, :name, :status, :downloadDir])
    assert torrents.size >0
    torrents.each do |torrent|
      assert torrent[:downloadDir] == file
    end

  end




  # MISC

  def test_blocklist_update
    tc = Trans::Api::Connect.new CONFIG
    response = tc.blocklist_update
    assert response.include? :blocklist_size
    assert response[:blocklist_size].class == Fixnum
  end

  def test_port_test
    tc = Trans::Api::Connect.new CONFIG
    response = tc.port_test
    assert response.include? :port_is_open
    assert response[:port_is_open].class == FalseClass || response[:port_is_open].class == TrueClass
  end


  # QUEUE

  def test_queue_movement
    tc = Trans::Api::Connect.new CONFIG

    torrents = []

    # add a bunch of files
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-2.iso.torrent")
    torrents << tc.torrent_add(filename: file, paused: true)
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-3.iso.torrent")
    torrents << tc.torrent_add(filename: file, paused: true)
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-4.iso.torrent")
    torrents << tc.torrent_add(filename: file, paused: true)
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-5.iso.torrent")
    torrents << tc.torrent_add(filename: file, paused: true)
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-6.iso.torrent")
    torrents << tc.torrent_add(filename: file, paused: true)
    file = File.expand_path(File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-7.iso.torrent")
    torrents << tc.torrent_add(filename: file, paused: true)

    # move bottom
    tc.queue_move_bottom [torrents.first[:id]]


    # collect all torrents
    all = tc.torrent_get([:id, :name, :status, :queuePosition])

    # isolate first and last
    torrent_first = all.first
    torrent_last = all.last

    # reverse queue order
    tc.queue_move_bottom [torrent_first[:id]]
    tc.queue_move_top [torrent_last[:id]]

    # check if order is reversed
    assert tc.torrent_get([:id, :name, :status, :queuePosition], [torrent_first[:id]]).first[:queuePosition] == all.size - 1
    assert tc.torrent_get([:id, :name, :status, :queuePosition], [torrent_last[:id]]).first[:queuePosition] == 0



    # get reference torrent (queueposition == 0)
    ref = nil
    all = tc.torrent_get([:id, :name, :status, :queuePosition])
    all.each do |t|
      if t[:queuePosition] == 0
        ref = t
        break
      end
    end

    # move down the queue list
    i = 0
    while i < all.size
      all = tc.torrent_get([:id, :name, :status, :queuePosition])
      all.each do |t|
       if t[:queuePosition] == i
         assert ref[:name] == t[:name]
         tc.queue_move_down [t[:id]]
        end
      end
      i += 1
    end

    # move up the queue list (use the last reference)
    while i >= 0
      all = tc.torrent_get([:id, :name, :status, :queuePosition])
      all.each do |t|
       if t[:queuePosition] == i
         assert ref[:name] == t[:name]
         tc.queue_move_up [t[:id]]
        end
      end
      i -= 1
    end


    # cleanup added torrents
    torrents.each do |torrent|
      tc.torrent_remove [torrent[:id]]
      sleep 0.5 # don't crash the rpc daemon!
    end
  end




  # UTILS, probe block as long as pr callback returns false

  def signal_wait_until(pr, &block)
    #NOTE: busy waiting!!!
    while true do
      torrent = yield
      #      puts torrent
      break if pr.call torrent
    end
  end


end

