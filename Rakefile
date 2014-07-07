require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  tfs = FileList['test/unit/*.rb']
  t.test_files = tfs
  t.verbose = true
end

require 'coveralls/rake/task'
Coveralls::RakeTask.new

task test_with_coveralls: ['test', 'coveralls:push']
task default: [:build, :install]
