require 'wiki/extensions'

module Wiki
  module Aspect
    def before_method(name, before_name = nil, &block)
      raise ArgumentError.new('block or method name has to be supplied') if !block && !before_name
      old = instance_method(name)
      new = block ? lambda(&block).to_method(self) : instance_method(before_name)
      define_method(name) do |*args|
        args = new.bind(self)[*args]
        args = [args] if !args.is_a? Array
        old.bind(self)[*args]
      end
    end

    def after_method(name, after_name = nil, &block)
      raise ArgumentError.new('block or method name has to be supplied') if !block && !after_name
      old = instance_method(name)
      new = block ? lambda(&block).to_method(self) : instance_method(after_name)
      define_method(name) do |*args|
        args = old.bind(self)[*args]
        args = [args] if !args.is_a? Array
        new.bind(self)[*args]
      end
    end

    def around_method(name, around_name = nil, &block)
      raise ArgumentError.new('block or method name has to be supplied') if !block && !around_name
      old = instance_method(name)
      new = block ? lambda(&block).to_method(self) : instance_method(around_name)
      define_method(name) { |*args| new.bind(self)[old.bind(self), *args] }
    end

    def method_missing(name, *args, &block)
      case name.to_s
      when /^before_(\w+)$/
        before_method($1, *args, &block)
      when /^after_(\w+)$/
        after_method($1,*args, &block)
      when /^around_(\w+)$/
        around_method($1, *args, &block)
      else
        super(name, *args, &block)
      end
    end
  end
end
