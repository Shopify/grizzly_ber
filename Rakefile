require "bundler/gem_tasks"
require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.ruby_opts << '-rubygems'
  t.libs << 'test'
  t.verbose = true
end
