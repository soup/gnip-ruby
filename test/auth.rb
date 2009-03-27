# ensure gnip auth info is configured for integration tests
#
  require 'yaml'

  $config =
    begin
      YAML.load(IO.read(File.expand_path('~/.gnip.yml')))
    rescue
      begin
        YAML.load(IO.read('test/gnip.yml'))
      rescue
        {}
      end
    end

  $username = $config['username']||ENV['GNIP_USERNAME']||ENV['gnip_username']||ENV['USERNAME']||ENV['username']
  $password = $config['password']||ENV['GNIP_PASSWORD']||ENV['gnip_password']||ENV['PASSWORD']||ENV['password']

  unless $username and $password
    div = '=' * 79

    message = <<-message
      #{ div }

      you need to have a gnip account and set both your username and password
      in the environment to run integration tests.  you can get a gnip account
      at

        http://gnip.com/

      there are 3 ways to setup your username and password for the tests

        1. via the environment variable:

            export GNIP_USERNAME=your.username@domain.org
            export GNIP_PASSWORD=your-password


        2. pass them in as rake variables:

          rake username=me@domain.org password=secret
          rake test:unit username=me@domain.org password=secret
          rake test:integration USERNAME=me@domain.org PASSWORD=secret


        3. edit either ~/gnip.yml or ./test/gnip.yml to look similar to this

          username : your.username@domain.org
          password : your_password

      #{ div }
    message

    indent = message[ %r/^([\s]+)[^\s]/ ].to_s
    message.gsub!(%r/^#{ indent }/, '')
    abort message
  end

  ENV['GNIP_USERNAME'] = $username
  ENV['GNIP_PASSWORD'] = $password
