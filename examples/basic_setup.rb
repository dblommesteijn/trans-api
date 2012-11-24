#!/usr/bin/env ruby

# setup
require 'rubygems'
require "bundler/setup"
require 'trans-api'


class BasicSetup

  include Trans::Api

  CONFIG = { host: "localhost", port: 9091, user: "admin", pass: "admin", path: "/transmission/rpc" }
  FIELDS = [ :id, :status, :name ]

  def initialize

    # connection information (rpc location)
    Client.config = CONFIG

    # default loading torrent fields
    Torrent.default_fields = FIELDS

    #TODO: add a section for session here!!

  end


  def add_torrent

    # selecting a file to add (debian demo file)
    file = ::File.expand_path(::File.dirname(__FILE__) + "/torrents/debian-6.0.6-amd64-CD-10.iso.torrent")

    # adding a torrent using static call on Torrent object (paused transfer)
    @torrent = Torrent.add_file file, paused: true
    # return variable is an instance of the torrent file
    # an exception can be raised on invalid request

    # NOTE: we will store it for later use (removing this torrent, not the whole list)

  end

  def remove_torrent

    #TODO: remove torrent here!

  end

  def iterating_torrents

    torrents = Torrent.all

    torrents.each do |torrent|

      puts "#{torrent.name} -> #{torrent.status_name}"

    end

  end

end



# initiate BasicSetup object, and run its methods
begin

  bs = BasicSetup.new
  bs.add_torrent
  bs.iterating_torrents

rescue Exception => e
  puts e
end




