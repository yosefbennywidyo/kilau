# Kilau: a Loco-style web framework for Spinel.
module Kilau
  VERSION = "0.1.0"
end

require_relative "kilau/testing/check"
require_relative "kilau/db/base"
require_relative "kilau/db/native"
require_relative "kilau/db/connection_spinel"
require_relative "kilau/db/connection_cruby"
require_relative "kilau/db/pool"
