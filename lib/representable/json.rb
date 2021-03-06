require 'representable/hash'
require 'representable/json/collection'
require 'bigdecimal'

begin
  require 'multi_json'
rescue LoadError => _
  abort "Missing dependency 'multi_json' for Representable::JSON. See dependencies section in README.md for details."
end

module Representable
  # Brings #to_json and #from_json to your object.
  module JSON
    extend Hash::ClassMethods
    include Hash

    def self.included(base)
      base.class_eval do
        include Representable # either in Hero or HeroRepresentation.
        extend ClassMethods # DISCUSS: do that only for classes?
        register_feature Representable::JSON
      end
    end


    module ClassMethods
      def collection_representer_class
        JSON::Collection
      end
    end

    def to_hash(*args)
      hash = super(*args)
      hash.each do |key, value|
        case value
        when ::BigDecimal
          hash[key] = Tastyworks::Api::Json::BigDecimalTranslator.value_to_json(value)
        when ::DateTime
          hash[key] = Tastyworks::Api::Json::DateTimeTranslator.value_to_json(value)
        end
      end
    end

    # Parses the body as JSON and delegates to #from_hash.
    def from_json(data, *args)
      data = MultiJson.load(data)
      from_hash(data, *args)
    end

    # Returns a JSON string representing this object.
    def to_json(*args)
      MultiJson.dump to_hash(*args)
    end
  end
end
