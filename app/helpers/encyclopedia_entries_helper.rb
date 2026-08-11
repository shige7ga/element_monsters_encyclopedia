module EncyclopediaEntriesHelper
  # カード一覧で同じユーザーの推し登録を繰り返し検索しないよう、元素IDごとにキャッシュする。
  def encyclopedia_entry_for(illustration)
    return unless user_signed_in?

    @encyclopedia_entries_by_element_id ||= current_user.encyclopedia_entries.index_by(&:element_id)
    @encyclopedia_entries_by_element_id[illustration.element_id]
  end
end
