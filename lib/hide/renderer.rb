# frozen_string_literal: true

module Hide
  class Renderer
    def self.inject!(cooked_html, post, guardian)
      hide_blocks_json = post.custom_fields["hide_blocks"]
      return cooked_html unless hide_blocks_json.present?

      begin
        hide_blocks = JSON.parse(hide_blocks_json)
      rescue JSON::ParserError
        return cooked_html
      end
      return cooked_html if hide_blocks.empty?

      return cooked_html unless guardian.can_see_hide?(post)

      doc = Nokogiri::HTML::DocumentFragment.parse(cooked_html)

      doc.css("div.bbcode-hide-placeholder").each do |node|
        idx = node["data-hide-index"].to_i
        content = hide_blocks[idx]
        next unless content

        revealed = doc.document.create_element("div")
        revealed["class"] = "bbcode-hide-revealed"
        revealed["data-hide-index"] = idx.to_s
        revealed.inner_html = PrettyText.sanitize(content)
        node.replace(revealed)
      end

      doc.to_html
    end
  end
end
