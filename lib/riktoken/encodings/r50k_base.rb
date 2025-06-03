# frozen_string_literal: true

require_relative "../encodings"

module Riktoken
  module Encodings
    module R50kBase
      include Riktoken::Encodings

      ENCODING_NAME = "r50k_base"
      private_constant :ENCODING_NAME

      # @rbs tiktoken_base_dir: String -- the directory where tiktoken files are stored
      # @rbs return: Riktoken::Encoding
      def self.load_encoding(tiktoken_base_dir:)
        ranks = TiktokenFile.new.load(find_tiktoken_file(name: ENCODING_NAME, base_dir: tiktoken_base_dir))
        special_tokens = {
          "<|endoftext|>" => 50256
        }
        pattern = /'(?:[sdmt]|ll|ve|re)| ?\p{L}++| ?\p{N}++| ?[^\s\p{L}\p{N}]++|\s++$|\s+(?!\S)|\s/

        Riktoken::Encoding.new(
          name: ENCODING_NAME,
          ranks: ranks,
          special_tokens: special_tokens,
          pattern: pattern
        )
      end

      private

      class << self
        def create_test_ranks
          # Create a basic set of ranks for testing
          # r50k_base is a legacy encoding similar to p50k_base but simpler
          ranks = {}

          # Single bytes
          256.times do |i|
            ranks[i.chr] = i
          end

          # Common tokens (simpler than p50k_base)
          common_words = %w[
            the of to and a in is it you that
            he was for on are with as I his they
            be at one have this from or had by
            word but what some we can out other
            were all there when up use your how
            said an each she which do their time
            if will way about many then them
            write would like so these her long
            make thing see him two has look more
          ]

          offset = 256
          common_words.each_with_index do |word, i|
            ranks[word] = offset + i
            ranks[" #{word}"] = offset + common_words.length + i
          end

          # Add test tokens
          test_tokens = {
            "a" => 97,
            "b" => 98,
            "c" => 99,
            "ab" => 397,
            "bc" => 15630,
            "abc" => 39305,
            "Hello" => 15496,
            " world" => 995,
            "test" => 9288
          }

          ranks.merge!(test_tokens)

          ranks
        end
      end
    end
  end
end
