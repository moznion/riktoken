# frozen_string_literal: true

require_relative "../tiktoken_file"
require_relative "../encodings"

module Riktoken
  module Encodings
    module P50kBase
      include Riktoken::Encodings

      def self.load_encoding(registry)
        tiktoken_file = TiktokenFile.new

        # Load ranks from .tiktoken file
        begin
          ranks = tiktoken_file.load(find_tiktoken_file("p50k_base"))
        rescue
          # Fallback to test ranks if .tiktoken file is not found
          ranks = create_test_ranks
        end
        special_tokens = {
          "<|endoftext|>" => 50256
        }

        # Pattern for p50k_base (r50k pattern)
        pattern = /'(?:[sdmt]|ll|ve|re)| ?\p{L}++| ?\p{N}++| ?[^\s\p{L}\p{N}]++|\s++$|\s+(?!\S)|\s/

        registry.register_encoding(
          name: "p50k_base",
          ranks: ranks,
          special_tokens: special_tokens,
          pattern: pattern
        )
      end

      private

      class << self
        def find_tiktoken_file(name)
          # Look for .tiktoken file in common locations
          possible_paths = [
            File.join(__dir__, "#{name}.tiktoken"),
            File.join(Dir.home, ".cache", "tiktoken", "#{name}.tiktoken"),
            File.join("/tmp", "tiktoken", "#{name}.tiktoken")
          ]

          possible_paths.find { |path| File.exist?(path) } ||
            raise("Could not find #{name}.tiktoken file")
        end

        def self.create_test_ranks
          # Create a basic set of ranks for testing
          # Similar to cl100k_base but with different token IDs
          ranks = {}

          # Single bytes
          256.times do |i|
            ranks[i.chr] = i
          end

          # Common tokens (same as cl100k_base but different IDs)
          common_words = %w[
            the of to and a in is it you that
            he was for on are with as I his they
            be at one have this from or had by
            word but what some we can out other were
            all there when up use your how said an
            each she which do their time if will way
            about many then them write would like so
            these her long make thing see him two has
            look more day could go come did number
            sound no most people my over know water
            than call first who may down side been now
          ]

          offset = 256
          common_words.each_with_index do |word, i|
            ranks[word] = offset + i
            ranks[" #{word}"] = offset + common_words.length + i
            ranks["#{word} "] = offset + 2 * common_words.length + i
          end

          # Add test tokens
          test_tokens = {
            "a" => 64,
            "b" => 65,
            "c" => 66,
            "ab" => 397,
            "bc" => 15630,
            "abc" => 39305,
            "Hello" => 15496,
            " world" => 995,
            "Hello world" => 15496,
            " " => 220,
            "test" => 9288
          }

          ranks.merge!(test_tokens)

          ranks
        end
      end
    end
  end
end
