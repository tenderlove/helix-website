require 'kramdown'
require 'kramdown/parser'

module Kramdown
  module Parser
    class Extras < GFM
      FENCED_CODEBLOCK_PLUS_START = /^[ ]{0,3}[~`]{3,}\{?/
      FENCED_CODEBLOCK_PLUS_MATCH = /^[ ]{0,3}(([~`]){3,})(?:\{(\S+)\})?\s*?((\S+?)(?:\?\S*)?)?\s*?\n(.*?)^[ ]{0,3}\1\2*\s*?\n/m

      def initialize(*)
        super

        {:codeblock_fenced_gfm => :codeblock_fenced_gfm_plus}.each do |current, replacement|
          i = @block_parsers.index(current)
          @block_parsers.delete(current)
          @block_parsers.insert(i, replacement)
        end
      end

      define_parser(:codeblock_fenced_gfm_plus, FENCED_CODEBLOCK_PLUS_START, nil, 'parse_codeblock_fenced')

      def parse_codeblock_fenced
        if @src.check(self.class::FENCED_CODEBLOCK_PLUS_MATCH)
          start_line_number = @src.current_line_number
          @src.pos += @src.matched_size
          el = new_block_el(:codeblock, @src[6], nil, :location => start_line_number)

          if @src[3]
            el.attr['data-filename'] = @src[3]
          end

          lang = @src[4].to_s.strip
          unless lang.empty?
            el.options[:lang] = lang
            el.attr['class'] = "language-#{@src[5]}"
          end
          @tree.children << el
          true
        else
          false
        end
      end
    end
  end
end

module MarkdownHandler
  KRAMDOWN_OPTIONS = {
    input: 'Extras'
  }

  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template)
    compiled_source = erb.call(template)
    "Kramdown::Document.new(begin;#{compiled_source};end, ::MarkdownHandler::KRAMDOWN_OPTIONS).to_html"
  end
end

ActionView::Template.register_template_handler :md, MarkdownHandler