require 'boot'

namespace :cache do
  task :flush do
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

  task :prime do
    Breach::Breach.all do |breach|
      breach.hash_count
      breach.cracked_count
      breach.uniq_hash_type_names
    end
  end

  task :reload do
    Breach::Breach.all do |breach|
      breach.hash_count!
      breach.cracked_count!
      breach.uniq_hash_type_names!
    end
  end
end
