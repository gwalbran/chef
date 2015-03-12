require 'foodcritic'

task :default => [:foodcritic]
FoodCritic::Rake::LintTask.new do |t|
  t.files = "#{Dir.pwd}/cookbooks"
end

require 'rspec/core/rake_task'
desc 'Run ChefSpec unit tests'
RSpec::Core::RakeTask.new(:spec) do |t, args|
  t.verbose = false
  t.fail_on_error = true
  t.pattern = "cookbooks/*/spec/*_spec.rb"
  t.rspec_opts = "--color"
end
