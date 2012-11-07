#! /usr/bin/env ruby
require 'rake'
require "bundler/gem_tasks"

task :default => :test

task :test do
  sh 'rspec -Ilib spec/*.rb --color --format doc'
end
