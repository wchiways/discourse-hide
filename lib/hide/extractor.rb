# frozen_string_literal: true

module Hide
  class Extractor
    HIDE_RAW_PATTERN = /\[hide\].*?\[\/hide\]/m

    def self.extract!(doc, post)
      hide_blocks = []
      index = 0

      doc.css("div.bbcode-hide-content").each do |node|
        hide_blocks << node.inner_html.strip
        placeholder = doc.document.create_element("div")
        placeholder["class"] = "bbcode-hide-placeholder"
        placeholder["data-hide-index"] = index.to_s
        placeholder.inner_html = "<p>回复后可见</p>"
        node.replace(placeholder)
        index += 1
      end

      if hide_blocks.any?
        post.custom_fields["hide_blocks"] = hide_blocks.to_json
        post.save_custom_fields(true)
      elsif post.custom_fields["hide_blocks"].present?
        post.custom_fields.delete("hide_blocks")
        post.save_custom_fields(true)
      end
    end
  end
end
