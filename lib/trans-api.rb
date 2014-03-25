require File.expand_path(File.dirname(__FILE__) + "/trans-api/version")
require File.expand_path(File.dirname(__FILE__) + "/trans-api/client")
require File.expand_path(File.dirname(__FILE__) + "/trans-api/connect")
require File.expand_path(File.dirname(__FILE__) + "/trans-api/session")
require File.expand_path(File.dirname(__FILE__) + "/trans-api/torrent")
require File.expand_path(File.dirname(__FILE__) + "/trans-api/file")

# boolean helper
if Boolean.nil?
  module Boolean; end
  class TrueClass; include Boolean; end
  class FalseClass; include Boolean; end
end

# trans api placeholder
module Trans
  module Api
  end
end
