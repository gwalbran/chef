require 'foodcritic'

task :default => [:foodcritic]
FoodCritic::Rake::LintTask.new do |t|
  t.files = "#{Dir.pwd}/cookbooks"
end
