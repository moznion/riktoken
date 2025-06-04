# frozen_string_literal: true

require_relative "riktoken/version"
require_relative "riktoken/encoding"
require_relative "riktoken/tiktoken_file"
require_relative "riktoken/encodings/cl100k_base"
require_relative "riktoken/encodings/p50k_base"
require_relative "riktoken/encodings/p50k_edit"
require_relative "riktoken/encodings/r50k_base"
require_relative "riktoken/encodings/o200k_base"

module Riktoken
  # @rbs!
  #   type rank = Integer
  #   type tuple[T, U] = [T, U]

  class UnknownEncodingError < StandardError; end

  class UnknownModelError < StandardError; end
  MODEL_TO_ENCODING = {
    # GPT-4 models
    "gpt-4" => "cl100k_base",
    "gpt-4-0314" => "cl100k_base",
    "gpt-4-0613" => "cl100k_base",
    "gpt-4-32k" => "cl100k_base",
    "gpt-4-32k-0314" => "cl100k_base",
    "gpt-4-32k-0613" => "cl100k_base",

    # GPT-3.5 models
    "gpt-3.5-turbo" => "cl100k_base",
    "gpt-3.5-turbo-0301" => "cl100k_base",
    "gpt-3.5-turbo-0613" => "cl100k_base",
    "gpt-3.5-turbo-16k" => "cl100k_base",
    "gpt-3.5-turbo-16k-0613" => "cl100k_base",

    # Legacy models
    "text-davinci-003" => "p50k_base",
    "text-davinci-002" => "p50k_base",
    "text-davinci-001" => "r50k_base",
    "text-curie-001" => "r50k_base",
    "text-babbage-001" => "r50k_base",
    "text-ada-001" => "r50k_base",
    "davinci" => "r50k_base",
    "curie" => "r50k_base",
    "babbage" => "r50k_base",
    "ada" => "r50k_base",

    # Code models
    "code-davinci-002" => "p50k_base",
    "code-davinci-001" => "p50k_base",
    "code-cushman-002" => "p50k_base",
    "code-cushman-001" => "p50k_base",
    "davinci-codex" => "p50k_base",
    "cushman-codex" => "p50k_base",

    # Edit models
    "text-davinci-edit-001" => "p50k_edit",
    "code-davinci-edit-001" => "p50k_edit",

    # Embeddings
    "text-embedding-ada-002" => "cl100k_base",

    # GPT-4o models
    "gpt-4o" => "o200k_base",
    "gpt-4o-mini" => "o200k_base"
  }.freeze
  DEFAULT_TIKTOKEN_BASE_DIR = File.join(Dir.home, ".riktoken").freeze
  TIKTOKEN_BASE_DIR_ENV_KEY = "TIKTOKEN_BASE_DIR"
  private_constant :MODEL_TO_ENCODING, :DEFAULT_TIKTOKEN_BASE_DIR, :TIKTOKEN_BASE_DIR_ENV_KEY

  class << self
    # Get the encoding by name (like "cl100k_base").
    # @rbs encoding_name: String
    # @rbs tiktoken_base_dir: String -- Base directory for tiktoken files
    # @rbs return: Encoding
    def get_encoding(encoding_name, tiktoken_base_dir: default_tiktoken_base_dir)
      enc_class = case encoding_name
      when "cl100k_base"
        Encodings::Cl100kBase
      when "p50k_base"
        Encodings::P50kBase
      when "p50k_edit"
        Encodings::P50kEdit
      when "r50k_base"
        Encodings::R50kBase
      when "o200k_base"
        Encodings::O200kBase
      else
        raise UnknownEncodingError, "Unknown encoding: #{encoding_name}"
      end

      enc_class.load_encoding(tiktoken_base_dir:)
    end

    # @rbs model_name: String -- Name of the model (e.g., "gpt-3.5-turbo")
    # @rbs tiktoken_base_dir: String -- Base directory for tiktoken files
    # @rbs return: Encoding
    def encoding_for_model(model_name, tiktoken_base_dir: default_tiktoken_base_dir)
      encoding_name = MODEL_TO_ENCODING[model_name]
      raise UnknownModelError, "Unknown model: #{model_name}" unless encoding_name

      get_encoding(encoding_name, tiktoken_base_dir:)
    end

    # @rbs name: String -- Name of the encoding
    # @rbs ranks: Hash[String, rank] -- Token to rank mapping
    # @rbs pattern: Regexp
    # @rbs special_tokens: Hash[String, rank]
    # @rbs return: Encoding
    def make_encoding(name:, ranks:, pattern:, special_tokens: {})
      Encoding.new(
        name:,
        ranks:,
        special_tokens:,
        pattern:
      )
    end

    # @rbs path: String -- Path to the .tiktoken file
    # @rbs name: String -- Name of the encoding
    # @rbs pattern: Regexp
    # @rbs special_tokens: Hash[String, rank]
    # @rbs return: Encoding
    def encoding_from_file(path:, name:, pattern:, special_tokens: {})
      parser = TiktokenFile.new
      ranks = parser.load(path)

      Encoding.new(
        name:,
        ranks:,
        special_tokens:,
        pattern:
      )
    end

    # @rbs return: Array[String]
    def list_encoding_names
      %w[cl100k_base p50k_base p50k_edit r50k_base o200k_base]
    end

    # @rbs return: Array[String]
    def list_model_names
      MODEL_TO_ENCODING.keys
    end
  end

  private

  class << self
    # @rbs return: String
    def default_tiktoken_base_dir
      ENV[TIKTOKEN_BASE_DIR_ENV_KEY] || DEFAULT_TIKTOKEN_BASE_DIR
    end
  end
end
