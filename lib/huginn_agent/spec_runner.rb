require 'huginn_agent/helper'

class HuginnAgent
  class SpecRunner
    attr_reader :gem_name

    def initialize
      @gem_name = File.basename(Dir['*.gemspec'].first, '.gemspec')
      $stdout.sync = true
    end

    def clone
      unless File.exists?('spec/huginn/.git')
        shell_out "git clone #{HuginnAgent.remote} -b #{HuginnAgent.branch} spec/huginn", 'Cloning huginn source ...'
      end
    end

    def reset
      Dir.chdir('spec/huginn') do
        shell_out "git fetch && git reset --hard origin/#{HuginnAgent.branch}", 'Resetting Huginn source ...'
      end
    end

    def bundle
      if File.exists?('.env')
        shell_out "cp .env spec/huginn"
      end
      Dir.chdir('spec/huginn') do
        shell_out "bundle install --without development production -j 4", 'Installing ruby gems ...'
      end

    end

    def database
      Dir.chdir('spec/huginn') do
        shell_out('bundle exec rake db:create db:migrate', 'Creating database ...')
      end
    end

    def spec
      Dir.chdir('spec/huginn') do
        shell_out "bundle exec rspec ../*_spec.rb ../**/*_spec.rb", 'Running specs ...', true
      end
    end

    def shell_out(command, message = nil, streaming_output = false)
      print message if message

      (status, output) = Bundler.with_clean_env do
        ENV['ADDITIONAL_GEMS'] = "#{gem_name}(path: ../../)"
        ENV['RAILS_ENV'] = 'test'
        HuginnAgent::Helper.open3(command, streaming_output)
      end

      if status == 0
        puts "\e[32m [OK]\e[0m" if message
      else
        puts "\e[31m [FAIL]\e[0m" if message
        puts "Tried executing '#{command}'"
        puts output
        fail
      end
    end
  end
end
