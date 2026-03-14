# frozen_string_literal: true

module Hide
  class Extractor
    HIDE_PATTERN = /\[hide\](.*?)\[\/hide\]/m

    def self.extract!(cooked, post)
      hide_blocks = []
      index = 0

      processed = cooked.gsub(HIDE_PATTERN) do |_match|
        content = Regexp.last_match(1).strip
        hide_blocks << content
        placeholder = "<div class=\"bbcode-hide-placeholder\" data-hide-index=\"#{index}\"><p>回复后可见</p></div>"
        index += 1
        placeholder
      end

      if hide_blocks.any?
        post.custom_fields["hide_blocks"] = hide_blocks.to_json
        post.save_custom_fields(true)
      elsif post.custom_fields["hide_blocks"].present?
        post.custom_fields.delete("hide_blocks")
        post.save_custom_fields(true)
      end

      processed
    end
  end
end
