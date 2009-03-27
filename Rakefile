task 'default' => 'test:all'

namespace 'test' do
  desc 'run all tests'
    task 'all' => %w[ unit integration ] do
    end

  desc 'run unit tests'
    task 'unit' do
      %w[
        activity
      ].each do |basename|
        test_loader "test/unit/#{ basename }.rb"
      end
    end

  desc 'run integration tests'
    task 'integration' do
      %w[
        auth
        publisher
      ].each do |basename|
        test_loader "test/integration/#{ basename }.rb", :require_auth => true
      end
    end
end

task 'test' => 'test:all' do
end

namespace 'gem' do
  task 'build' do
    sh 'gemspec.rb'
  end
  task 'release' => 'build' do
    gem = Dir['gnip*.gem'].sort.last or abort('no gem!')
    version = gem[%r/[\d.]+/]
    command = "rubyforge login && rubyforge add_release gnip 'gnip' '#{ version }' '#{ gem }'"
    sh command
  end
end

BEGIN {
  Dir.chdir(File.dirname(__FILE__))
  ENV['PATH'] = [ '.', './bin/', ENV['PATH'] ].join(File::PATH_SEPARATOR)

  def test_loader basename, options = {}
    auth = '-r test/auth.rb ' if options[:require_auth]
    command = "ruby -r test/loader.rb #{ auth }#{ basename }"
    STDERR.print "\n==== TEST ====\n\n  #{ command }\n\n==============\n\n"
    system command or abort("#{ command } # FAILED WITH #{ $?.inspect }")
  end
}
