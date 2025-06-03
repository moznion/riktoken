# frozen_string_literal: true

require_relative "../encodings"

module Riktoken
  module Encodings
    module P50kEdit
      include Riktoken::Encodings

      ENCODING_NAME = "p50k_edit"
      TIKTOKEN_SIGNATURE_NAME = "p50k_base"
      private_constant :ENCODING_NAME

      # @rbs tiktoken_base_dir: String -- the directory where tiktoken files are stored
      # @rbs return: Riktoken::Encoding
      def self.load_encoding(tiktoken_base_dir:)
        ranks = TiktokenFile.new.load(find_tiktoken_file(name: TIKTOKEN_SIGNATURE_NAME, base_dir: tiktoken_base_dir))
        special_tokens = {
          "<|endoftext|>" => 50256,
          "<|fim_prefix|>" => 50258,
          "<|fim_middle|>" => 50259,
          "<|fim_suffix|>" => 50260
        }
        pattern = /'(?:[sdmt]|ll|ve|re)| ?\p{L}++| ?\p{N}++| ?[^\s\p{L}\p{N}]++|\s++$|\s+(?!\S)|\s/

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
