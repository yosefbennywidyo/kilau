module KilauTool
  # Splits a template body into text, expr ({{ }}) and tag ({% %}) tokens
  # (spec §4.2). Every delimiter opens and closes on one line, so each
  # token carries the line it came from. A line holding only one tag or
  # comment, plus whitespace, leaves no trace in the output: the way a
  # hand-written .html reads is the way the page renders.
  module TemplateLexer
    class Token
      attr_reader :kind, :text, :line

      def initialize(kind, text, line)
        @kind = kind
        @text = text
        @line = line
      end
    end

    OPENERS = ["{{", "{%", "{#"]
    CLOSERS = { "{{" => "}}", "{%" => "%}", "{#" => "#}" }
    KINDS = { "{{" => "expr", "{%" => "tag", "{#" => "comment" }

    # body: the template without its args line; first_line: the file line
    # body starts on (2).
    def self.tokenize(body, path, first_line)
      tokens = []
      lines = body.split("\n", -1)
      lines.each_with_index do |line, i|
        number = first_line + i
        pieces = line_pieces(line, path, number)
        standalone = standalone?(pieces)
        pieces.each do |piece|
          next if piece.kind == "comment"
          next if standalone && piece.kind == "text"
          push(tokens, piece)
        end
        push(tokens, Token.new("text", "\n", number)) unless standalone || i == lines.size - 1
      end
      tokens
    end

    def self.line_pieces(line, path, number)
      pieces = []
      pos = 0
      while pos < line.size
        start = next_opener(line, pos)
        if start.nil?
          pieces << Token.new("text", line[pos, line.size - pos], number)
          pos = line.size
        else
          pieces << Token.new("text", line[pos, start - pos], number) if start > pos
          opener = line[start, 2]
          closer = CLOSERS.fetch(opener)
          stop = line.index(closer, start + 2)
          raise ArgumentError, "#{path}:#{number}: #{opener} is not closed by #{closer} on the same line" if stop.nil?
          kind = KINDS.fetch(opener)
          inner = line[start + 2, stop - start - 2].strip
          raise ArgumentError, "#{path}:#{number}: empty #{opener} #{closer}" if inner.empty? && kind != "comment"
          pieces << Token.new(kind, inner, number)
          pos = stop + 2
        end
      end
      pieces
    end

    def self.next_opener(line, pos)
      best = nil
      OPENERS.each do |opener|
        found = line.index(opener, pos)
        best = found if !found.nil? && (best.nil? || found < best)
      end
      best
    end

    # Exactly one tag or comment, and nothing else but blanks.
    def self.standalone?(pieces)
      marks = pieces.count { |piece| piece.kind == "tag" || piece.kind == "comment" }
      others = pieces.count { |piece| piece.kind == "expr" || (piece.kind == "text" && !piece.text.strip.empty?) }
      marks == 1 && others == 0
    end

    # Adjacent text merges, keeping the line it started on.
    def self.push(tokens, token)
      last = tokens.last
      if token.kind == "text" && !last.nil? && last.kind == "text"
        tokens[tokens.size - 1] = Token.new("text", last.text + token.text, last.line)
      else
        tokens << token
      end
    end
  end
end
