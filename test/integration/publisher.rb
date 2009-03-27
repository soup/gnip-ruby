Class.new(Test::Unit::TestCase) do
  context 'with username and password configured' do
    setup do
      assert( Gnip.username = ENV['GNIP_USERNAME'] )
      assert( Gnip.password = ENV['GNIP_PASSWORD'] )
    end

    should 'be able to retreive a list of /gnip publishers' do
      list = nil
      assert_nothing_raised{ assert list=Gnip.publisher.list }
      assert list
      assert !list.empty?, 'not empty list'
      list.each do |object|
        assert object.respond_to?(:name), 'responds_to?(:name)'
        assert object.respond_to?(:rules), 'responds_to?(:rules)'
      end
    end

    should 'be able to get the notifications for publishers' do
      list = nil
      assert_nothing_raised{ assert list=Gnip.publisher.list }
      assert list
      list.each do |publisher|
        notifications = nil
        assert_nothing_raised{ assert notifications=publisher.notifications }
        assert notifications
      end
    end

    should 'be able to retreive a list of /my publishers' do
      list = nil
      assert_nothing_raised{ assert list=Gnip.publisher.list(:scope => 'my') }
      assert list
    end

    should 'be able to retreive a given publisher by name in the /gnip scope' do
      publisher = nil
      name = 'gnip-sample'
      assert_nothing_raised{ publisher = Gnip.publisher.for(name) }
      assert publisher
      assert name, publisher.name
    end

    should 'be able to retreive a given publisher with their rules boy!' do
      publisher = nil
      name = 'gnip-sample'
      assert_nothing_raised{ publisher = Gnip.publisher.for(name) }
      assert publisher
      assert name, publisher.name
      rules = []
      assert_nothing_raised{ rules = publisher.rules }
      assert !rules.empty?
      assert Gnip.publisher.rule.list.include?(rules.first)
      assert Gnip.publisher.rule.list.include?(rules.last)
    end

    context 'creating and destroying publishers' do
      setup do
        @hostname = Socket.gethostname rescue `hostname`.strip
        @hostname = Array.new(4).map{ rand(256) }.join('.') if @hostname.strip.empty?
        @hostname = @hostname.to_s.gsub %r/[^a-zA-Z0-9]/, '-'
        @name = "gnip-ruby-integration-test-#{ @hostname }"
        @rules = Gnip.publisher.rule.list
      end

      should 'be able to create and delete a publisher in the /my scope' do
        publisher = Gnip.publisher.exists?(@name, :scope => :my)
        if publisher
          assert_nothing_raised{ Gnip.publisher.delete(@name, :scope => :my) }
          assert !Gnip.publisher.exists?(@name, :scope => :my)
        end

        publisher = nil
        assert_nothing_raised{ publisher = Gnip.publisher.create(@name, :scope => :my, :rules => @rules) }
        assert publisher
        assert_equal publisher.name, @name
        assert_equal publisher.scope.to_s, 'my' 

        deleted = nil
        assert_nothing_raised{ deleted = publisher.delete }
        assert deleted
        assert deleted.name, publisher.name
      end
    end
  end
end
