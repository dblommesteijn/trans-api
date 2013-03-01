
require 'rubygems'
require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../../lib/trans-api")



#
# Unit test for Transmission RPC+json
# https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt
# Revision: 13328 (2012/11/16)
#

class TransSessionObject < Test::Unit::TestCase

  CONFIG = { host: "localhost", port: 9091, user: "admin", pass: "admin", path: "/transmission/rpc" }

  def setup
    Trans::Api::Client.config = CONFIG
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


end
