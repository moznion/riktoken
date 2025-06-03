# frozen_string_literal: true

module Riktoken
  class BPE
    class TextEncodingError < StandardError; end

    attr_reader :encoder #: Hash[String, rank] -- parameter like parsed *.tiktoken file
    attr_reader :decoder  #: Hash[rank, String]
    attr_reader :special_tokens_encoder  #: Hash[String, rank]
    attr_reader :special_tokens_decoder  #: Hash[rank, String]
    attr_reader :regex  #: Regexp
    attr_reader :special_regex #: Regexp

    # @rbs encoder: Hash[String, rank]
    # @rbs regex: Regexp
    # @rbs special_tokens_encoder: Hash[String, rank]
    # @rbs return: BPE
    def initialize(encoder:, regex:, special_tokens_encoder:)
      @encoder = encoder
      @regex = regex
      @special_tokens_encoder = special_tokens_encoder
      @special_regex = Regexp.union(special_tokens_encoder.keys.map { |s| Regexp.escape(s) })
      @decoder = encoder.map { |k, v| [v, k] }.to_h
      @special_tokens_decoder = special_tokens_encoder.map { |k, v| [v, k] }.to_h
    end

    # @rbs return: Set[String]
    def special_tokens
      Set.new(@special_tokens_encoder.keys)
    end

    # Encode given text into tokens using the BPE encoding without considering special tokens.
    # @rbs text: String
    # @rbs return: Array[rank]
    def encode_ordinary(text)
      tokens = []
      text.scan(@regex) do |m|
        piece = m.is_a?(Array) ? m[0] : m
        encoded = @encoder[piece]
        if encoded
          tokens << encoded
        else
          tokens.concat(self.class.byte_pair_encode(piece, @encoder))
        end
      end
      tokens
    end

    # Encode given text into tokens using the BPE encoding, allowing for given special tokens.
    # @rbs text: String
    # @rbs allowed_special_tokens: Set[String]
    # @rbs return: tuple[Array[rank], Integer]
    def encode(text, allowed_special_tokens: Set.new)
      tokens = []
      start = 0
      last_piece_token_len = 0

      loop do
        next_special = nil
        start_find = start
        while start_find < text.bytesize
          m = @special_regex.match(text, start_find)
          if m.nil?
            break
          elsif allowed_special_tokens.include?(m[0])
            next_special = m
            break
          else
            start_find = m.begin(0) + 1
          end
        end

        end_pos = next_special ? next_special.begin(0) : text.bytesize

        segment = text[start...end_pos]
        segment.scan(@regex) do |m|
          piece = m.is_a?(Array) ? m[0] : m
          if @encoder.key?(piece)
            last_piece_token_len = 1
            tokens << @encoder[piece]
          else
            bpe_tokens = self.class.byte_pair_encode(piece, @encoder)
            last_piece_token_len = bpe_tokens.size
            tokens.concat(bpe_tokens)
          end
        end

        break unless next_special

        piece = next_special[0]
        token = @special_tokens_encoder[piece]
        tokens << token
        start = next_special.end(0)
        last_piece_token_len = 0
      end

      [tokens, last_piece_token_len]
    end

    # Encode given text into tokens using the BPE encoding, allowing for all special tokens.
    # @rbs text: String
    # @rbs return: tuple[Array[rank], Integer]
    def encode_with_special_tokens(text)
      encode(text, allowed_special_tokens: special_tokens)
    end

    # Decode given tokens back into text encoded as UTF-8.
    # @rbs tokens: Array[rank]
    # @rbs return: String
    def decode(tokens)
      return "" if tokens.empty?
      encoded = tokens.map { |t| @decoder[t] || @special_tokens_decoder[t] }.join.force_encoding("UTF-8")
      if encoded.valid_encoding?
        encoded
      else
        raise TextEncodingError, "failed to apply the text encoding to decoded tokens as valid UTF-8"
      end
    end

    # @rbs piece: String
    # @rbs ranks: Hash[String, rank]
    # @rbs return: Array[rank]
    def self.byte_pair_encode(piece, ranks)
      return [ranks[piece]] if ranks[piece]

      chars = piece.bytes.map(&:chr)

      loop do
        # Find the pair with the smallest rank among all adjacent pairs in ranks
        min_rank = nil
        min_pair_pos = nil
        (0...chars.size - 1).each do |i|
          pair = chars[i] + chars[i + 1]
          if ranks.key?(pair) && (min_rank.nil? || ranks[pair] < min_rank)
            min_rank = ranks[pair]
            min_pair_pos = i
          end
        end
        break unless min_pair_pos

        # merge: `min_pair_pos` and `min_pair_pos+1`
        chars = chars[0...min_pair_pos] + [chars[min_pair_pos] + chars[min_pair_pos + 1]] + chars[(min_pair_pos + 2)..]
        # after merging, it attempts re-searching from the start to maximize the merging unit
      end

      chars.map { |c| ranks[c] }
    end
  end
end
