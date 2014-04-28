
require 'rubygems'
require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../../lib/trans-api")


# run with config options
#CONFIG="{\"host\":\"localhost\",\"port\":9091,\"user\":\"admin\",\"pass\":\"admin\",\"path\":\"/transmission/rpc\"}" ruby -I test test/unit/trans_session_object.rb

#
# Unit test for Transmission RPC+json
# https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt
# Revision: 13328 (2012/11/16)
#

class TransSessionObject < Test::Unit::TestCase

  # BLOCKLIST = "http://list.iblocklist.com/?list=bt_level3&fileformat=p2p&archiveformat=gz"
  BLOCKLIST = "http://list.iblocklist.com/?list=bt_level1&fileformat=p2p&archiveformat=gz"

  def setup
    @CONFIG = { host: "localhost", port: 9091, user: "admin", pass: "admin", path: "/transmission/rpc" }
    @CONFIG = JSON.parse(ENV["CONFIG"], symbolize_names: true) if ENV.include? "CONFIG"

    Trans::Api::Client.config = @CONFIG
  end


  def test_session_singleton

    # load first instance
    session1 = Trans::Api::Session.instance
    # load second instance
    session2 = Trans::Api::Session.instance

    # compare instance objects (should be equal)
    assert session1 == session2

  end


  def test_session_set_peer_limit_global
    # session object
    session = Trans::Api::Session.instance

    # read value
    oldvalue = session.peer_limit_global

    # set new value
    session.peer_limit_global = oldvalue + 1
    session.save!

    # read new value
    newvalue = session.peer_limit_global
    assert newvalue == oldvalue + 1, "newvalue not oldvalue+1"

    # restore old value
    session.peer_limit_global = oldvalue
    session.save!

    assert session.peer_limit_global == oldvalue, "oldvalue not stored"
  end

  def test_session_fields
    # session object
    session = Trans::Api::Session.instance

    assert session.fields_and_values.size > 0, "no fields and values loaded"
    assert session.fields.size > 0, "no fields loaded"

  end

  def test_session_stats
    # session object
    session = Trans::Api::Session.instance

    assert session.stats!, "no stats loaded"
  end


  def test_session_secure
    session = Trans::Api::Session.instance

    #TODO: add security test here!
  end


  def test_swap_configs
    # test default operation
    session = Trans::Api::Session.instance
    assert session.fields_and_values.size > 0, "no fields and values loaded"

    # insert a broken config
    broken_config = { host: "localhost", port: 9091, user: "akdljflkasjdlfk", pass: "alskdfjlkajsdfl", path: "/transmission/rpc" }
    Trans::Api::Client.config = broken_config
    begin
      session.reload!
      assert false, "should have raised an exception"
    rescue
      assert true
    end
    begin
      session.stats!.nil?
      assert false, "stat should be broken!"
    rescue
      assert true
    end
  end


  def test_set_blocklist
    session = Trans::Api::Session.instance
    session.blocklist_enabled = false
    session.blocklist_url = ""
    session.save!
    # verify
    session.reload!
    assert session.blocklist_url == "", "url not updated"
    assert session.blocklist_enabled == false, "boolean not toggled"
    # save blocklist to session
    session = Trans::Api::Session.instance
    session.blocklist_url = BLOCKLIST
    session.blocklist_enabled = true
    session.save!
    # verify
    session.reload!
    assert session.blocklist_url == BLOCKLIST, "blocklist not saved!"
    # force blocklist update
    response = session.update_blocklist!
    session.reload!
    assert session.blocklist_size == response[:blocklist_size], "blocklist not updated"
  end

  def test_set_wrong_blocklist
    session = Trans::Api::Session.instance
    session.blocklist_enabled = false
    session.blocklist_url = ""
    session.save!
    session.reload!
    begin
      session.update_blocklist!
      assert false, "should not be possible without an url"
    rescue Exception => e
      assert true
    end
  end


end
