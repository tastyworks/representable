require 'representable'
require 'representable/xml/binding'
require 'representable/xml/collection'

begin
  require 'nokogiri'
rescue LoadError => _
  abort "Missing dependency 'nokogiri' for Representable::XML. See dependencies section in README.md for details."
end

# TODO: the wrap node should be created in the binding and not the surrounding representer. that way, we can use :wrap, :as, etc.

module Representable
  module XML
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        self.representation_wrap = true # let representable compute it.
        register_feature Representable::XML
      end
    end


    module ClassMethods
      def remove_namespaces!
        representable_attrs.options[:remove_namespaces] = true
      end

      def collection_representer_class
        Collection
      end
    end

    def from_xml(doc, *args)
      node = parse_xml(doc, *args)

      from_node(node, *args)
    end

    def from_node(node, options={})
      update_properties_from(node, options, Binding)
    end

    # Returns a Nokogiri::XML object representing this object.
    def to_node(options)
      puts "@@@@@ #{representation_wrap(options)}  #{options.inspect}"
      # if :as is set on the binding representing this nested object, :wrap should already be set to it.
      root_tag = options[:wrap] || representation_wrap(options) # || :as

      options[:root_wrap] = root_tag
      # create_representation_with(Nokogiri::XML::Node.new(root_tag.to_s, options[:doc]), options, Binding)
      create_representation_with(options[:doc], options, Binding)
    end

    def to_xml(options={})
      options[:doc] ||= Nokogiri::XML::Document.new
      to_node(options).to_s
    end

  private
    def remove_namespaces?
      # TODO: make local Config easily extendable so you get Config#remove_ns? etc.
      representable_attrs.options[:remove_namespaces]
    end

    def parse_xml(doc, *args)
      node = Nokogiri::XML(doc)

      node.remove_namespaces! if remove_namespaces?
      node.root
    end
  end
end
