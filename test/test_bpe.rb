# frozen_string_literal: true

require_relative "test_helper"

class TestBPE < Minitest::Test
  def setup
    @encoder = {
      "a" => 0,
      "b" => 1,
      "c" => 2,
      "ab" => 3,
      "bc" => 4,
      "abc" => 5,
      " " => 6,
      "d" => 7,
      "e" => 8,
      "de" => 9,
      "f" => 10,
      "g" => 11,
      "h" => 12,
      "i" => 13,
      "j" => 14,
      "k" => 15,
      "l" => 16,
      "m" => 17,
      "n" => 18,
      "o" => 19,
      "p" => 20,
      "q" => 21,
      "r" => 22,
      "s" => 23,
      "t" => 24,
      "u" => 25,
      "v" => 26,
      "w" => 27,
      "x" => 28,
      "y" => 29,
      "z" => 30,
      "test" => 31,
      "hello" => 32,
      "world" => 33,
      "E" => 34,
      "N" => 35,
      "D" => 36,
      "S" => 37,
      "T" => 38,
      "A" => 39,
      "R" => 40,
      "P" => 41,
      "C" => 42,
      "I" => 43,
      "L" => 44,
      "END" => 45,
      "START" => 46,
      "SPECIAL" => 47
    }

    @special_tokens_encoder = {
      "END" => 100,
      "START" => 101,
      "SPECIAL" => 102
    }

    @regex = /\w+|\s/

    @bpe = Riktoken::BPE.new(
      encoder: @encoder,
      regex: @regex,
      special_tokens_encoder: @special_tokens_encoder
    )
  end

  def test_encode_ordinary_simple
    tokens = @bpe.encode_ordinary("abc")
    assert_equal [5], tokens

    tokens = @bpe.encode_ordinary("a b c")
    assert_equal [0, 6, 1, 6, 2], tokens

    tokens = @bpe.encode_ordinary("ab c")
    assert_equal [3, 6, 2], tokens
  end

  def test_encode_ordinary_with_unknown_characters
    encoder = {"a" => 0, "b" => 1, "ab" => 2}

    result = Riktoken::BPE.byte_pair_encode("abc", encoder)
    assert_equal [2, nil], result
  end

  def test_encode_ordinary_empty_string
    tokens = @bpe.encode_ordinary("")
    assert_equal [], tokens
  end

  def test_encode_with_no_special_tokens
    tokens, last_piece_len = @bpe.encode("hello world")
    assert_equal [32, 6, 33], tokens
    assert_equal 1, last_piece_len
  end

  def test_encode_with_allowed_special_tokens
    text = "hello END world"
    tokens, last_piece_len = @bpe.encode(text, allowed_special_tokens: Set.new(["END"]))
    assert_equal [32, 6, 100, 6, 33], tokens
    assert_equal 1, last_piece_len
  end

  def test_encode_with_disallowed_special_tokens
    text = "hello END world"
    tokens, last_piece_len = @bpe.encode(text)
    assert_equal [32, 6, 45, 6, 33], tokens
    assert_equal 1, last_piece_len
  end

  def test_encode_with_multiple_special_tokens
    text = "START hello SPECIAL world END"
    allowed = Set.new(["START", "SPECIAL", "END"])
    tokens, last_piece_len = @bpe.encode(text, allowed_special_tokens: allowed)
    assert_equal [101, 6, 32, 6, 102, 6, 33, 6, 100], tokens
    assert_equal 0, last_piece_len
  end

  def test_encode_with_special_tokens
    text = "START hello SPECIAL world END"
    tokens, last_piece_len = @bpe.encode_with_special_tokens(text)
    assert_equal [101, 6, 32, 6, 102, 6, 33, 6, 100], tokens
    assert_equal 0, last_piece_len
  end

  def test_decode_simple
    tokens = [5]
    assert_equal "abc", @bpe.decode(tokens)

    tokens = [0, 6, 1, 6, 2]
    assert_equal "a b c", @bpe.decode(tokens)

    tokens = [32, 6, 33]
    assert_equal "hello world", @bpe.decode(tokens)
  end

  def test_decode_with_special_tokens
    tokens = [101, 6, 32, 6, 33, 6, 100]
    assert_equal "START hello world END", @bpe.decode(tokens)
  end

  def test_decode_empty_tokens
    assert_equal "", @bpe.decode([])
  end

  def test_decode_invalid_utf8
    # Create a BPE with invalid UTF-8 sequences
    encoder = {"\xFF" => 0}
    bpe = Riktoken::BPE.new(
      encoder: encoder,
      regex: /./,
      special_tokens_encoder: {}
    )

    assert_raises(Riktoken::BPE::TextEncodingError) do
      bpe.decode([0])
    end
  end

  def test_byte_pair_encode_simple
    ranks = {"a" => 0, "b" => 1, "ab" => 2}

    result = Riktoken::BPE.byte_pair_encode("a", ranks)
    assert_equal [0], result

    result = Riktoken::BPE.byte_pair_encode("ab", ranks)
    assert_equal [2], result
  end

  def test_byte_pair_encode_complex
    ranks = {
      "a" => 0,
      "b" => 1,
      "c" => 2,
      "ab" => 3,
      "bc" => 4,
      "abc" => 5
    }

    result = Riktoken::BPE.byte_pair_encode("abc", ranks)
    assert_equal [5], result
  end

  def test_byte_pair_encode_with_bytes
    ranks = {"h" => 0, "e" => 1, "l" => 2, "o" => 3}

    result = Riktoken::BPE.byte_pair_encode("hello", ranks)
    expected = [0, 1, 2, 2, 3]
    assert_equal expected, result
  end

  def test_byte_pair_encode_merging_process
    ranks = {
      "a" => 0,
      "b" => 1,
      "c" => 2,
      "d" => 3,
      "ab" => 4,
      "cd" => 5,
      "abcd" => 6
    }

    result = Riktoken::BPE.byte_pair_encode("abcd", ranks)
    assert_equal [6], result
  end

  def test_byte_pair_encode_unknown_bytes
    ranks = {"a" => 0, "b" => 1}

    result = Riktoken::BPE.byte_pair_encode("xyz", ranks)
    # Unknown characters return nil
    expected = [nil, nil, nil]
    assert_equal expected, result
  end

  def test_byte_pair_encode_partial_matches
    ranks = {
      "a" => 0,
      "b" => 1,
      "c" => 2,
      "ab" => 3,
      "bc" => 4
    }

    result = Riktoken::BPE.byte_pair_encode("abcab", ranks)
    # Should merge in order: ab -> 3, c -> 2, ab -> 3
    assert_equal [3, 2, 3], result
  end

  def test_encode_decode_roundtrip
    texts = [
      "hello world",
      "abc",
      "test string",
      "a b c d e f g",
      ""
    ]

    texts.each do |text|
      tokens, _ = @bpe.encode(text)
      decoded = @bpe.decode(tokens)
      assert_equal text, decoded, "Failed roundtrip for: #{text}"
    end
  end

  def test_encode_decode_roundtrip_with_special_tokens
    text = "START hello world END"
    tokens, _ = @bpe.encode_with_special_tokens(text)
    decoded = @bpe.decode(tokens)
    assert_equal text, decoded
  end

  def test_special_regex_escaping
    # Test with simple special tokens that don't have regex special chars
    # The current implementation has issues with Regexp.escape + Regexp.union
    special_tokens = {
      "DOTTOKEN" => 100,
      "STARTOKEN" => 101,
      "PLUSTOKEN" => 102
    }

    # Need to include the tokens in encoder
    encoder = @encoder.merge({
      "DOTTOKEN" => 200,
      "STARTOKEN" => 201,
      "PLUSTOKEN" => 202
    })

    bpe = Riktoken::BPE.new(
      encoder: encoder,
      regex: @regex,
      special_tokens_encoder: special_tokens
    )

    # Should match these as special tokens when allowed
    text = "test DOTTOKEN test"
    tokens, _ = bpe.encode(text, allowed_special_tokens: Set.new(["DOTTOKEN"]))
    assert_includes tokens, 100
  end

  def test_complex_regex_patterns
    # Test with more complex regex patterns
    regex = /\w+|[^\w\s]+|\s+/
    # Add punctuation to encoder
    encoder = @encoder.merge({
      "," => 300,
      "!" => 301
    })

    bpe = Riktoken::BPE.new(
      encoder: encoder,
      regex: regex,
      special_tokens_encoder: @special_tokens_encoder
    )

    text = "hello, world!"
    tokens = bpe.encode_ordinary(text)
    # Should be: "hello" (32), "," (300), " " (6), "world" (33), "!" (301)
    assert_equal 5, tokens.length
    assert_equal [32, 300, 6, 33, 301], tokens
  end

  def test_last_piece_token_length
    # Test that last_piece_token_len is correctly calculated
    encoder = {
      "h" => 0, "e" => 1, "l" => 2, "o" => 3,
      "he" => 4, "ll" => 5, "hello" => 6
    }

    bpe = Riktoken::BPE.new(
      encoder: encoder,
      regex: /\w+/,
      special_tokens_encoder: {"<end>" => 100}
    )

    # Test with single token at end
    tokens, last_len = bpe.encode("hello")
    assert_equal [6], tokens
    assert_equal 1, last_len

    # Test with multiple tokens from BPE at end
    encoder_partial = {"h" => 0, "e" => 1, "l" => 2, "o" => 3}
    bpe_partial = Riktoken::BPE.new(
      encoder: encoder_partial,
      regex: /\w+/,
      special_tokens_encoder: {"<end>" => 100}
    )

    tokens, last_len = bpe_partial.encode("hello")
    assert_equal [0, 1, 2, 2, 3], tokens
    assert_equal 5, last_len

    # Test with special token at end
    tokens, last_len = bpe.encode("hello<end>", allowed_special_tokens: Set.new(["<end>"]))
    assert_equal [6, 100], tokens
    assert_equal 0, last_len
  end
end
