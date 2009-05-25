module Gnip
  class Activity

    def Activity.list_from_xml(xml, &block)
      list = []
      parse_xml(xml) do |activity|
        block ? block.call(activity) : list.push(activity)
      end
      block ? nil : list
    end

    def Activity.from_xml(xml)
      parse_xml(xml){|activity| return activity}
      nil
    end

    def Activity.parse_xml(xml, &block)
      doc = Nokogiri::XML.parse(xml)
      list = []
      selectors = '*/activities', 'activity'
      selectors.each do |selector|
        search = doc.search(selector)
        next unless search.size > 0
        search.each do |node|
          activity = Activity.from_node(node)
          block ? block.call(activity) : list.push(activity)
        end
      end
      block ? nil : list
    end

    def Activity.from_node(node)
      activity = new

      if value = node.at('at')
        activity.at = value.content
      end
      if value = node.at('action')
        activity.action = value.content
      end
      if value = node.at('activityID')
        activity.activity_id = value.content
      end
      if value = node.at('URL')
        activity.url = value.content
      end
      if values = node.search('source')
        values.each{|value| activity.sources << value.content}
      end
      if values = node.search('keyword')
        values.each{|value| activity.keywords << value.content}
      end
      if places = node.search('place')
        places.each do |value|
          place = activity.places.build
          %w( point elev floor featuretypetag featurename relationshiptag ).each do |tag|
            tag_value = value.at(tag)
            place.send("#{ tag }=", tag_value.content) if tag_value
          end
        end
      end
      if values = node.search('actor')
        values.each do |value|
          actor = activity.actors.build
          actor.content = value.content
          actor.meta_url = value['metaURL']
          actor.uid = value['uid']
        end
      end
      if values = node.search('destinationURL')
        values.each do |value|
          destination_url = activity.destination_urls.build
          destination_url.content = value.content
          destination_url.meta_url = value['metaURL']
        end
      end
      if values = node.search('tag')
        values.each do |value|
          tag = activity.tags.build
          tag.content = value.content
          tag.meta_url = value['metaURL']
        end
      end
      if values = node.search('to')
        values.each do |value|
          to = activity.tos.build
          to.content = value.content
          to.meta_url = value['metaURL']
        end
      end
      if values = node.search('regardingURL')
        values.each do |value|
          regarding_url = activity.regarding_urls.build
          regarding_url.content = value.content
          regarding_url.meta_url = value['metaURL']
        end
      end
      if payload_node = node.at('payload')
        activity.payload! do |payload|
          if title_node = payload_node.at('title')
            payload.title = title_node.content
          end
          if body_node = payload_node.at('body')
            payload.body = body_node.content
          end
          if raw_node = payload_node.at('raw')
            payload.raw = payload.decode(raw_node.content)
          end
          if media_url_nodes = payload_node.search('mediaURL')
            media_url_nodes.each do |media_url_node|
              media_url = payload.media_urls.build
              media_url.content = media_url_node.content
              media_url.height = media_url_node['height']
              media_url.width = media_url_node['width']
              media_url.duration = media_url_node['duration']
              media_url.mime_type = media_url_node['mimeType']
              media_url.type = media_url_node['type']
            end
          end
        end
      end

      activity
    end

    def Activity.from_hash(*args)
      args, options = Gnip.args_for(args)

      activity = new

      %w(
        at
        action
        activity_id
        url
        sources
        keywords
        places
        actors
        destination_urls
        tags
        tos
        regarding_urls
        payload
      ).each do |opt|
        if options.hasopt?(opt)
          activity.send("#{ opt }=", options.getopt(opt))
        end
      end

      activity
    end

    def Activity.from_yaml(string)
      string = string.read if string.respond_to?(:read)
      to_hash(YAML.load(string))
    end

    Attributes = []

    Attributes << 'activity_id'
      def activity_id
        @activity_id ||= nil
      end
      def activity_id= value
        @activity_id = value.to_s
      end

    Attributes << 'at'
      def at
        @at ||= nil
      end
      def at= value
        @at = Time === value ? value : Time.parse(value.to_s).utc #.iso8601(3)
      end

    Attributes << 'action'
      def action
        @action ||= nil
      end
      def action= value
        @action = value.to_s
      end

    Attributes << 'url'
      def url
        @url ||= nil
      end
      def url= value
        @url = value.to_s
      end

    Attributes << 'sources'
      def sources
        @sources ||= List.of(String)
      end
      def sources= value
        sources.replace(value)
      end

    Attributes << 'keywords'
      def keywords
        @keywords ||= List.of(String)
      end
      def keywords= value
        keywords.replace(value)
      end

    Attributes << 'places'
      def places
        @places ||= List.of(Place)
      end
      def places= value
        places.replace(value)
      end

    Attributes << 'actors'
      def actors
        @actors ||= List.of(Actor)
      end
      def actors= value
        actors.replace(value)
      end

    Attributes << 'destination_urls'
      def destination_urls
        @destination_urls ||= List.of(DestinationURL)
      end
      def destination_urls= value
        destination_urls.replace(value)
      end

    Attributes << 'tags'
      def tags
        @tags ||= List.of(Tag)
      end
      def tags= value
        tags.replace(value)
      end

    Attributes << 'tos'
      def tos
        @tos ||= List.of(To)
      end
      def tos= value
        tos.replace(value)
      end

    Attributes << 'regarding_urls'
      def regarding_urls
        @regarding_urls ||= List.of(RegardingURL)
      end
      def regarding_urls= value
        regarding_urls.replace(value)
      end

