require 'rake/testtask'
require "bundler/gem_tasks"

task :default => :test


#
# TESTING

Rake::TestTask.new(:test) do |t|
  t.libs << "tests"
  t.test_files = FileList['tests/test.rb']
  t.verbose = true
end
