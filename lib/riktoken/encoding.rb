# frozen_string_literal: true

require_relative "bpe"

module Riktoken
  class Encoding
    class DisallowedSpecialTokenError < StandardError; end

    class InvalidTokenError < StandardError; end

    attr_reader :name

    # @rbs @special_tokens: Hash[String, rank]
    # @rbs @bpe: BPE

    # @rbs name: String
    # @rbs ranks: Hash[String, rank]
    # @rbs special_tokens: Hash[String, rank]
    # @rbs pattern: Regexp
    # @rbs return: Encoding
    def initialize(name:, ranks:, pattern:, special_tokens: {})
      @name = name
      @special_tokens = special_tokens
      @bpe = BPE.new(encoder: ranks, regex: pattern, special_tokens_encoder: special_tokens)
    end

    # @rbs text: String
    # @rbs allowed_special: Set[String]|"all"
    # @rbs disallowed_special: Set[String]|"all"
    # @rbs return: Array[rank]
    def encode(text, allowed_special: Set.new, disallowed_special: "all")
      allowed_special = Set.new(@special_tokens.keys) if allowed_special == "all"
      disallowed_special = Set.new(@special_tokens.keys) - allowed_special if disallowed_special == "all"

      unless disallowed_special.empty?
        found = text.scan(Regexp.union(disallowed_special.to_a)).uniq
        found_disallowed = found & disallowed_special.to_a
        unless found_disallowed.empty?
          raise DisallowedSpecialTokenError, "Disallowed special token(s) found: #{found_disallowed.join(", ")}"
        end
      end

      @bpe.encode(text, allowed_special_tokens: allowed_special)[0]
    end

    # @rbs tokens: Array[rank]
    # @rbs return: String
    def decode(tokens)
      @bpe.decode(tokens)
    end
  end
end