# TODO - extend this pattern to other elements
#
    Attributes << 'payload'
      def payload(*args, &block)
        return payload!(*args, &block) if block
        @payload ||= nil
      end
      def payload!(*args, &block)
        @payload = Payload.for(*args)
        block ? block.call(@payload) : @payload
      end
      def payload= value
        @payload = Payload.for(value)
      end

    attr_accessor :gnip_resource_uri

    def initialize(options = {})
      options = Gnip.options_for(options)
      options.each{|key, value| send("#{ key }=", value)}
    end

    include Tagz
    def to_xml(*args)
      args, options = Gnip.args_for(args)
      doc = args.shift

      tagz(doc) {
        activity_{
          at_{ at.utc.iso8601(3) }
          action_{ action.to_s }
    
          if activity_id
            activityID_{ activity_id }
          end
          if url
            URL_{ url }
          end
          if sources
            sources.each{|source| source_{ source } }
          end
          if keywords
            keywords.each{|keyword| keyword_{ keyword } }
          end
          if places
            places.each{|place| place.to_xml(tagz)}
          end
          if actors
            actors.each{|actor| actor.to_xml(tagz)}
          end
          if destination_urls
            destination_urls.each{|destination_url| destination_url.to_xml(tagz)}
          end
          if tags
            tags.each{|tag| tag.to_xml(tagz)}
          end
          if tos
            tos.each{|to| to.to_xml(tagz)}
          end
          if regarding_urls
            regarding_urls.each{|regarding_url| regarding_url.to_xml(tagz)}
          end
          if payload
            payload.to_xml(tagz)
          end
        }
      }
    end

    class Place
      def Place.for(*args, &block)
        arg = args.first if(args.size == 1 and args.first.is_a?(Place))
        new(*args, &block)
      end

      def initialize(options = {}, &block)
        options.each{|key, value| send "#{ key }=", value}
      end

      class Point
        def Point.for(*args, &block)
          new(*args, &block)
        end

        attr_accessor :lat
        attr_accessor :lon

        def initialize(*args)
          @lat, @lon = Point.parse(*args)
        end

        def Point.parse(*args)
          string = args.join(' ')
          coords = string.strip.split(%r/\s+/, 2).map{|coord| Util.number_for(coord)}
          raise ArgumentError, args.inspect unless coords.size == 2
          coords
        end

        def to_s
          [@lat, @lon].join(' ')
        end

        def format n
          '%03.3f' % n
        end
      end

      attr :point
      def point= value
        @point = Point.for(value)
      end

      attr :elev
      def elev= value
        @elev = Util.number_for(value)
      end

      attr :floor
      def floor= value
        @floor = Util.number_for(value).to_i
      end

      attr :featuretypetag
      def featuretypetag= value
        @featuretypetag = String(value)
      end

      attr :featurename
      def featurename= value
        @featurename = String(value)
      end

      attr :relationshiptag
      def relationshiptag= value
        @relationshiptag = String(value)
      end

      def to_yaml(*a, &b)
        oh = OrderedHash.new
        oh['point'] = [point.lat, point.lon] if point
        oh['elev'] = elev
        oh['floor'] = floor
        oh['featuretypetag'] = featuretypetag
        oh['featurename'] = featurename
        oh['relationshiptag'] = relationshiptag
        oh.to_yaml(*a, &b)
      end

      include Tagz
      def to_xml(*args)
        args, options = Gnip.args_for(args)
        doc = args.shift

        tagz(doc) {
          place_{
            point_{ point } if point
            elev_{ elev } if elev
            floor_{ floor } if floor
            featuretypetag_{ featuretypetag } if featuretypetag
            featurename_{ featurename } if featurename
            relationshiptag_{ relationshiptag } if relationshiptag
          }
        }
      end
    end

    class MetaURL
      attr_accessor :content
      attr_accessor :meta_url

      def MetaURL.for(*args)
        arg = args.flatten.compact.first
        self.class === arg ? arg : new(*args)
      end

      def initialize(*args)
        args, options = Gnip.args_for(args)
        self.content = args.join unless args.empty?
        options.each{|k,v| send "#{ k }=", v}
      end

      def to_yaml(*a, &b)
        oh = OrderedHash.new
        oh['content'] = content
        oh['meta_url'] = meta_url
        oh.to_yaml(*a, &b)
      end

      include Tagz
      def to_xml(*args)
        args, options = Gnip.args_for(args)
        doc = args.shift
        tagz(doc){ send("#{ xml_tag }_", xml_attributes){ content } }
      end

      def xml_attributes
        attributes = {}
        attributes.update(:metaURL => meta_url) if meta_url
        attributes
      end

      def xml_tag
        self.class.const_get(:XML_TAG)
      end
    end

    class Actor < MetaURL
      XML_TAG = 'actor'

      attr_accessor :uid

      def to_yaml(*a, &b)
        oh = OrderedHash.new
        oh['content'] = content
        oh['meta_url'] = meta_url
        oh['uid'] = uid
        oh.to_yaml(*a, &b)
      end

      def xml_attributes
        attributes = super
        attributes.update(:uid => uid) if uid
        attributes
      end
    end

    class Tag < MetaURL
      XML_TAG = 'tag'
    end

    class To < MetaURL
      XML_TAG = 'to'
    end

    class DestinationURL < MetaURL
      XML_TAG = 'destinationURL'
    end

    class RegardingURL < MetaURL
      XML_TAG = 'regardingURL'
    end

    class Payload
      def Payload.for(*args)
        return args.first if(args.size == 1 and args.first.is_a?(Place))
        new(*args)
      end

      def initialize(options = {}, &block)
        options.each{|key, value| send "#{ key }=", value}
      end

      def title
        @title ||= nil
      end
      def title= title
        @title = String(title)
      end

      def body
        @body ||= nil
      end
      def body= body
        @body = String(body)
      end

      def media_urls
        @media_urls ||= List.of(MediaURL)
      end
      def media_urls= value
        media_urls.replace value
      end

      def raw
        @raw ||= nil
      end
      def __raw__
        @raw ||= nil
      end
      def raw= raw
        @raw = raw
      end
      def __raw__= raw
        @raw = raw
      end

      include Tagz
      def to_xml(*args)
        args, options = Gnip.args_for(args)
        doc = args.shift
        tagz(doc){
          payload_{
            title_{ title } if title
            body_{ normalize(body) } if body
            media_urls.each{|media_url| media_url.to_xml(tagz)} if media_urls
            raw_{ encode(raw) } if raw
          }
        }
      end

      def encode(data)
        Util.encode(raw)
      end

      def decode(raw)
        Util.decode(raw)
      end

      def normalize(string)
        Util.normalize!(string)
      end

      class MediaURL
        attr_accessor :content
        attr_accessor :height
        attr_accessor :width
        attr_accessor :duration
        attr_accessor :mime_type
        attr_accessor :type

        def initialize(*args)
          args, options = Gnip.args_for(args)
          self.content = args.join
          options.each{|k,v| send "#{ k }=", v}
        end

        def to_yaml(*a, &b)
          oh = OrderedHash.new
          oh['content'] = content
          oh['height'] = height
          oh['width'] = width
          oh['duration'] = duration
          oh['mime_type'] = mime_type
          oh['type'] = type
          oh.to_yaml(*a, &b)
        end

        include Tagz
        def to_xml(*args)
          args, options = Gnip.args_for(args)
          doc = args.shift
          tagz(doc){
            options = {}
            options['height'] = height if height
            options['width'] = width if width
            options['duration'] = duration if duration
            options['mimeType'] = mime_type if mime_type
            options['type'] = type if type
            mediaURL_(options){ content }
          }
        end
      end
    end

    class Stream
      def Stream.from_xml(xml, options = {}, &block)
        doc = Nokogiri::XML.parse(xml)
        selector = 'activityStream'
        node = doc.at(selector)
        Stream.from_node(node)
      end

      def Stream.from_node(node)
        updated_at = node.at('activitiesAddedAt').content
        buckets = []
        node.search('bucket').each do |bucket|
          buckets << bucket['href']
        end
        Stream.new(:updated_at => updated_at, :buckets => buckets)
      end

      Attributes = []

      Attributes << 'updated_at'
        def updated_at
          @updated_at ||= nil
        end
        def updated_at= value
          @updated_at = Time.parse(value.to_s)
        end

      Attributes << 'buckets'
        def buckets
          @buckets ||= List.of(String)
        end
        def buckets= value
          buckets.replace(value)
        end

        def initialize(options = {})
          options = Gnip.options_for(options)
          options.each{|key, value| send("#{ key }=", value)}
        end
    end

    def Activity.stream(options = {})
      options = Gnip.options_for(options)
      scope = options.getopt(:scope, Gnip.scope)
      resource = options.getopt(:resource, Gnip.default.resource)
      style = options.getopt(:style, 'activity')
      publisher = options.getopt(:publisher)
      endpoint = resource.endpoint "#{ scope }/publishers/#{ publisher.name }/#{ style }.xml"
      response = endpoint.get
      xml = response.to_s
      Activity::Stream.from_xml(xml)
    end

  end
end
