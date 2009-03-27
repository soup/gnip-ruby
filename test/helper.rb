module Gnip
  module Test
    module Helper
      def xml_in s
        @eq_all_but_zero ||= Object.new.instance_eval do
          def ==(other)
            Integer(other) == 0 ? false : true
          end
          self
        end

        s = "#{ s }"

      # munge some hard to compare stuff!
      #
        s.gsub! %r|\<raw\>.*?\</raw\>|mo, '<raw></raw>'

        s.gsub!(%r|\<point\>(.*?)\</point\>|mo) do
          content = Activity::Place::Point.for($1).to_s
          "<point>#{ content }</point>"
        end

        s = XmlSimple.xml_in(s, 'normalisespace' => @eq_all_but_zero)
      end
      def xml_out o
        XmlSimple.xml_out(o)
      end
      def xml_normalized s
        xml_out(xml_in(s))
      end
      def xml_obj s
        xml_in(xml_out(xml_in(s)))
      end
      def xml_cmp!(a, b)
        a = xml_in(a)
        b = xml_in(b)

        #return a==b
        a_keys = a.keys.sort
        b_keys = b.keys.sort
        unless a_keys==b_keys
          STDERR.puts a_keys.inspect
          STDERR.puts ' !=' 
          STDERR.puts b_keys.inspect
          abort
        end
        keys = a_keys.dup
        a_values = keys.map{|k| a[k]}
        b_values = keys.map{|k| b[k]}
        a_values.zip(b_values).each do |a_val, b_val|
          unless a_val==b_val
            STDERR.puts a_val.inspect
            STDERR.puts ' !=' 
            STDERR.puts b_val.inspect
            abort
          end
        end
        true
      end
    end
  end
end


module Kernel
private
  def Test(*args, &block)
    Class.new(::Test::Unit::TestCase) do
      include Gnip::Test::Helper
      args.push 'default' if args.empty?
      context(*args, &block)
    end
  end
end


__END__


module Gnip
  module Test
    Helper = lambda do
      @@should = 0

      def Test.should description, &block
        desc = description.to_s.scan(%r/\w+/).join('__')
        define_method("test_#{ '%03.3d' % (@@should+=1) }_#{ desc }", &block)
      end

      def xml_cmp(a, b)
        eq_all_but_zero = Object.new.instance_eval do
          def ==(other)
            Integer(other) == 0 ? false : true
          end
          self
        end
        a = XmlSimple.xml_in(a.to_s, 'normalisespace' => eq_all_but_zero)
        b = XmlSimple.xml_in(b.to_s, 'normalisespace' => eq_all_but_zero)
        a == b
      end
    end
  end
end

module Kernel
private
  def Test(*args, &block)
    Class.new(::Test::Unit::TestCase) do
      module_eval &::Gnip::Test::Helper
      module_eval &block
    end
  end
end

__END__
