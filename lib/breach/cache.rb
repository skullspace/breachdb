require 'moneta/file'
require 'gibbler/aliases'
module Breach
  CACHE = Moneta::File.new(:path => "/tmp/breachdb/cache")

  class Cache

    def self.set(key, obj,*)
      CACHE[key] = obj
    end

    def self.get(key)
      CACHE[key]
    end

    def self.delete(key)
      CACHE.delete[key]
    end
  end

  # some caching stuff for sequel model
  class Sequel::Model
    module CachedMethodsApi
      def self._register_method(method_name)
        (@_cached_methods ||= []) << method_name
      end

      def self._method_already_registered?(method_name)
        (@_cached_methods ||= []).include?(method_name)
      end

      def self.method_added(method_name,*args,&block)
        return if _method_already_registered?(method_name)

        cached_method_name = "#{method_name}!".to_sym
        _register_method(method_name)
        _register_method(cached_method_name)

        original_method = instance_method(method_name)

        define_method cached_method_name do
          original_method.bind(self).call
        end

        define_method method_name do |*args|
          _cache [method_name,args].digest do
            send cached_method_name
          end
        end
      end
    end

    def self.cache_methods(*args,&block)
      CachedMethodsApi.module_exec(&block)

      include CachedMethodsApi
    end

    def _cache(key,&block)
      Cache.get(key) or Cache.set(key,yield)
    end
  end
end
