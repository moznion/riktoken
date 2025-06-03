# frozen_string_literal: true

require_relative "test_helper"

class TestRiktoken < Minitest::Test
  # Sample texts to test encoding/decoding
  SIMPLE_TEXTS = {
    "Hello, world!" => {
      "o200k_base" => [13225, 11, 2375, 0],
      "cl100k_base" => [9906, 11, 1917, 0],
      "p50k_base" => [15496, 11, 995, 0],
      "p50k_edit" => [15496, 11, 995, 0],
      "r50k_base" => [15496, 11, 995, 0]
    },
    "This is a test of the tokenization system." => {
      "o200k_base" => [2500, 382, 261, 1746, 328, 290, 6602, 2860, 2420, 13],
      "cl100k_base" => [2028, 374, 264, 1296, 315, 279, 4037, 2065, 1887, 13],
      "p50k_base" => [1212, 318, 257, 1332, 286, 262, 11241, 1634, 1080, 13],
      "p50k_edit" => [1212, 318, 257, 1332, 286, 262, 11241, 1634, 1080, 13],
      "r50k_base" => [1212, 318, 257, 1332, 286, 262, 11241, 1634, 1080, 13]
    },
    "Programming in Ruby is fun! 🚀" => {
      "o200k_base" => [94925, 306, 56201, 382, 2827, 0, 169883, 222],
      "cl100k_base" => [46819, 304, 24658, 374, 2523, 0, 11410, 248, 222],
      "p50k_base" => [15167, 2229, 287, 10888, 318, 1257, 0, 12520, 248, 222],
      "p50k_edit" => [15167, 2229, 287, 10888, 318, 1257, 0, 12520, 248, 222],
      "r50k_base" => [15167, 2229, 287, 10888, 318, 1257, 0, 12520, 248, 222]
    },
    "特殊文字とUTF-8: こんにちは世界！" => {
      "o200k_base" => [153508, 79831, 5330, 16597, 12, 23, 25, 220, 95839, 28428, 3393],
      "cl100k_base" => [66378, 36149, 232, 88435, 19732, 8729, 12, 23, 25, 220, 90115, 3574, 244, 98220, 6447],
      "p50k_base" => [31965, 117, 162, 106, 232, 23877, 229, 27764, 245, 30201, 48504, 12, 23, 25, 23294, 241, 22174, 28618, 2515, 94, 31676, 10310, 244, 45911, 234, 171, 120, 223],
      "p50k_edit" => [31965, 117, 162, 106, 232, 23877, 229, 27764, 245, 30201, 48504, 12, 23, 25, 23294, 241, 22174, 28618, 2515, 94, 31676, 10310, 244, 45911, 234, 171, 120, 223],
      "r50k_base" => [31965, 117, 162, 106, 232, 23877, 229, 27764, 245, 30201, 48504, 12, 23, 25, 23294, 241, 22174, 28618, 2515, 94, 31676, 10310, 244, 45911, 234, 171, 120, 223]
    },
    "Code example: def hello\n  puts 'Hello'\nend" => {
      "o200k_base" => [2836, 4994, 25, 1056, 40617, 198, 220, 19237, 461, 13225, 2207, 419],
      "cl100k_base" => [2123, 3187, 25, 711, 24748, 198, 220, 9711, 364, 9906, 1270, 408],
      "p50k_base" => [10669, 1672, 25, 825, 23748, 198, 220, 7584, 705, 15496, 6, 198, 437],
      "p50k_edit" => [10669, 1672, 25, 825, 23748, 198, 220, 7584, 705, 15496, 6, 198, 437],
      "r50k_base" => [10669, 1672, 25, 825, 23748, 198, 220, 7584, 705, 15496, 6, 198, 437]
    },
    "Numbers and symbols: 12345 !@#$%^&*()" => {
      "o200k_base" => [31274, 326, 29502, 25, 220, 7633, 2548, 1073, 31, 108156, 108254, 5, 9, 416],
      "cl100k_base" => [28336, 323, 18210, 25, 220, 4513, 1774, 758, 31, 49177, 46999, 5, 9, 368],
      "p50k_base" => [49601, 290, 14354, 25, 17031, 2231, 5145, 31, 29953, 4, 61, 5, 9, 3419],
      "p50k_edit" => [49601, 290, 14354, 25, 17031, 2231, 5145, 31, 29953, 4, 61, 5, 9, 3419],
      "r50k_base" => [49601, 290, 14354, 25, 17031, 2231, 5145, 31, 29953, 4, 61, 5, 9, 3419]
    },
    "Long text: " + "word " * 20 => {
      "o200k_base" => [7930, 2201, 25, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 2195, 220],
      "cl100k_base" => [6720, 1495, 25, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 3492, 220],
      "p50k_base" => [14617, 2420, 25, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 220],
      "p50k_edit" => [14617, 2420, 25, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 220],
      "r50k_base" => [14617, 2420, 25, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 1573, 220]
    }
  }.freeze

  # Special token examples for each encoding
  SPECIAL_TOKEN_EXAMPLES = {
    "cl100k_base" => "Hello <|endoftext|> World <|fim_prefix|>code<|fim_suffix|>",
    "o200k_base" => "Start <|endoftext|> Middle <|startoftext|> End",
    "p50k_base" => "Simple text with <|endoftext|> marker",
    "p50k_edit" => "Edit mode <|endoftext|> with <|fim_prefix|>insert<|fim_suffix|>",
    "r50k_base" => "Legacy format with <|endoftext|> only"
  }.freeze

  # Test each encoding for basic encode/decode roundtrip
  %w[cl100k_base o200k_base p50k_base p50k_edit r50k_base].each do |encoding_name|
    define_method "test_#{encoding_name}_simple_text_roundtrip" do
      encoding = Riktoken.get_encoding(encoding_name, tiktoken_base_dir: File.join("test", "resources", "tiktoken"))

      SIMPLE_TEXTS.each do |text, expected_tokens|
        tokens = encoding.encode(text)
        assert_equal expected_tokens[encoding_name], tokens, "encoded tokens do not match for #{encoding_name}: #{text.inspect}"

        decoded = encoding.decode(tokens)
        assert_equal text, decoded,
          "Failed to roundtrip for #{encoding_name}: #{text.inspect}"

        # Ensure tokens are integers
        assert tokens.all? { |t| t.is_a?(Integer) },
          "Tokens should all be integers for #{encoding_name}: #{text.inspect}"

        # Ensure tokens are non-empty
        assert tokens.length > 0,
          "Token array should not be empty for #{encoding_name}: #{text.inspect}"
      end
    end

    define_method "test_#{encoding_name}_special_tokens_roundtrip" do
      special_text = SPECIAL_TOKEN_EXAMPLES[encoding_name]
      next unless special_text

      encoding = Riktoken.get_encoding(encoding_name, tiktoken_base_dir: File.join("test", "resources", "tiktoken"))

      # Test that special tokens raise error by default
      assert_raises(Riktoken::Encoding::DisallowedSpecialTokenError) do
        encoding.encode(special_text)
      end

      # Test with special tokens allowed
      tokens = encoding.encode(special_text, allowed_special: "all")
      decoded = encoding.decode(tokens)

      assert_equal special_text, decoded,
        "Failed to roundtrip special tokens for #{encoding_name}: #{special_text.inspect}"

      # Test with specific special tokens allowed
      special_tokens_in_text = special_text.scan(/<\|[^|>]+\|>/).uniq
      tokens_specific = encoding.encode(special_text, allowed_special: Set.new(special_tokens_in_text))
      decoded_specific = encoding.decode(tokens_specific)

      assert_equal special_text, decoded_specific,
        "Failed to roundtrip with specific special tokens for #{encoding_name}"
      assert_equal tokens, tokens_specific,
        "Token arrays should be identical when allowing all vs specific special tokens"
    end
  end

  # Test get_encoding and encoding_for_model
  def test_get_encoding
    encoding = Riktoken.get_encoding("cl100k_base", tiktoken_base_dir: File.join("test", "resources", "tiktoken"))
    assert_instance_of Riktoken::Encoding, encoding
    assert_equal "cl100k_base", encoding.name
  end

  def test_encoding_for_model
    encoding = Riktoken.encoding_for_model("gpt-4", tiktoken_base_dir: File.join("test", "resources", "tiktoken"))
    assert_instance_of Riktoken::Encoding, encoding
    assert_equal "cl100k_base", encoding.name

    # Test different models
    models_to_encodings = {
      "gpt-4" => "cl100k_base",
      "gpt-3.5-turbo" => "cl100k_base",
      "text-davinci-003" => "p50k_base",
      "text-davinci-edit-001" => "p50k_edit",
      "davinci" => "r50k_base"
    }

    models_to_encodings.each do |model, expected_encoding|
      encoding = Riktoken.encoding_for_model(model, tiktoken_base_dir: File.join("test", "resources", "tiktoken"))
      assert_equal expected_encoding, encoding.name,
        "Model #{model} should use #{expected_encoding} encoding"
    end
  end

  # Test unknown encoding and model
  def test_unknown_encoding
    assert_raises(Riktoken::UnknownEncodingError) do
      Riktoken.get_encoding("unknown_encoding")
    end
  end

  def test_unknown_model
    assert_raises(Riktoken::UnknownModelError) do
      Riktoken.encoding_for_model("unknown-model")
    end
  end

  # Test list methods
  def test_list_encoding_names
    names = Riktoken.list_encoding_names
    assert_instance_of Array, names
    assert names.include?("cl100k_base")
    assert names.include?("o200k_base")
    assert names.include?("p50k_base")
    assert names.include?("p50k_edit")
    assert names.include?("r50k_base")
  end

  def test_list_model_names
    names = Riktoken.list_model_names
    assert_instance_of Array, names
    assert names.include?("gpt-4")
    assert names.include?("gpt-3.5-turbo")
    assert names.include?("text-davinci-003")
  end
end
