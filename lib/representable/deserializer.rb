module Representable
  # we don't use keyword args, because i didn't want to discriminate 1.9 users, yet.
  # this will soon get introduces and remove constructs like options[:binding][:default].

  # Deprecation strategy:
  # binding.evaluate_option_with_deprecation(:reader, options, :doc)
  #   => binding.evaluate_option(:reader, options) # always pass in options.

  AssignFragment = ->(input, options) { options[:fragment] = input }

  ReadFragment = ->(input, binding:, as:, **) { binding.read(input, as) }
  Reader = ->(input, options) { options[:binding].evaluate_option(:reader, input, options) }

  StopOnNotFound = ->(input, options) do
    Binding::FragmentNotFound == input ? Pipeline::Stop : input
  end

  StopOnNil = ->(input, options) do # DISCUSS: Not tested/used, yet.
    input.nil? ? Pipeline::Stop : input
  end

  OverwriteOnNil = ->(input, options) do
    input.nil? ? (SetValue.(input, options); Pipeline::Stop) : input
  end

  Default = ->(input, binding:, **) do
    Binding::FragmentNotFound == input ? binding[:default] : input
  end

  SkipParse = ->(input, options) do
    options[:binding].evaluate_option(:skip_parse, input, options) ? Pipeline::Stop : input
  end

  module Function
    class Prepare
      def call(input, options)
        binding = options[:binding]

        binding.evaluate_option(:prepare, input, options)
      end
    end

    class Decorate
      def call(object, options)
        binding = options[:binding]

        return object unless object # object might be nil.

        mod = binding.evaluate_option(:extend, object, options)

        prepare_for(mod, object, binding)
      end

      def prepare_for(mod, object, binding)
        mod.prepare(object)
      end
    end
  end

  module CreateObject
    Instance = ->(input, options) { options[:binding].evaluate_option(:instance, input, options)||
        raise( DeserializeError.new(":instance did not return class constant for `#{options[:binding].name}`.")) }
    Class    = ->(input, options) do
      object_class = options[:binding].evaluate_option(:class, input, options) ||
        raise( DeserializeError.new(":class did not return class constant for `#{options[:binding].name}`."))
      object_class.new
    end # FIXME: no additional args passed here, yet.

    Populator = ->(*) { raise "Populator: implement me!" }
  end

  # CreateObject = Function::CreateObject.new
  Prepare      = Function::Prepare.new
  Decorate     = Function::Decorate.new
  Deserializer = ->(input, options) { options[:binding].evaluate_option(:deserialize, input, options) }

  Deserialize  =  ->(input, binding:, fragment:, options:, **) do
    # user_options:
    child_options = OptionsForNested.(options, binding)

    input.send(binding.deserialize_method, fragment, child_options)
  end

  ParseFilter = ->(input, options) do
    options[:binding][:parse_filter].(input, options)
  end

  Setter   = ->(input, options) { options[:binding].evaluate_option(:setter, input, options) }
  SetValue = ->(input, options) { options[:binding].send(:exec_context, options).send(options[:binding].setter, input) }


  Stop = ->(*) { Pipeline::Stop }

  If = ->(input, options) { options[:binding].evaluate_option(:if, nil, options) ? input : Pipeline::Stop }

  StopOnExcluded = ->(input, options:, binding: ,**) do
    return input unless private = options
    return input unless props = (options[:exclude] || options[:include])

    res = props.include?(binding.name.to_sym) # false with include: Stop. false with exclude: go!

    return input if options[:include]&&res
    return input if options[:exclude]&&!res
    Pipeline::Stop
  end
end