# frozen_string_literal: true

require_relative "../encodings"

module Riktoken
  module Encodings
    module Cl100kBase
      include Riktoken::Encodings

      ENCODING_NAME = "cl100k_base"
      private_constant :ENCODING_NAME

      # @rbs tiktoken_base_dir: String -- the directory where tiktoken files are stored
      # @rbs return: Riktoken::Encoding
      def self.load_encoding(tiktoken_base_dir:)
        ranks = TiktokenFile.new.load(find_tiktoken_file(name: ENCODING_NAME, base_dir: tiktoken_base_dir))
        special_tokens = {
          "<|endoftext|>" => 100257,
          "<|fim_prefix|>" => 100258,
          "<|fim_middle|>" => 100259,
          "<|fim_suffix|>" => 100260,
          "<|endofprompt|>" => 100276
        }
        pattern = /'(?i:[sdmt]|ll|ve|re)|[^\r\n\p{L}\p{N}]?+\p{L}++|\p{N}{1,3}+| ?[^\s\p{L}\p{N}]++[\r\n]*+|\s++$|\s*[\r\n]|\s+(?!\S)|\s/

        Riktoken::Encoding.new(
          name: ENCODING_NAME,
          ranks: ranks,
          special_tokens: special_tokens,
          pattern: pattern
        )
      end

      private

      class << self
        def self.create_test_ranks
          # Create a simplified set of ranks for testing
          # In production, this would be loaded from a .tiktoken file
          ranks = {}

          # Single byte tokens (essential for basic character handling)
          256.times do |i|
            ranks[i.chr] = i
          end

          # Add common word tokens
          common_tokens = {
            "Hello" => 9906,
            " world" => 10917,
            "Hello world" => 15496,
            "test" => 1985,
            "Testing" => 11985,
            "UTF" => 22865,
            "世" => 19990,
            "界" => 30181
          }

          ranks.merge!(common_tokens)

          ranks
        end
      end
    end
  end
end
