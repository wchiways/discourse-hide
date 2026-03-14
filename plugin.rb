# frozen_string_literal: true

# name: discourse-hide
# about: Adds [hide]...[/hide] BBCode for reply-to-view content hiding
# version: 0.1.0
# authors: chiway
# url: https://github.com/wchiways/discourse-hide

enabled_site_setting :discourse_hide_enabled

register_asset "stylesheets/hide-bbcode.scss"

after_initialize do
  %w[
    lib/hide/extractor
    lib/hide/guardian_extension
    lib/hide/renderer
  ].each { |path| require_relative path }

  register_post_custom_field_type("hide_blocks", :string)

  Guardian.prepend(Hide::GuardianExtension)

  on(:post_process_cooked) do |doc, post|
    next unless post.present?
    Hide::Extractor.extract!(doc, post)
  end

  # Strip hide blocks from search indexing (both HTML and raw BBCode)
  register_modifier(:search_index_text) do |text, _obj|
    next text unless text
    text = text.gsub(Hide::Extractor::HIDE_RAW_PATTERN, "")
    fragment = Nokogiri::HTML::DocumentFragment.parse(text)
    fragment.css("div.bbcode-hide-content, div.bbcode-hide-placeholder").each(&:remove)
    fragment.to_html
  end

  add_to_serializer(:post, :cooked) do
    cooked = object.cooked
    if object.custom_fields["hide_blocks"].present?
      cooked = Hide::Renderer.inject!(cooked, object, scope)
    end
    cooked
  end

  # Ensure posts with hide blocks are not fragment-cached across users
  add_to_serializer(:post, :hide_has_blocks) do
    object.custom_fields["hide_blocks"].present?
  end
end
