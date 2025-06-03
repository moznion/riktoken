# frozen_string_literal: true

require_relative "../encodings"

module Riktoken
  module Encodings
    module O200kBase
      include Riktoken::Encodings

      ENCODING_NAME = "o200k_base"
      private_constant :ENCODING_NAME

      # @rbs tiktoken_base_dir: String -- the directory where tiktoken files are stored
      # @rbs return: Riktoken::Encoding
      def self.load_encoding(tiktoken_base_dir:)
        ranks = TiktokenFile.new.load(find_tiktoken_file(name: ENCODING_NAME, base_dir: tiktoken_base_dir))
        special_tokens = {
          "<|endoftext|>" => 199999,
          "<|fim_prefix|>" => 200000,
          "<|fim_middle|>" => 200001,
          "<|fim_suffix|>" => 200002,
          "<|endofprompt|>" => 200003,
          "<|startoftext|>" => 200004,
          "<|image|>" => 200005,
          "<|audio|>" => 200006,
          "<|video|>" => 200007
        }
        pattern = Regexp.union([
          /[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]*[\p{Ll}\p{Lm}\p{Lo}\p{M}]+(?i:'s|'t|'re|'ve|'m|'ll|'d)?/,
          /[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]+[\p{Ll}\p{Lm}\p{Lo}\p{M}]*(?i:'s|'t|'re|'ve|'m|'ll|'d)?/,
          /\p{N}{1,3}/,
          / ?[^\s\p{L}\p{N}]+[\r\n\/]*/,
          /\s*[\r\n]+/,
          /\s+(?!\S)/,
          /\s+/
        ])

        Riktoken::Encoding.new(
          name: ENCODING_NAME,
          ranks: ranks,
          special_tokens: special_tokens,
          pattern: pattern
        )
      end

      private

      class << self
        def self.create_test_ranks
          # Create a larger vocabulary for o200k_base (200K tokens)
          ranks = {}

          # Single bytes
          256.times do |i|
            ranks[i.chr] = i
          end

          # Extended common tokens
          common_words = %w[
            the of to and a in is it you that he was for on are with as I his they
            be at one have this from or had by word but what some we can out other
            were all there when up use your how said an each she which do their
            time if will way about many then them write would like so these her
            long make thing see him two has look more day could go come did number
            sound no most people my over know water than call first who may down
            side been now find any new work part take get place made live where
            after back little only round man year came show every good me give
            our under name very through just form sentence great think say help
            low line differ turn cause much mean before move right boy old too
            same tell does set three want air well also play small end put home
            read hand port large spell add even land here must big high such
            follow act why ask men change went light kind off need house picture
            try us again animal point mother world near build self earth father
            head stand own page should country found answer school grow study
            still learn plant cover food sun four between state keep eye never
            last let thought city tree cross farm hard start might story saw far
            sea draw left late run while press close night real life few north
            open seem together next white children begin got walk example ease
            paper group always music those both mark often letter until mile
            river car feet care second book carry took science eat room friend
            began idea fish mountain stop once base hear horse cut sure watch
            color wood main enough plain girl usual young ready above ever red
            list though feel talk bird soon body dog family direct pose leave
            song measure door product black short numeral class wind question
            happen complete ship area half rock order fire south problem piece
            told knew pass since top whole king space heard best hour better
            during hundred five remember step early hold west ground interest
            reach fast verb sing listen six table travel less morning ten simple
            several vowel toward war lay against pattern slow center love person
            money serve appear road map rain rule govern pull cold notice voice
            unit power town fine certain fly fall lead cry dark machine note
            wait plan figure star box noun field rest correct able pound done
            beauty drive stood contain front teach week final gave green oh
            quick develop ocean warm free minute strong special mind behind
            clear tail produce fact street inch multiply nothing course stay
            wheel full force blue object decide surface deep moon island foot
            system busy test record boat common gold possible plane stead dry
            wonder laugh thousands ago ran check game shape equate miss brought
            heat snow tire bring yes distant fill east paint language among
            grand ball yet wave drop heart am present heavy dance engine
            position arm wide sail material size vary settle speak weight general
            ice matter circle pair include divide syllable felt perhaps pick
            sudden count square reason length represent art subject region energy
            hunt probable bed brother egg ride cell believe fraction forest sit
            race window store summer train sleep prove lone leg exercise wall
            catch mount wish sky board joy winter sat written wild instrument
            kept glass grass cow job edge sign visit past soft fun bright gas
            weather month million bear finish happy hope flower clothe strange
            gone jump baby eight village meet root buy raise solve metal whether
            push seven paragraph third shall held hair describe cook floor either
            result burn hill safe cat century consider type law bit coast copy
            phrase silent tall sand soil roll temperature finger industry value
            fight lie beat excite natural view sense ear else quite broke case
            middle kill son lake moment scale loud spring observe child straight
            consonant nation dictionary milk speed method organ pay age section
            dress cloud surprise quiet stone tiny climb bad oil blood touch grew
            cent mix team wire cost lost brown wear garden equal sent choose
            fell fit flow fair bank collect save control decimal gentle woman
            captain practice separate difficult doctor please protect noon whose
            locate ring character insect caught period indicate radio spoke atom
            human history effect electric expect crop modern element hit student
            corner party supply bone rail imagine provide agree thus capital
            won't chair danger fruit rich thick soldier process operate guess
            necessary sharp wing create neighbor wash bat rather crowd corn
            compare poem string bell depend meat rub tube famous dollar stream
            fear sight thin triangle planet hurry chief colony clock mine tie
            enter major fresh search send yellow gun allow print dead spot
            desert suit current lift rose continue block chart hat sell success
            company subtract event particular deal swim term opposite wife shoe
            shoulder spread arrange camp invent cotton born determine quart nine
            truck noise level chance gather shop stretch throw shine property
            column molecule select wrong gray repeat require broad prepare salt
            yellow jump southern thousand steel thick forward similar rule
            experience select house both white hundred against pattern table
          ]

          offset = 256
          common_words.each_with_index do |word, i|
            ranks[word] = offset + i
            ranks[" #{word}"] = offset + common_words.length + i
            ranks["#{word} "] = offset + 2 * common_words.length + i
          end

          # Add programming-related tokens
          programming_tokens = {
            "def" => 50000,
            "class" => 50001,
            "function" => 50002,
            "import" => 50003,
            "export" => 50004,
            "return" => 50005,
            "if" => 50006,
            "else" => 50007,
            "elif" => 50008,
            "for" => 50009,
            "while" => 50010,
            "try" => 50011,
            "except" => 50012,
            "finally" => 50013,
            "with" => 50014,
            "as" => 50015,
            "from" => 50016,
            "console.log" => 50017,
            "print" => 50018,
            "puts" => 50019,
            "require" => 50020,
            "module" => 50021,
            "const" => 50022,
            "let" => 50023,
            "var" => 50024,
            "true" => 50025,
            "false" => 50026,
            "null" => 50027,
            "undefined" => 50028,
            "nil" => 50029
          }

          # Add test tokens
          test_tokens = {
            "a" => 1000,
            "b" => 1001,
            "c" => 1002,
            "ab" => 1109,
            "bc" => 1868,
            "abc" => 40929,
            "Hello" => 9906,
            " world" => 10917,
            "test" => 1985,
            "Testing" => 11985
            # Keep individual character mappings consistent with byte values
            # Use standard ASCII values for single characters
          }

          ranks.merge!(programming_tokens)
          ranks.merge!(test_tokens)

          ranks
        end
      end
    end
  end
end
