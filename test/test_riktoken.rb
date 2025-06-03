# frozen_string_literal: true

require_relative "test_helper"

class TestRiktoken < Minitest::Test
  # Sample texts to test encoding/decoding
  SIMPLE_TEXTS = [
    "Hello, world!",
    "This is a test of the tokenization system.",
    "Programming in Ruby is fun! 🚀",
    "特殊文字とUTF-8: こんにちは世界！",
    "Code example: def hello\n  puts 'Hello'\nend",
    "Numbers and symbols: 12345 !@#$%^&*()",
    "Long text: " + "word " * 20
  ].freeze

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

      SIMPLE_TEXTS.each do |text|
        tokens = encoding.encode(text)
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
