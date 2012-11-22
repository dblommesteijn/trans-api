# Trans::Api

Trans::Api is an ruby implementation for Transmission RPC. Based on RPC spec 13328
https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt

It required for the Transmission RPC to run the 'remote access':

	Transmission > Preferences > Remote (tab) > Enable remote access

This gem is build and tested with: OSX Lion, Ruby 1.9.3, (Rails: 3.2.8) and Transmission 2.73 (13589)

### NOTE

The following api calls are not yet implemented:

	Roadmap for (0.0.2):

	torrent-start-now
	queue-move-top
	queue-move-up
	queue-move-down
	queue-move-bottom
	blocklist-update
	port-test

## Installation

Add this line to your application's Gemfile:

    gem 'trans-api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trans-api


## Setup

Define a configuration for your connection (initialize script)

	CONFIG = { host: "localhost", port: 9091, user: "admin", pass: "admin", path: "/transmission/rpc" }

Setup default configuration (initialize script)

  Trans::Api::Client.config = CONFIG

Define default torrent fields (bulk requests)
NOTE: connection is slow when running many torrents with a large amount of fields (transmission rpc issue).
On requesting an additional info field from the torrent object, a new call is made to the RPC (and stored
withing the object).

	Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

Example

	Trans::Api::Torrent.default_fields = [ :id, :status, :name ]

	# loads the torrent object of id 1 with fields: :id, :status, :name
	id = 1
	torrent = Trans::Api::Torrent.find id

	# calls the rpc to receive files from the defined torrent
	torrent.files


## Usage

Trans api can be used in two ways:


1. Connect (raw class)

  tc = Trans::Api::Connect.new CONFIG
  torrents = tc.torrent_get([:id, :name, :status])

2. Mapped objects (torrent, file, session classes)

	examples below.


### Requesting Torrent Info

Get all registered torrents

	Trans::Api::Torrent.all

Get a specific torrent by transmission id
NOTE: transmission assigns random ids to torrents on daemon start

	id = 1
	Trans::Api::Torrent.find id


### Torrent static calls

Start all

	Trans::Api::Torrent.start_all

Stop all

	Trans::Api::Torrent.stop_all

Delete all (dangerous)

	Trans::Api::Torrent.delete_all

Add torrent file

	options = {paused: true}
	Trans::Api::Torrent.add_file filename, options


### Torrent instance actions

Get a torrent object

	id = 1
	torrent = Trans::Api::Torrent.find id

Save (store changed values)

	torrent.save!

Start

	torrent.start!

Reset

	torrent.reset!

Stop

	torrent.stop!

File Objects (returns a list of Trans::Api::File objects)

	torrent.files_objects

Status names (get the status name of the torrent)

	torrent.status_name

Verify (recheck downloaded files)

	torrent.verify!

Reannounce

	torrent.reannounce!

Delete (and remove local data)

	options = {delete_local_data: true}
	torrent.delete! options

NOTE: defined torrent accessor fields are defined as instance methods to the Torrent object


### Session Info

Get session object

	session = Trans::Api::Session.new

Get available fields (returns symbols of get/set fields)

	session.fields

NOTE: defined session fields are defined as instance methods to the Session object


### File Info

Getting files from a torrent (file cannot be used standalone, it's an helper class)

	id = 1
	torrent = Trans::Api::Torrent.find id
	files = torrent.files_objects
	files.each do |file|
		# manipulate file here!
	end

File name

	file.name

File mark unwant (mark for ignore, not download)

	file.unwant

File mark want (mark for download)

	file.want

File wanted? (marked for download)

	file.wanted?

File stats

	file.stat

NOTE: changed preferences (want, unwant) set options on the linked Torrent object, after saving torrent (torrent.save!) file mutations are stored.

