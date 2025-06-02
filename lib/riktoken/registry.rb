# frozen_string_literal: true

require_relative "encoding"
require_relative "tiktoken_file"

module Riktoken
  class Registry
    class UnknownEncodingError < StandardError; end

    class UnknownModelError < StandardError; end

    @encodings = {}
    @model_to_encoding = {
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
    }

    class << self
      def get_encoding(encoding_name)
        # Load encoding if not already loaded
        unless @encodings.key?(encoding_name)
          load_encoding(encoding_name)
        end

        encoding = @encodings[encoding_name]
        raise UnknownEncodingError, "Unknown encoding: #{encoding_name}" unless encoding

        encoding
      end

      def encoding_for_model(model_name)
        encoding_name = @model_to_encoding[model_name]
        raise UnknownModelError, "Unknown model: #{model_name}" unless encoding_name

        get_encoding(encoding_name)
      end

      def list_encoding_names
        # List all available encodings
        %w[cl100k_base p50k_base p50k_edit r50k_base o200k_base]
      end

      def list_model_names
        @model_to_encoding.keys
      end

      def register_encoding(name:, ranks:, special_tokens: {}, pattern: nil)
        @encodings[name] = Encoding.new(
          name: name,
          ranks: ranks,
          special_tokens: special_tokens,
          pattern: pattern
        )
      end

      def unregister_encoding(name)
        @encodings.delete(name)
      end

      def encoding_from_file(path:, name:, special_tokens: {}, pattern: nil)
        parser = TiktokenFile.new
        ranks = parser.load(path)

        Encoding.new(
          name: name,
          ranks: ranks,
          special_tokens: special_tokens,
          pattern: pattern
        )
      end

      private

      def load_encoding(encoding_name)
        case encoding_name
        when "cl100k_base"
          load_cl100k_base
        when "p50k_base"
          load_p50k_base
        when "p50k_edit"
          load_p50k_edit
        when "r50k_base"
          load_r50k_base
        when "o200k_base"
          load_o200k_base
        else
          raise UnknownEncodingError, "Unknown encoding: #{encoding_name}"
        end
      end

      def load_cl100k_base
        # For now, create a simple encoding for testing
        # In production, this would load from a .tiktoken file
        require_relative "encodings/cl100k_base"
        Encodings::Cl100kBase.load_encoding(self)
      end

      def load_p50k_base
        # For now, create a simple encoding for testing
        require_relative "encodings/p50k_base"
        Encodings::P50kBase.load_encoding(self)
      end

      def load_p50k_edit
        # Similar to p50k_base but with edit-specific tokens
        require_relative "encodings/p50k_edit"
        Encodings::P50kEdit.load_encoding(self)
      end

      def load_r50k_base
        # Legacy encoding
        require_relative "encodings/r50k_base"
        Encodings::R50kBase.load_encoding(self)
      end

      def load_o200k_base
        # o200k_base encoding for larger models
        require_relative "encodings/o200k_base"
        Encodings::O200kBase.load_encoding(self)
      end
    end
  end

  # Module-level convenience methods
  def self.get_encoding(encoding_name)
    Registry.get_encoding(encoding_name)
  end

  def self.encoding_for_model(model_name)
    Registry.encoding_for_model(model_name)
  end

  def self.list_encoding_names
    Registry.list_encoding_names
  end

  def self.list_model_names
    Registry.list_model_names
  end

  def self.register_encoding(**kwargs)
    Registry.register_encoding(**kwargs)
  end

  def self.unregister_encoding(name)
    Registry.unregister_encoding(name)
  end

  def self.encoding_from_file(**kwargs)
    Registry.encoding_from_file(**kwargs)
  end
end
