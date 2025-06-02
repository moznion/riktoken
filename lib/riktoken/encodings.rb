# frozen_string_literal: true

module Riktoken
  module Encodings
    def self.included(base)
      base.extend(ClassMethods)

      base.private_class_method :find_tiktoken_file
    end

    module ClassMethods
      # TODO TODO TODO
      # Look for .tiktoken file in common locations
      # @rbs name: String
      # @rbs return: String
      def find_tiktoken_file(name)
        possible_paths = [
          File.join(__dir__, "#{name}.tiktoken"),
          File.join(Dir.home, ".cache", "tiktoken", "#{name}.tiktoken"),
          File.join("/tmp", "tiktoken", "#{name}.tiktoken")
        ]

        possible_paths.find { |path| File.exist?(path) } || raise("Could not find #{name}.tiktoken file")
      end
    end
  end
end
