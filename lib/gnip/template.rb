module Gnip
  class Template < ERB
    def Template.for(*args, &block)
      new(*args, &block)
    end

    def initialize(*args, &block)
      args, options = Gnip.args_for(args)
      @context = options.getopt(:context, options.getopt(:object))
      string = args.shift || block.call
      super(Gnip.util.unindent(string), safe_mode=nil, trim_mode='%')
    end

    def expand context = nil, &block
      context ||= block.binding if block
      context ||= @context
      raise ArgumentError, 'no context' unless context
      context = context.instance_eval('binding') unless context.respond_to?('binding')
      block.call(self) if block
      result(context)
    end

    class Xml < Template
      Declaration = '<?xml version="1.0" encoding="UTF-8"?>'

      def initialize(string = '', options = {}, &block)
        Gnip.optify!(options)

        declaration = options.getopt(:declaration)
        case declaration
          when TrueClass, FalseClass, NilClass
            declaration = Declaration if declaration
          else
            declaration = declaration.to_s
        end
        string = "#{ declaration }\n#{ Gnip.util.unindent(string) }" if declaration

        super(string, options, &block)
      end
    end

    def Template.xml() Xml end
  end
end
