module Gnip
  class Filter
    def Filter.list_from_xml(xml, options = {}, &block)
      list = []
      parse_xml(xml, options) do |filter|
        block ? block.call(filter) : list.push(filter)
      end
      block ? nil : list
    end

    def Filter.parse_xml(xml, options = {}, &block)
      doc = Nokogiri::XML.parse(xml)
      list = []
      selectors = 'filter'
      selectors.each do |selector|
        search = doc.search(selector)
        next unless search.size > 0
        search.each do |node|
          filter = Filter.from_node(node, options)
          block ? block.call(filter) : list.push(filter)
        end
      end
      block ? nil : list
    end

    def Filter.from_node(node, options = {})
      full_data = node['fullData'] =~ /true/ ? true : false
      name = node['name']
      post_url = nil
      rules = []
      node.search('rule').each do |rule_node|
        type = rule_node['type']
        value = rule_node.content
        rules << {:type => type, :value => value}
      end
      if post_url_node = node.at('postURL')
        post_url = post_url_node.content
      end
      new(name, rules, :full_data => full_data, :post_url => post_url)
    end

    def Filter.from_xml(xml, options = {})
      parse_xml(xml, options){|filter| return filter}
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

    Attributes << 'post_url'
      def post_url
        @post_url ||= nil
      end
      def post_url= value
        @post_url = String(value)
      end

    Attributes << 'rules'
      def rules
        @rules ||= List.of(Rule)
      end
      def rules= value
        rules.replace(value)
      end

    Attributes << 'full_data'
      def full_data
        @full_data ||= nil
      end
      def full_data= value
        @full_data = !!value
      end

    attr_accessor :publisher

    def initialize(*args)
      args, options = Gnip.args_for(args)
      self.name = args.shift unless args.empty?
      self.rules = args unless args.empty?
      options.each{|key, value| send("#{ key }=", value)}
    end

    class Rule
      def Rule.from_xml(xml, options = {})
        parse_xml(xml, options){|rule| return rule}
      end

      def Rule.parse_xml(xml, options = {}, &block)
        doc = Nokogiri::XML.parse(xml)
        list = []
        selectors = 'rule'
        selectors.each do |selector|
          search = doc.search(selector)
          next unless search.size > 0
          search.each do |node|
            rule = Rule.from_node(node, options)
            block ? block.call(rule) : list.push(rule)
          end
        end
        block ? nil : list
      end

      def Rule.from_node(node, options = {})
        type = node['type']
        value = node.content
        new(:type => type, :value => value)
      end

      def Rule.for(*args)
        arg = args.first if args.size == 1
        if Rule === arg
          arg
        elsif Hash === arg
          new(arg)
        else
          new(*args)
        end
      end

      attr_accessor :type
      attr_accessor :value

      def initialize(*args)
        args, options = Gnip.args_for(args)
        type = value = nil
        case args.size
          when 1
            type, value = args.first.to_s.split(%r/:/, 2)
          when 2
            type, value = args
        end
        self.type = Publisher.rule.for options.getopt(:type, type)
        self.value = options.getopt(:value, value)
      end

      def inspect
        "#{ type }:#{ value }"
      end

      def to_s
        inspect
      end

      def to_yaml(*a, &b)
        to_s.to_yaml(*a, &b)
      end

=begin
      def Rule.template
        @template ||=
          Template.new do
            "
              <rule type=<%= type.inspect %>>
                <%= value %>
              </rule>
            "
          end
      end

      def to_xml(options = {})
        Rule.template.expand(self)
      end
=end

      include Tagz
      def to_xml(*args)
        args, options = Gnip.args_for(args)
        doc = args.shift

        tagz(doc) {
          rule_(:type => type){ value }
        }
      end

      attr_accessor :filter

      def resource
        raise 'filter not set!' unless filter
        rule = self
        filter.publisher.filter.resource["filters/#{ filter.name }/rules?type=#{ rule.type }&value=#{ rule.value }"]
      end

      def delete(options = {})
        Gnip.optify!(options)
        filter = options.getopt(:filter, self.filter)
        resource.delete
        self
      end
    end

    include Tagz
    def to_xml(*args)
      tagz {
        filter_(:name => name, :fullData => !!full_data){
          postURL_{ post_url } if post_url
          rules.each do |rule|
            rule_(:type => rule.type){ rule.value }
          end
          nil
        }
      }
    end

=begin
    def Filter.template
      @template ||=
        Template.new do
          "
            <filter name=<%= name.inspect %> fullData=<%= (!!full_data).to_s.inspect %>>
            % if post_url
              <postURL><%= post_url %></postURL>
            % end
            % rules.each do |rule|
              <rule type=<%= rule.type.inspect %>><%= rule.value %></rule>
            % end
            </filter>
          "
        end
    end

    def to_xml(options = {})
      Filter.template.expand(self)
    end
=end

    def resource
      raise 'publisher not set!' unless publisher
      publisher.filter.resource["filters/#{ name }.xml"]
    end

    def get(*args, &block)
      resource.get(*args, &block)
    end

    def delete(*args, &block)
      resource.delete(*args, &block)
    end

    def put(*args, &block)
      resource.put(*args, &block)
    end

    def post(*args, &block)
      resource.post(*args, &block)
    end

    def replace(other)
      put(other.to_xml)
      publisher.filter.for(name)
    end

    def rule
      @rule ||= RuleResource.new(self)
    end

    class RuleResource
      attr_accessor :filter

      def initialize filter
        @filter = filter
      end

      def publisher
        filter.publisher
      end

      def resource
        publisher.resource
      end

      def list options = {}
        Gnip.optify!(options)
        type = options.getopt(:type) or raise 'no type'
        value = options.getopt(:value) or raise 'no type'
        xml = resource["filters/#{ filter.name }/rules?type=#{ type }&value=#{ value }"].get
        rule = Rule.from_xml(xml)
        rule.filter = filter
        rule
      end

      def for(*args)
        rule = Rule.for(*args)
        list(:type => rule.type, :value => rule.value)
      end

      def delete options = {}
        list(options).delete(:filter => filter)
      end

      def create(*rules)
        rules = rules.map{|rule| Rule.for(rule)}
        slices = [] and rules.each_slice(5000){|slice| slices << slice}
        msg = slices.size > 1 ? 'threadify' : 'each'
        slices.send(msg) do |slice|
          xml = slice.map{|rule| rule.to_xml(:declaration => false)}.join
          resource["filters/#{ filter.name }/rules"].post("<rules>#{ xml }</rules>")
        end
        rules.each{|rule| rule.filter = filter}
        rules
      end
    end
  end
end
