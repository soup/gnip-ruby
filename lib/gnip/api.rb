module Gnip

# TODO - doc the api

  module Api
  #
  #
    def username(*arg)
      default.config.username = arg.first.to_s unless arg.empty?
      default.config.username
    end
    alias_method 'username=', 'username'

    def password(*arg)
      default.config.password = arg.first.to_s unless arg.empty?
      default.config.password
    end
    alias_method 'password=', 'password'

    def uri(*arg)
      default.config.uri = arg.first.to_s unless arg.empty?
      default.config.uri
    end
    alias_method 'uri=', 'uri'

  #
  #
    def ping(*args)
      args, options = Gnip.args_for(args)
      path = args.shift || Gnip.default.ping_path
      options = Gnip.options_for(options)
      resource = options.getopt(:resource, Gnip.default.resource)
      endpoint = resource.endpoint(path)
      !!endpoint.get
    rescue
      raise if options.getopt(:raise)
      false
    end

  #
  #
    def publisher
      Publisher
    end

  #
  #
    def resource
      Resource
    end

  #
  #
    def activity
      Activity
    end

  #
  #
    def filter
      Filter
    end

  #
  #
    def util
      Util
    end

  #
  #
    def config
      Config
    end

  #
  #
    def orderedhash
      OrderedHash
    end

  #
  #
    def clock_drift(*args)
      args, options = Gnip.args_for(args)
      path = args.shift || Gnip.default.ping_path
      options = Gnip.options_for(options)
      resource = options.getopt(:resource, Gnip.default.resource)
      force = options.getopt(:force, false)
      endpoint = resource.endpoint(path)
      @clock_drift = nil if force
      @clock_drift ||= ( Time.httpdate(endpoint.get.headers[:date]).utc - Time.now.utc )
    end

  #
  #
    def Gnip.time
      Time.now.utc + clock_drift
    end

  #
  #
    attr_writer 'scope'

    def scope *arg, &block
      @scope ||= Gnip.default.scope
      if block
        scope = @scope
        begin
          @scope = arg.first.to_s unless arg.empty?
          block.call(@scope)
        ensure
          @scope = scope
        end
      end
      @scope
    end

  #
  #
    def args_for(args)
      Arguments.for(args)
    end
    def argify!(args)
      Arguments.for(args)
    end

    def options_for(args)
      Options.for(args)
    end
    def optify!(args)
      Options.for(args)
    end

  #
  #
    def compress(data)
      util.compress(data)
    end

  #
  #
    def decompress(data)
      util.decompress(data)
    end

  #
  #
    def encode(data)
      util.encode(data)
    end

  #
  #
    def decode(data)
      util.decode(data)
    end


  #
  #
    module Default
      @uri = 'https://api-v21.gnip.com/'
      attr_accessor :uri

      @scope = 'gnip'
      attr_accessor :scope

      @ping_path = '/my/publishers.xml'
      attr_accessor :ping_path

      attr_writer :config
      def config
        @config ||= Config.default
      end

      attr_writer :resource
      def resource
        @resource ||= Resource.default
      end

      extend self
    end

    def default
      Default
    end
  end

  extend Api
end
