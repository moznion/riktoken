# frozen_string_literal: true

if ENV["COVERAGE"] || ENV["CI"]
  require "simplecov"

  SimpleCov.start do
    add_filter "/test/"
    add_filter "/vendor/"

    add_group "Library", "lib"
    add_group "Encodings", "lib/riktoken/encodings"

    track_files "lib/**/*.rb"

    enable_coverage :branch
  end
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "riktoken"

require "minitest/autorun"
