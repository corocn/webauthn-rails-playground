# frozen_string_literal: true

require 'open3'

namespace :db do
  def apply(options)
    config_file = Rails.root.join('config', 'database.yml')
    schema_file = Rails.root.join('db', 'Schemafile')

    command = "bundle exec ridgepole -c #{config_file} -f #{schema_file} #{options} -E #{Rails.env}"
    puts command

    out = []

    Open3.popen2e(command) do |stdin, stdout_and_stderr, _wait_thr|
      stdin.close

      stdout_and_stderr.each_line do |line|
        out << line
        yield(line) if block_given?
      end
    end

    out.join("\n")
  end

  task 'migrate' => :environment do
    ENV['RAILS_ENV'] ||= 'development'
    apply('--apply') do |line|
      puts line
    end
  end

  desc 'apply dry run'
  task :'apply-dry-run' do
    apply('--apply --dry-run') do |line|
      puts line
    end
  end
end
