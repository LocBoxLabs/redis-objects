# This is the class loader, for use as "include Redis::Objects::Sets"
# For the object itself, see "Redis::Set"
require 'redis/sorted_set'
class Redis
  module Objects
    module SortedSets
      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.extend ClassMethods
      end

      # Class methods that appear in your class when you include Redis::Objects.
      module ClassMethods
        # Define a new list.  It will function like a regular instance
        # method, so it can be used alongside ActiveRecord, DataMapper, etc.
        def sorted_set(name, options={})
          @redis_objects[name.to_sym] = options.merge(:type => :sorted_set)
          klass_name = '::' + self.name
          if options[:global]
            instance_eval <<-EndMethods
              def #{name}
                @#{name} ||= Redis::SortedSet.new(redis_field_key(:#{name}), #{name}_redis, #{klass_name}.redis_objects[:#{name}])
              end
            EndMethods
            instance_eval do
              define_singleton_method "#{name}_redis" do
                options[:connection] || klass_name.constantize.redis
              end
            end
            class_eval <<-EndMethods
              def #{name}
                self.class.#{name}
              end
            EndMethods
          else
            class_eval <<-EndMethods
              def #{name}
                @#{name} ||= Redis::SortedSet.new(redis_field_key(:#{name}), #{name}_redis, #{klass_name}.redis_objects[:#{name}])
              end
            EndMethods
            class_eval do
              define_method "#{name}_redis" do
                options[:connection] || klass_name.constantize.redis
              end
            end
          end
        end
      end

      # Instance methods that appear in your class when you include Redis::Objects.
      module InstanceMethods
      end
    end
  end
end