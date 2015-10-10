module SmartProperties
  class PropertyCollection
    include Enumerable
    class << (ANCHOR = Object.new)
      def key?; false; end
      def [](*); nil; end
      def keys; []; end
      def values; []; end
      def each(&block); to_enum if block.nil?; end
    end

    attr_reader :parent

    def self.for(scope)
      parent = scope.ancestors[1..-1].find do |ancestor|
        ancestor.ancestors.include?(SmartProperties) && ancestor != SmartProperties
      end

      parent.nil? ? new : new(parent.properties)
    end

    def initialize(parent = nil)
      @collection = {}
      @parent = parent || ANCHOR
    end

    def []=(name, value)
      collection[name.to_s] = value
    end

    def [](name)
      name = name.to_s
      return collection[name] if collection.key?(name)
      parent[name]
    end

    def key?(name)
      return true if collection.key?(name.to_s)
      parent.key?(name)
    end

    def keys
      parent.keys + collection.keys.map(&:to_sym)
    end

    def values
      parent.values + collection.values
    end

    def each(&block)
      return to_enum if block.nil?

      iterator = lambda { |(name, value)| [name.to_sym, value] }
      parent.each(&iterator)
      collection.each(&iterator)
    end

    def to_hash
      Hash[keys.zip(values)]
    end

    protected

    attr_accessor :collection
  end
end
