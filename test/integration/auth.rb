Class.new(Test::Unit::TestCase) do
  context 'with username and password configured' do
    setup do
      assert( Gnip.username = ENV['GNIP_USERNAME'] )
      assert( Gnip.password = ENV['GNIP_PASSWORD'] )
    end

    should 'be able to do an authenticated ping' do
      assert_nothing_raised{ assert Gnip.ping }
    end
  end
end
