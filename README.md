# Trans::Api

Trans::Api is an ruby implementation for Transmission RPC. Based on RPC spec 13328
https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt

It required for the Transmission RPC to run the 'remote access':

OSX:

  Transmission > Preferences > Remote (tab) > Enable remote access


## Tests

This gem is build and tested with:

  OSX Lion, Mountain Lion
  Ruby 1.9.3,
  Rails: 3.2.8, 3.2.9
  Transmission 2.73 (13589)


### Roadmap

* (0.0.2)

  Session object include: blocklist, port-test
  Torrent object include torernt-start-now, queue-move-top/up/down/bottom


### Known Issues

The Transmission RPC call 'torrent-remove' (implemented as torrent.delete! and Torrent::delete\_all!) will crash the daemon! This is not a known issue at


## Installation

Add this line to your application's Gemfile:

    gem 'trans-api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trans-api


## Setup

Define a configuration for your connection (initialize script)

```ruby
  CONFIG = { host: "localhost", port: 9091, user: "admin", pass: "admin", path: "/transmission/rpc" }
```

Setup default configuration (initialize script)

```ruby
  Trans::Api::Client.config = CONFIG
```

Define default torrent fields (bulk requests)
NOTE: connection is slow when running many torrents with a large amount of fields (transmission rpc issue).
On requesting an additional info field from the torrent object, a new call is made to the RPC (and stored
withing the object).

```ruby
  Trans::Api::Torrent.default\_fields = [ :id, :status, :name ]
```

Example

```ruby
	Trans::Api::Torrent.default\_fields = [ :id, :status, :name ]

	# loads the torrent object of id 1 with fields: :id, :status, :name
	id = 1
	torrent = Trans::Api::Torrent.find id

	# calls the rpc to receive files from the defined torrent
	torrent.files
```

## Usage

Trans api can be used in two ways:


1. Connect (raw class)

```ruby
  tc = Trans::Api::Connect.new CONFIG
  torrents = tc.torrent\_get([:id, :name, :status])
```

2. Mapped objects (torrent, file, session classes)

	examples below.


### Requesting Torrent Info

Get all registered torrents

```ruby
	Trans::Api::Torrent.all
```

Get a specific torrent by transmission id
NOTE: transmission assigns random ids to torrents on daemon start

```ruby
	id = 1
	Trans::Api::Torrent.find id
```

### Torrent static calls

Start all

```ruby
	Trans::Api::Torrent.start\_all
```

Stop all

```ruby
	Trans::Api::Torrent.stop\_all
```

Delete all (tranmission daemon will crash on rapid call)

```ruby
	Trans::Api::Torrent.delete\_all
```

Add torrent file

```ruby
	options = {paused: true}
	Trans::Api::Torrent.add\_file filename, options
```

### Torrent instance actions

Get a torrent object

```ruby
	id = 1
	torrent = Trans::Api::Torrent.find id
```

Save (store changed values)

```ruby
	torrent.save!
```

Start

```ruby
	torrent.start!
```

Reset

```ruby
	torrent.reset!
```

Stop

```ruby
	torrent.stop!
```

File Objects (returns a list of Trans::Api::File objects)

```ruby
	torrent.files\_objects
```

Status names (get the status name of the torrent)

```ruby
	torrent.status\_name
```

Verify (recheck downloaded files)

```ruby
	torrent.verify!
```

Reannounce

```ruby
	torrent.reannounce!
```

Delete all (tranmission daemon will crash on rapid call)

```ruby
	options = {delete\_local\_data: true}
	torrent.delete! options
```

NOTE: defined torrent accessor fields are defined as instance methods to the Torrent object


### Session Info

Get session object

```ruby
	session = Trans::Api::Session.new
```

Get available fields (returns symbols of get/set fields)

```ruby
	session.fields
```

NOTE: defined session fields are defined as instance methods to the Session object


### File Info

Getting files from a torrent (file cannot be used standalone, it's an helper class)

```ruby
	id = 1
	torrent = Trans::Api::Torrent.find id
	files = torrent.files\_objects
	files.each do |file|
		# manipulate file here!
	end
```

File name

```ruby
	file.name
```

File mark unwant (mark for ignore, not download)

```ruby
	file.unwant
```

File mark want (mark for download)

```ruby
	file.want
```

File wanted? (marked for download)

```ruby
	file.wanted?
```

File stats

```ruby
	file.stat
```

NOTE: changed preferences (want, unwant) set options on the linked Torrent object, after saving torrent (torrent.save!) file mutations are stored.

