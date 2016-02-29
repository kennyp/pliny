module Pliny
  module CastingConfigHelpers
    def mandatory(name, method=nil)
      value = cast(ENV.fetch(name.to_s.upcase), method)
      create(name, value)
    end

    def optional(name, method=nil)
      value = cast(ENV[name.to_s.upcase], method)
      create(name, value)
    end

    def override(name, default, method=nil)
      value = cast(ENV.fetch(name.to_s.upcase, default), method)
      create(name, value)
    end

    def int
      ->(v) { v.to_i }
    end

    def float
      ->(v) { v.to_f }
    end

    def bool
      ->(v) { v.to_s=='true'}
    end

    def string
      nil
    end

    def symbol
      ->(v) { v.to_sym }
    end

    # optional :accronyms, array(string)
    # => ['a', 'b']
    # optional :numbers, array(int)
    # => [1, 2]
    # optional :notype, array
    # => ['a', 'b']
    def array(method = nil)
      -> (v) do
        if v
          v.split(",").map{|a| cast(a, method) }
        end
      end
    end

    def rack_env
      if pliny_env == "development" || pliny_env == "test"
        "development"
      else
        "deployment"
      end
    end

    private

    def cast(value, method)
      method ? method.call(value) : value
    end

    def create(name, value)
      instance_variable_set(:"@#{name}", value)
      instance_eval "def #{name}; @#{name} end", __FILE__, __LINE__
      if value.kind_of?(TrueClass) || value.kind_of?(FalseClass) || value.kind_of?(NilClass)
        instance_eval "def #{name}?; !!@#{name} end", __FILE__, __LINE__
      end
    end
  end

  module ConfigHelpers
    def optional(*attrs)
      attrs.each do |attr|
        instance_eval "def #{attr}; @#{attr} ||= ENV['#{attr.upcase}'] end", __FILE__, __LINE__
        ConfigHelpers.add_question_method(attr)
      end
    end

    def mandatory(*attrs)
      attrs.each do |attr|
        instance_eval "def #{attr}; @#{attr} ||= ENV['#{attr.upcase}'] || raise('missing=#{attr.upcase}') end", __FILE__, __LINE__
        ConfigHelpers.add_question_method(attr)
      end
    end

    def override(attrs)
      attrs.each do |attr, value|
        instance_eval "def #{attr}; @#{attr} ||= ENV['#{attr.upcase}'] || '#{value}'.to_s end", __FILE__, __LINE__
        ConfigHelpers.add_question_method(attr)
      end
    end

    def self.add_question_method(attr)
      define_method "#{attr}?" do
        return false if send(attr).nil?
        !!(send(attr) =~ /\Atrue|yes|on\z/i || send(attr).to_i > 0)
      end
    end
  end

end

# Supress the "use RbConfig instead" warning
if Object.const_defined?(:Config) && !Config.is_a?(Pliny::CastingConfigHelpers)
  Object.send(:remove_const, :Config)
end
