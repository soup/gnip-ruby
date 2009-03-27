module Gnip
  module Arguments
    def options
      @options ||= Options.for(last.is_a?(Hash) ? pop : {})
    end

    %w[ getopt getopts hasopt hasopts delopt delopts ].each do |method|
      module_eval <<-code
        def #{ method }(*args, &block)
          options.#{ method }(*args, &block)
        end
      code
    end

    def Arguments.for(args)
      raise ArgumentError unless args.is_a?(Array)
      args.extend(Arguments)
      [args, args.options]
    end
  end
end
