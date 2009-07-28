module Gnip
  class Publisher
    def Publisher.list(options = {})
      options = Gnip.optify!(options)
      scope = options.getopt(:scope, Gnip.scope)
      resource = options.getopt(:resource, Gnip.default.resource)
      endpoint = resource.endpoint "#{ scope }/publishers.xml"
      response = endpoint.get
      xml = response.to_s
      Publisher.list_from_xml(xml, :scope => scope)
    end

    def Publisher.list_from_xml(xml, options = {}, &block)
      list = []
      parse_xml(xml, options) do |publisher|
        block ? block.call(publisher) : list.push(publisher)
      end
      block ? nil : list
    end

    def Publisher.from_xml(xml, options = {}, &block)
      parse_xml(xml, options){|publisher| return publisher}
    end

    def Publisher.parse_xml(xml, options = {}, &block)
      doc = Nokogiri::XML.parse(xml)
      list = []
      selectors = '*/publishers', 'publisher'
      selectors.each do |selector|
        search = doc.search(selector)
        next unless search.size > 0
        search.each do |node|
          publisher = Publisher.from_node(node, options)
          block ? block.call(publisher) : list.push(publisher)
        end
      end
      block ? nil : list
    end

    def Publisher.from_node(node, options = {})
      name = node['name']
      rules = node.search('supportedRuleTypes/type').map{|type| type.content}
      Publisher.new(name, options.update(:rules => rules))
    end

    def Publisher.for name, options = {}
      options = Gnip.optify!(options)
      scope = options.getopt(:scope, Gnip.scope)
      resource = options.getopt(:resource, Gnip.default.resource)
      endpoint = resource["#{ scope }/publishers/#{ name }.xml"]
      response = endpoint.get
      xml = response.to_s
      publisher = Publisher.from_xml(xml)
      publisher.scope = scope
      publisher
    end

    def Publisher.exists?(*args, &block)
      Publisher.for(*args, &block) rescue false
    end

    def Publisher.resource
      @resource ||= Gnip.default.resource
    end

    def Publisher.create(*args, &block)
      publisher = new(*args, &block)
      resource = Publisher.resource["#{ publisher.scope }/publishers.xml"]
      resource.post(publisher.to_xml(:declaration => true))
      Publisher.for(publisher.name, :scope => publisher.scope)
    end

    def Publisher.delete(name, options = {})
      if publisher = Publisher.exists?(name, options)
        publisher.delete
      end
    end

    Attributes = []

    Attributes << 'name'
      def name
        @name ||= nil
      end
      def name= value
        @name = String(value)
      ensure
        raise ArgumentError, @name unless @name =~ %r/^[a-zA-Z0-9.+-]+$/
      end

    Attributes << 'rules'
      def rules
        @rules ||= List.of(String)
      end
      def rules= value
        rules.replace(value)
      end

    attr_accessor :scope

    def initialize(*args)
      args, options = Gnip.args_for(args)
      self.name = args.shift if args.first
      @scope = options.getopt(:scope, Gnip.scope).to_s
      @resource = options.getopt(:resource, Gnip.default.resource)
      rules = options.getopt(:rules, []).flatten.compact
      @rules = rules.map{|rule| Rule.for(rule)}
    end

    def resource
      @resource["#{ scope }/publishers/#{ name }"]
    end



    class Rule < ::String
      List = []

      %w[ actor tag to regarding source keyword action ].each do |name|
        module_eval <<-code
          def Rule.#{ name }
            @#{ name } ||= Rule.new('#{ name }').freeze
          end
        code
        List << Rule.send(name)
      end

      List.freeze

      def Rule.list
        List
      end

      def Rule.for(name)
        send(name.to_s.downcase.strip)
      rescue
        raise ArgumentError, "bad rule type #{ name.inspect }" 
      end

      def Rule.[] name
        Rule.for(name)
      end
    end

    def Publisher.rule
      Rule
    end

    include Tagz
    def to_xml(*args)
      args, options = Gnip.args_for(args)
      doc = args.first

      tagz(doc) {
        publisher_(:name => name){
          supportedRuleTypes_{
            rules.each{|rule| type_{ rule }}
          }
        }
      }
    end

