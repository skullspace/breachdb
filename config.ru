require 'boot'

use Rack::Cache,
  :verbose     => true,
  :metastore   => 'file:/tmp/cache/rack/meta',
  :entitystore => 'file:/tmp/cache/rack/body'

run Breach::Server
