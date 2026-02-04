# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

require "rubocop/rake_task"

RuboCop::RakeTask.new

desc "Run tests"
task :test do
  system("bin/test")
end

task default: %i[rubocop test]
