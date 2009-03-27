module Gnip
# a typed list of objects
#
  class List
    include Enumerable
    include Comparable

    def List.for(klass, *args, &block)
      new(klass, *args, &block)
    end

    def List.of(klass, *args, &block)
      new(klass, *args, &block)
    end

    attr :list
    attr :klass

    def initialize(klass, *args, &block)
      @list = []
      @klass = klass
    end

    def new(*args, &block)
      if klass.respond_to?(:for)
        klass.for(*args, &block)
      else
        klass.new(*args, &block)
      end
    end

    def cast(value)
      return value if value.is_a?(klass)
      msg =
        if klass.respond_to?(:cast)
          :cast
        elsif klass.respond_to?(:for)
          :for
        else
          :new
        end
      klass.send(msg, value)
    end

    def build(*args, &block)
      element = new(*args, &block)
      list << element
      element
    end
    alias_method 'create', 'build'

    def push(value)
      list << cast(value)
      self
    end
    alias_method '<<', 'push'

    def each(&block)
      list.each(&block)
    end

    def map(&block)
      list.map(&block)
    end

    def [](idx)
      list[idx]
    end

    def inspect
      "#{ self.class.name }.of(#{ klass.name })#{ list.inspect }"
    end

    def clear
      list.clear
      self
    end

    def size
      list.size
    end

    def replace other
      clear
      case other
        when List, Array
          other.flatten.each{|value| push(value)}
        else
          push(other)
      end
      self
    end

    def first
      list.first
    end

    def last
      list.last
    end

    def to_a
      list
    end

    def to_xs
      to_a.map{|element| element.respond_to?(:to_xs) ? element.to_xs : element}
    end

    def method_missing(m, *a, &b)
      if list.respond_to?(m)
        list.send(m, *a, &b)
      else
        super
      end
    end

    def to_yaml(*a, &b)
      list.to_yaml(*a, &b)
    end

    def <=> other
      list <=> other
    end
  end
end
