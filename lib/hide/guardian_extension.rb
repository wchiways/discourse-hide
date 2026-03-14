# frozen_string_literal: true

module Hide
  module GuardianExtension
    def can_see_hide?(post)
      return true if is_staff?
      return true if @user && @user.id == post.user_id
      return false unless @user

      @_can_see_hide_cache ||= {}
      cache_key = "#{post.topic_id}"

      return @_can_see_hide_cache[cache_key] if @_can_see_hide_cache.key?(cache_key)

      @_can_see_hide_cache[cache_key] = Post.where(
        topic_id: post.topic_id,
        user_id: @user.id,
        post_type: Post.types[:regular],
        hidden: false,
        user_deleted: false,
      ).where("post_number > 1")
       .where(deleted_at: nil)
       .exists?
    end
  end
end
