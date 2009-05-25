module Gnip
  class Resource
    def Resource.default
      @default ||= new
    end

    def Resource.headers headers = {}
      result = default_headers.dup

      headers.each do |key, value|
        key = key.to_s.downcase.split(%r/[_-]/).map{|part| part.capitalize}.join('-')
        result[key] = value
      end

      result

=begin
      default_headers.dup.merge(headers).inject({}) do |final, (key, value)|
        final[key.to_s.gsub(/_/, '-').capitalize] = value.to_s
        final
      end
=end
    end

    def Resource.default_headers
      @default_headers ||= {
        'Content-Type' => 'application/xml',
        'User-Agent' => 'gnip.rb',
        'Content-Encoding' => 'gzip',
        'Accept-Encoding' => 'gzip',
      }
    end

    def Resource.compress(data)
      writer = Zlib::GzipWriter.new(StringIO.new(result=''))
      writer.write(data)
      writer.close
      result
    end

    def Resource.uncompress(data)
      Zlib::GzipReader.new(StringIO.new(data)).read
    end

    attr_accessor :config

    def initialize(*args)
      args, options = Gnip.args_for(args)
      @config = args.shift || options.getopt(:config, Gnip.default.config)
      which = options.getopt(:implementation, :restclient)
      @implementation = Implementation.for(self, which)
    end

    def method_missing(m, *a, &b)
      if @implementation.respond_to?(m)
        @implementation.send(m, *a, &b)
      else
        super
      end
    end

    def Resource.method_missing(m, *a, &b)
      if Implementation.respond_to?(m)
        Implementation.send(m, *a, &b)
      else
        super
      end
    end

    def uri_for(*args)
      args, options = Gnip.args_for(args)
      uri = config.uri.dup
      uri.path = "/#{ args.shift }".squeeze('/')
      options.each{|k,v| uri.send "#{ k }=", v}
      uri
    end

    def [](*args, &block)
      @implementation.send('[]', *args, &block)
    end
    alias_method 'endpoint', '[]'
    alias_method '/', '[]'

# TODO - requires username and password?
#
    class Implementation
      class RestClient < Implementation
        attr_accessor :interface
        attr_accessor :resource

        def initialize interface, options = {}
          Gnip.options_for(options)
          @interface = interface
          uri = options.getopt(:uri, config.uri)
          username = options.getopt(:username, config.username)
          password = options.getopt(:password, config.password)
          headers = options.getopt(:headers, default_headers)
          @resource = ::RestClient::Resource.new(uri, :user => username, :password => password, :headers => headers)
        end

        def default_headers
          {
            :content_type => 'application/xml',
            :user_agent => 'gnip.rb',
            :content_encoding => 'gzip',
            :accept_encoding => 'gzip',
          }
        end

        def compress(data, headers = {})
          key = (resource.headers.keys + headers.keys).detect{|key| key.to_s =~ /^\s*content.encoding\s*$/i}
          value = resource.headers[key] || headers[key] if key
          ( value.to_s =~ /gzip/ ? Util.compress(data) : data ).to_s
        end

        def decompress(data)
          Util.decompress(data.to_s).to_s
        end

        def config
          interface.config
        end

        def uri
          URI.parse resource.url.to_s
        end

        def username
          resource.user
        end

        def password
          resource.password
        end

        def [] path
          subresource = resource[relative_path(path)]
          subclient = dup
          subclient.resource = subresource
          subclient
        end
        alias_method 'endpoint', '[]'
        alias_method '/', '[]'

        def for options = {}
          Gnip.options_for(options)
          path = options.getopt(:path)
          if path
            uri = URI.parse(resource.uri)
            uri.path = absolute_path(path)
            self.class.new(interface, :uri => uri, :username => username, :password => password)
          else
            raise ArgumentError
          end
        end

        class Error < ::StandardError
          attr :error
          def initialize message = nil, error = nil
            super(message.to_s)
            @error = error
          end
        end

        def wrapping_errors
          begin
            yield
          rescue => error
            message = []
            message << error.message if error.respond_to?(:message) rescue nil
            message << error.response.body if error.respond_to?(:response) rescue nil
            message = message.join(' #=> ')
            raise Error.new(message, error)
          end
        end

        %w[ get delete post put ].each do |verb|
          define_method(verb) do |*args|
            Gnip.argify!(args)
            headers = args.options
            data = args.shift

            args = []
            args.push(compress(data, headers)) if data
            args.push(headers)

            wrapping_errors do
              log_request(verb, data, headers)
              log_response(resource.send(verb, *args))
            end
          end
        end

        def inspect
          options = resource.headers.dup.update(:username => username, :password => password)
          "#{ resource.url }(#{ options.inspect })"
        end
      end

      def absolute_path(*paths)
        paths.join('/').squeeze('/').sub(%r|^/+|, '/')
      end

      def relative_path(*paths)
        absolute_path(*paths).sub(%r|^/+|, '')
      end

      def log_request verb, data = nil, headers = {}
        log {
          if data
            data = data.size > log_max_size ? "#{ data[0,log_max_size] }...(#{ data.size }bytes)" : data
          end
          "\n#{ self.inspect }.#{ verb }(#{ data.inspect }, #{ headers.inspect })"
        }
      end

      def log_response response
        log {
          data = response.to_s
          data = data.size > log_max_size ? "#{ data[0,log_max_size] }...(#{ data.size }bytes)" : data
          "#{ data }"
        }
        response
      end

      def Implementation.log= value
        @@log =
          case value
            when STDERR, 'stderr', :stderr
              STDERR
            when STDOUT, 'stdout', :stdout
              STDOUT
            else
              if respond_to?(:write)
                value
              else
                fd = open(value, 'w')
              end
          end
      ensure
        @@log.sync = true if @@log.respond_to?(:sync)
      end

      def Implementation.log
        unless defined?(@@log)
          if value = ENV['GNIP_HTTP_LOG']
            Implementation.log = value
          else
            @@log = nil
          end
        end
        @@log
      end

      def log &block
        if Implementation.log and block
          log.puts block.call
          log.flush
        else
          Implementation.log
        end
      end

      def Implementation.log_max_size
        unless defined?(@@log_max_size)
          if value = ENV['GNIP_HTTP_LOG_MAX_SIZE']
            Implementation.log_max_size = value
          else
            @@log_max_size = 4096
          end
        end
        @@log_max_size
      end

      def Implementation.log_max_size= value
        @@log_max_size = Integer value
      end

      def log_max_size
        Implementation.log_max_size
      end

      def Implementation.list
        @list ||= [
          RestClient
        ]
      end

      def Implementation.for endpoint, which
        implementation =
          case which = which.to_s.downcase.strip.to_sym
            when :restclient
              RestClient
            else
              raise ArgumentError, "unknown implementation #{ which }"
          end 
        implementation.new(endpoint)
      end
    end
  end
end