=begin
    def Publisher.template
      @template ||=
        Template.new do
          "
            <publisher name=<%= name.inspect %>>
              <supportedRuleTypes>
            % rules.each do |rule|
              <type><%= rule %></type>
            % end
              </supportedRuleTypes>
            </publisher>
          "
        end
    end

    def to_xml(options = {})
      Publisher.template.expand(self)
    end
=end


    def delete
      Publisher.resource["#{ scope }/publishers/#{ name }"].delete
      self
    end

    def activity_stream options = {}
      Activity.stream(options.update(:publisher => self, :scope => scope))
    end

    def activity options = {}, &block
      Gnip.optify!(options)

      style = options.getopt(:style, 'activity').to_s
      raise ArgumentError unless %w( activity notification ).include?(style)


      bucket = options.getopt(:bucket)
      ago = options.getopt(:ago)
      thru = options.getopt(:thru, options.getopt(:through))

      if Range === ago
        ago, thru = [ago.begin, ago.end].sort.reverse
      end

      unless bucket
        bucket = ago ? bucket_for_minutes_ago(ago) : 'current'
      end

      filter = options.getopt(:filter)
      filter = filter.value if(filter and filter.respond_to?(:value))
      filter = filter.name if(filter and filter.respond_to?(:name))

      buckets =
        if thru
          thru = 0 if thru =~ /current|now/i
          a, b = [ago, Integer(thru)].sort
          (a..b).to_a.reverse.map{|i| bucket_for_minutes_ago(i)}
        else
          if bucket =~ /all/i
            stream = send("#{ style }_stream")
            stream.buckets.map{|bucket| File.basename(bucket, '.xml')}
          else
            [bucket]
          end
        end

      buckets.map! do |bucket|
        bucket.is_a?(Time) ? bucket.strftime('%Y%m%d%H%M') : bucket
      end

      activities = []

      msg = buckets.size > 1 ? 'threadify' : 'each'

      buckets.send(msg) do |bucket|
        path = "#{ style }/#{ bucket }.xml"
        path = "filters/#{ filter }/#{ path }" if filter
        xml = resource[path].get
        Activity.list_from_xml(xml) do |activity|
          activity.gnip_resource_uri = resource[path].uri
          block ? block.call(activity) : activities.push(activity)
        end
      end

      activities unless block
    end

    def bucket_for_minutes_ago ago
      bucket = Gnip.time - (Integer(ago) * 60)
      bucket.strftime('%Y%m%d%H%M')
    end

    def notification_stream options = {}
      Activity.stream(options.update(:publisher => self, :scope => scope, :style => 'notification'))
    end

    def notifications options = {}
      Gnip.optify!(options)
      options.setopt!(:style, 'notification') unless options.hasopt?(:style)
      activity(options)
    end

    def publish *activities
      activities.flatten!
      activities.compact!
      #xml = "<activiies>#{ activities.map{|activity| activity.to_xml} }</activities>"
      xml = tagz { activities_{ activities.map{|activity| activity.to_xml(tagz.doc)} } }
      resource['activity.xml'].post(xml)
      activities
    end


    def filter
      @filter ||= FilterResource.new(self)
    end

    class FilterResource
      attr_accessor :publisher

      def initialize publisher
        @publisher = publisher
      end

      def resource
        publisher.resource
      end

      def list
        xml = resource['filters.xml'].get
        Filter.list_from_xml(xml).each{|filter| filter.publisher = publisher}
      end

      def for name
        xml = resource["filters/#{ name }.xml"].get
        filter = Filter.from_xml(xml)
      ensure
        filter.publisher = publisher if filter
      end

      alias_method '[]', 'for'

      def create(name, rules, options)
        Gnip.optify!(options)
        filter = Filter.new(name, rules, options)
        resource['filters.xml'].post(filter.to_xml(:declaration => true))
        filter = self.for(name)
      ensure
        filter.publisher = publisher if filter
      end
    end
  end
end
