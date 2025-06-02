# frozen_string_literal: true

require_relative "bpe"

module Riktoken
  class Encoding
    class DisallowedSpecialTokenError < StandardError; end

    class InvalidTokenError < StandardError; end

    attr_reader :name

    def initialize(name:, ranks:, special_tokens: {}, pattern: nil)
      @name = name
      @ranks = ranks
      @special_tokens = special_tokens
      @pattern = pattern
      @special_tokens_regex = create_special_tokens_regex(special_tokens.keys)
      @bpe = BPE.new(encoder: ranks, regex: pattern, special_tokens_encoder: special_tokens)

      # Create reverse mappings
      @token_to_bytes = {}
      @bytes_to_token = {}

      ranks.each do |bytes_str, rank|
        @token_to_bytes[rank] = bytes_str
        @bytes_to_token[bytes_str] = rank
      end

      special_tokens.each do |token_str, token_id|
        @token_to_bytes[token_id] = token_str
        @bytes_to_token[token_str] = token_id
      end
    end

    def encode(text, allowed_special: Set.new, disallowed_special: "all")
      # Handle special tokens
      allowed_special = Set.new(@special_tokens.keys) if allowed_special == "all"
      allowed_special = Set.new(allowed_special) unless allowed_special.is_a?(Set)

      disallowed = if disallowed_special == "all"
        Set.new(@special_tokens.keys) - allowed_special
      else
        Set.new(disallowed_special) - allowed_special
      end

      # Check for disallowed special tokens
      if @special_tokens_regex && !disallowed.empty?
        found = text.scan(@special_tokens_regex).uniq
        found_disallowed = found & disallowed.to_a
        unless found_disallowed.empty?
          raise DisallowedSpecialTokenError,
            "Disallowed special token(s) found: #{found_disallowed.join(", ")}"
        end
      end

      # Split text by special tokens
      tokens = []

      if allowed_special.empty? || @special_tokens_regex.nil?
        # No special tokens to handle
        tokens = encode_ordinary(text)
      else
        # Split by allowed special tokens
        parts = text.split(@special_tokens_regex)
        matches = text.scan(@special_tokens_regex)

        parts.each_with_index do |part, i|
          unless part.empty?
            tokens.concat(encode_ordinary(part))
          end

          if i < matches.length && allowed_special.include?(matches[i])
            tokens << @special_tokens[matches[i]]
          end
        end
      end

      tokens
    end

    def decode(tokens)
      # Check for invalid tokens first
      tokens.each do |token|
        unless @token_to_bytes.key?(token) || token < 256
          raise InvalidTokenError, "Unknown token: #{token}"
        end
      end

      @bpe.decode(tokens)
    end

    def encode_ordinary(text)
      return [] if text.empty?

      # Use BPE to encode - it returns bytes directly
      @bpe.encode(text)[0] # TODO
    end

    def encode_with_unstable(text)
      tokens = encode(text)
      completions = []

      # For each token, decode all tokens up to that point
      (1..tokens.length).each do |i|
        partial_tokens = tokens[0...i]
        completions << decode(partial_tokens)
      end

      {tokens: tokens, completions: completions}
    end

    def token_byte_values
      @token_to_bytes.dup
    end

    private

    def create_special_tokens_regex(special_tokens)
      return nil if special_tokens.empty?

      # Escape special regex characters and join
      pattern = special_tokens
        .map { |token| Regexp.escape(token) }
        .join("|")

      Regexp.new(pattern)
    end
  end
end
