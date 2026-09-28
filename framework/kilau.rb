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
require_relative "kilau/model/errors"
require_relative "kilau/model/model"
require_relative "kilau/model/migration"
require_relative "kilau/model/migrator"
require_relative "kilau/cli/schema_cli"
require_relative "kilau/config"
require_relative "kilau/controller/error"
require_relative "kilau/http/form"
require_relative "kilau/http/request"
require_relative "kilau/http/parser"
require_relative "kilau/view/html"
require_relative "kilau/http/response"
require_relative "kilau/controller/format"
