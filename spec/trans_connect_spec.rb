
require 'spec_helper'

describe Trans::Api::Connect do

  it "should get a session" do
    t = Trans::Api::Connect.new
    session = t.session_get

    puts session["arguments"].map {|k,v| "#{k}\t\t#{v}"}

    assert
  end

end

