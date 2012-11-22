
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

  def test_session_set_peer_limit_global
    # load global configuration
    Trans::Api::Client.config = CONFIG

    # session object
    session = Trans::Api::Session.new

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
    # load global configuration
    Trans::Api::Client.config = CONFIG

    # session object
    session = Trans::Api::Session.new

    assert session.fields_and_values.size > 0, "no fields and values loaded"
    assert session.fields.size > 0, "no fields loaded"

  end

  def test_session_stats
    # load global configuration
    Trans::Api::Client.config = CONFIG

    # session object
    session = Trans::Api::Session.new

    assert session.stats!, "no stats loaded"
  end


end
