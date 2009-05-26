# built-in libs
#
  require 'yaml'
  require 'time'
  require 'zlib'
  require 'enumerator'
  require 'base64'
  # require 'erb'

# gems and third party libs
#
  begin
    require 'rubygems'
    gem 'tagz', '>= 5.0.1'
  rescue LoadError
    'oh noes!'
  end

  begin
    require 'restclient'
  rescue
    abort 'sudo gem install rest-client'
  end

  begin
    require 'nokogiri'
  rescue
    abort 'sudo gem install nokogiri #=> depends on libxml + libxslt'
  end

  begin
    require 'tagz'
  rescue
    abort 'sudo gem install tagz'
  end

  begin
    require 'threadify'
  rescue
    abort 'sudo gem install threadify'
  end

# gnip libs
#
  module Gnip
    Version = '1.1.0'

    def version
      Gnip::Version
    end

    def libdir(*args)
      @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/,'')
      args.empty? ? @libdir : File.join(@libdir, *args)
    end
    extend self
  end

  require Gnip.libdir('util')
  require Gnip.libdir('orderedhash')
  # require Gnip.libdir('blankslate')
  require Gnip.libdir('arguments')
  require Gnip.libdir('options')
  require Gnip.libdir('list')
  require Gnip.libdir('config')
  require Gnip.libdir('resource')
  # require Gnip.libdir('template')
  require Gnip.libdir('publisher')
  require Gnip.libdir('filter')
  require Gnip.libdir('activity')
  require Gnip.libdir('api')
