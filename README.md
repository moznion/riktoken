# Riktoken

A pure Ruby partial implementation of OpenAI's tiktoken library for BPE (Byte Pair Encoding) tokenization. Riktoken enables you to encode and decode text using the same tokenizers as OpenAI's models like GPT-4, GPT-3.5, and others.

Most of the code is ported from [openai/tiktoken](https://github.com/openai/tiktoken).

## Features

- Pure Ruby implementation (no native dependencies) <= **this is one of the main motivations for this library**
- No any dependencies
- Compatible with OpenAI's tiktoken encodings (partial)
- Supports all major OpenAI model encodings (cl100k_base, o200k_base, p50k_base, etc.)
- Special token handling
- Model-to-encoding mapping

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'riktoken'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install riktoken
```

## Quick Start

### Setting Up .tiktoken Files

You have to download the official `.tiktoken` files from OpenAI and locate them to arbitrary directory in advance:

```bash
# Create base directory as you like (`~/.riktoken` is the default location)
mkdir -p ~/.riktoken

# Download encoding files
curl -o ~/.riktoken/cl100k_base.tiktoken \
  https://raw.githubusercontent.com/openai/tiktoken/main/tiktoken/assets/cl100k_base.tiktoken

curl -o ~/.riktoken/o200k_base.tiktoken \
  https://raw.githubusercontent.com/openai/tiktoken/main/tiktoken/assets/o200k_base.tiktoken

# Add other encodings as needed...
```

The library will search for `.tiktoken` files in the given directory as a parameter `tiktoken_base_dir` (default is `ENV[TIKTOKEN_BASE_DIR] || #{ENV['HOME']}/.riktoken/`).

**NOTE: If no `.tiktoken` file is found, the library will raise an error on loading; it does not fall back to built-in encodings and/or downloads the file automatically. i.e. the user must guarantee that the `.tiktoken` files are available in the specified directory.**

### Synopsis

```ruby
require 'riktoken'

# Get encoding by name
# You have to prepare `.tiktoken` files in the specified directory in advance.
encoding = Riktoken.get_encoding("cl100k_base", tiktoken_base_dir: "#{ENV['HOME']}/.riktoken")

# Or get encoding for a specific model
# Once `tiktoken_base_dir` is omitted, it will use the directory `ENV[TIKTOKEN_BASE_DIR] || #{ENV['HOME']}/.riktoken/` as default.
encoding = Riktoken.encoding_for_model("gpt-4")

# Encode text to tokens
tokens = encoding.encode("Hello, world!")
# => [9906, 11, 1917, 0]

# Decode tokens back to text
text = encoding.decode(tokens)
# => "Hello, world!"

# Count tokens
token_count = encoding.encode("Your text here").length
# => 3
```

## Supported Encodings

| Encoding | Models | tiktoken file name     |
|----------|--------|------------------------|
| `cl100k_base` | GPT-4, GPT-3.5-turbo, text-embedding-ada-002, text-embedding-3-small, text-embedding-3-large | `cl100k_base.tiktoken` |
| `o200k_base` | GPT-4o, GPT-4o-mini | `o200k_base.tiktoken` |
| `p50k_base` | text-davinci-003, text-davinci-002, code-davinci-002 | `p50k_base.tiktoken` |
| `p50k_edit` | text-davinci-edit-001, code-davinci-edit-001 | `p50k_base.tiktoken` |
| `r50k_base` | text-davinci-001, text-curie-001, text-babbage-001, text-ada-001 | `r50k_base.tiktoken` |

## Usage Examples

### Token Counting for API Cost Estimation

```ruby
encoding = Riktoken.encoding_for_model("gpt-4")
text = "Your prompt here..."
token_count = encoding.encode(text).length

# Estimate API cost (example rates)
input_cost_per_1k = 0.03  # $0.03 per 1K tokens
estimated_cost = (token_count / 1000.0) * input_cost_per_1k
puts "Token count: #{token_count}"
puts "Estimated cost: $#{'%.4f' % estimated_cost}"
```

### Handling Special Tokens

```ruby
encoding = Riktoken.get_encoding("cl100k_base")

# By default, special tokens raise an error
begin
  tokens = encoding.encode("Hello <|endoftext|> world")
rescue Riktoken::Encoding::DisallowedSpecialTokenError
  puts "Special tokens not allowed!"
end

# Allow specific special tokens
tokens = encoding.encode("Hello <|endoftext|> world", allowed_special: ["<|endoftext|>"])

# Allow all special tokens
tokens = encoding.encode("Hello <|endoftext|> world", allowed_special: "all")
```

### Splitting Text by Token Limit

```ruby
def split_by_tokens(text, max_tokens, encoding)
  tokens = encoding.encode(text)
  chunks = []

  tokens.each_slice(max_tokens) do |chunk|
    chunks << encoding.decode(chunk)
  end

  chunks
end

# Example: Split text into 100-token chunks
encoding = Riktoken.get_encoding("cl100k_base")
chunks = split_by_tokens("Your long text here...", 100, encoding)
```

### List Available Encodings and Models

```ruby
# List all available encodings
puts Riktoken.list_encoding_names
# => ["cl100k_base", "o200k_base", "p50k_base", "p50k_edit", "r50k_base"]

# List all supported models
puts Riktoken.list_model_names
# => ["gpt-4", "gpt-3.5-turbo", "text-davinci-003", ...]
```

## Advanced Usage

### Custom Encodings

```ruby
# Make a custom encoding
encoding = Riktoken.make_encoding(
  name: "my_custom_encoding",
  ranks: {"hello" => 0, "world" => 1},
  special_tokens: {"<|custom|>" => 100},
  pattern: /\w+/
)

tokens = encoding.encode('hello, world')
```

### Loading from Custom .tiktoken File

```ruby
encoding = Riktoken.encoding_from_file(
  path: "path/to/custom.tiktoken",
  name: "custom_encoding",
  special_tokens: {"<|special|>" => 50000},
  pattern: /'(?i:[sdmt]|ll|ve|re)|[^\r\n\p{L}\p{N}]?+\p{L}++|\p{N}{1,3}+| ?[^\s\p{L}\p{N}]++[\r\n]*+|\s++$|\s*[\r\n]|\s+(?!\S)|\s/
)
```

## Precedents

[IAPark/tiktoken_ruby](https://github.com/IAPark/tiktoken_ruby) is a Ruby port of OpenAI's tiktoken library uses native extensions.
This would be a good choice if you need a faster implementation with native performance.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/moznion/riktoken. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/moznion/riktoken/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

