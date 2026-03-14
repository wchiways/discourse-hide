# frozen_string_literal: true

# name: discourse-hide
# about: Adds [hide]...[/hide] BBCode for reply-to-view content hiding
# version: 0.1.0
# authors: chiway
# url: https://github.com/chiway/discourse-hide

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
    cooked = doc.to_html
    processed = Hide::Extractor.extract!(cooked, post)
    if processed != cooked
      doc.inner_html = Nokogiri::HTML::DocumentFragment.parse(processed).to_html
    end
  end

  # Strip [hide]...[/hide] from raw text used in search indexing
  register_modifier(:search_index_text) do |text, _obj|
    text&.gsub(Hide::Extractor::HIDE_PATTERN, "")
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
