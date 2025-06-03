# frozen_string_literal: true

module Riktoken
  module Encodings
    class FileNotFoundError < StandardError; end

    def self.included(base)
      base.extend(ClassMethods)

      base.private_class_method :find_tiktoken_file
    end

    module ClassMethods
      # Look for .tiktoken file in common locations
      # @rbs name: String
      # @rbs base_dir: String -- a directory to find the tiktoken file
      # @rbs return: String
      def find_tiktoken_file(name:, base_dir:)
        path = File.join(base_dir, "#{name}.tiktoken")
        if File.exist?(path)
          path
        else
          raise FileNotFoundError, "tiktoken file not found: #{path}"
        end
      end
    end
  end
end
