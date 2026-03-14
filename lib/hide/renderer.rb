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

      processed = cooked_html.dup
      hide_blocks.each_with_index do |content, index|
        placeholder = "<div class=\"bbcode-hide-placeholder\" data-hide-index=\"#{index}\"><p>回复后可见</p></div>"
        sanitized = PrettyText.sanitize(content)
        revealed = "<div class=\"bbcode-hide-revealed\" data-hide-index=\"#{index}\">#{sanitized}</div>"
        processed.gsub!(placeholder, revealed)
      end

      processed
    end
  end
end
