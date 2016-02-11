require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  tfs = FileList['test/unit/*.rb']
  t.test_files = tfs
  t.verbose = true
end

task default: [:build, :install]
