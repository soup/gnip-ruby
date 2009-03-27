Class.new(Test::Unit::TestCase) do
  context 'util' do
    setup do
      assert_nothing_raised{ assert(@util = Gnip.util) }
    end

    should 'detect the home directory' do
      assert(test(?d, @util.homedir))
    end

    should 'unindent strings' do
      string = "\n\n  foobar\n  barfoo\n"
      unindented = @util.unindent(string)
      assert "\n\nfoobar\nbarfoo\n", unindented
      assert "\n\nfoobar\nbarfoo\n", @util.unindent!(string) 
      assert "\n\nfoobar\nbarfoo\n", string
    end

    should 'indent strings' do
      string = "\n\n  foobar\n  barfoo\n"
      indented = @util.indent(string, 1)
      assert "\n\n foobar\n barfoo\n", indented
      indented = @util.indent(string, 3)
      assert "\n\n   foobar\n   barfoo\n", indented
      indented = @util.indent!(string, 3)
      assert "\n\n   foobar\n   barfoo\n", indented
      assert "\n\n   foobar\n   barfoo\n", string
    end

    should 'inline strings' do
      string = "\n\n  foobar\n  barfoo\n"
      inlined = @util.inline(string)
      assert "foobar barfoo", inlined
      inlined = @util.inline!(string)
      assert "foobar barfoo", inlined
      assert "foobar barfoo", string
    end
  end
end
