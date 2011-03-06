task :flush_cache do
  dir = [
    '/tmp/cache/rack/meta/',
    '/tmp/cache/rack/body/',
    '/tmp/breachdb/cache/'
  ]

  dir.each do |d|
    FileUtils.rm_rf d
    FileUtils.mkdir_p d
  end
end
