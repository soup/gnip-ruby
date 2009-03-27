Test 'Activty' do
  should 'initialize with no args' do
    activity = nil
    assert_nothing_raised{ assert(activity = Gnip.activity.new) }
  end

  should 'transitively serialize to and from xml' do
    glob = File.join($test_data_dir, 'activity*.xml')
    Dir[glob].each do |activity_xml|
      expected_xml = IO.read(activity_xml)
      activity = nil
      assert_nothing_raised{ activity = Gnip.activity.from_xml(expected_xml) }
      assert activity
      actual_xml = nil
      assert_nothing_raised{ 
        begin
          actual_xml = activity.to_xml 
          xml_cmp!(expected_xml, actual_xml)
        rescue Object => e
          STDERR.puts "\n\n # activity_xml=#{ activity_xml }\n\n"
          raise
        end
      }
    end
  end
end
