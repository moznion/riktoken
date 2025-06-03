# frozen_string_literal: true

require_relative "../encodings"

module Riktoken
  module Encodings
    module O200kBase
      include Riktoken::Encodings

      ENCODING_NAME = "o200k_base"
      private_constant :ENCODING_NAME

      # @rbs tiktoken_base_dir: String -- the directory where tiktoken files are stored
      # @rbs return: Riktoken::Encoding
      def self.load_encoding(tiktoken_base_dir:)
        ranks = TiktokenFile.new.load(find_tiktoken_file(name: ENCODING_NAME, base_dir: tiktoken_base_dir))
        special_tokens = {
          "<|endoftext|>" => 199999,
          "<|fim_prefix|>" => 200000,
          "<|fim_middle|>" => 200001,
          "<|fim_suffix|>" => 200002,
          "<|endofprompt|>" => 200003,
          "<|startoftext|>" => 200004,
          "<|image|>" => 200005,
          "<|audio|>" => 200006,
          "<|video|>" => 200007
        }
        pattern = Regexp.union([
          /[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]*[\p{Ll}\p{Lm}\p{Lo}\p{M}]+(?i:'s|'t|'re|'ve|'m|'ll|'d)?/,
          /[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]+[\p{Ll}\p{Lm}\p{Lo}\p{M}]*(?i:'s|'t|'re|'ve|'m|'ll|'d)?/,
          /\p{N}{1,3}/,
          / ?[^\s\p{L}\p{N}]+[\r\n\/]*/,
          /\s*[\r\n]+/,
          /\s+(?!\S)/,
          /\s+/
        ])

        Riktoken::Encoding.new(
          name: ENCODING_NAME,
          ranks: ranks,
          special_tokens: special_tokens,
          pattern: pattern
        )
      end
    end
  end
end
