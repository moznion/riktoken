# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[test rubocop]

desc "Run tests with code coverage"
task :coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task["test"].invoke
end

namespace :rbs do
  task gen: %i[] do
    sh "rbs-inline --output --opt-out lib"
  end
end
