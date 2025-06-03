# frozen_string_literal: true

require "base64"

module Riktoken
  class TiktokenFile
    class ParseError < StandardError; end

    # Parses a .tiktoken file content and returns a hash mapping base64-encoded tokens to their ranks.
    # @rbs content: String
    # @rbs return: Hash[String, Integer]
    def parse(content)
      ranks = {}

      content.each_line do |line|
        line = line.strip

        next if line.empty? || line.start_with?("#")

        parts = line.split(/\s+/)
        if parts.length != 2
          raise ParseError, "Invalid line format: #{line}"
        end

        begin
          token = Base64.strict_decode64(parts[0])
          rank = Integer(parts[1])
          ranks[token] = rank
        rescue ArgumentError => e
          raise ParseError, "Failed to parse line: #{line} - #{e.message}"
        end
      end

      ranks
    end

    def load(path)
      content = File.read(path, encoding: "UTF-8")
      parse(content)
    end
  end
end
