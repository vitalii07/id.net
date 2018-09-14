module FriendsHelper
  def select_options_for_pending_requests
    current_account.identities.map do |identity|
      ["#{identity.identity_title}(#{identity.pending_requests.count})", pending_friends_path(identity_id: identity)]
    end
  end

  def link_actions
    [ :write_message ] + case controller.action_name
    when 'index' # my friends
      [:unfollow, :block]
    when 'following' # my followees
      [ :unfollow ]
    when 'followers' # my followers
      [ :mutual_accept, :block ]
    when 'blocked' # my blocked
      [ :unblock ]
    when 'pending' # my pending requests
      [ :accept, :mutual_accept, :block ]
    end
  end

  def identity_links(id)
    user_identities[id][:associated].map do |i|
      identity_label(i)
    end.join(' ').html_safe
  end

  def identities_options(id, action)
    user_identities[id][action].map{|i| [i.identity_title, i.id] }
  end

  def identities_controls(identity)
    controls =
      case controller.action_name
      when 'index'
        [link_to_unfollow(identity), link_to_block(identity)]
      when 'following'
        [link_to_unfollow(identity)]
      when 'followers'
        [link_to_mutual_accept(identity), link_to_block(identity)]
      when 'blocked'
        [link_to_unblock(identity)]
      when 'pending'
        [link_to_mutual_accept(identity), link_to_accept(identity), link_to_block(identity)]
      end
    controls << link_to_write_message(identity)

    controls.join(' ').html_safe
  end

  # name: text of the link
  # type: method of identity. possible types are: pending|friends|followers|followees|blocked
  # options[:action]: overrides action detected from type
  def friends_tab(name, type, options={})
    action = options[:action] || type
    cls = (params[:action] == action.to_s) ? 'active' : ''

    identities = current_account.identities
    identities = identities.where(_id: params[:scope_id]) if params[:scope_id]
    count = identities.map {|i| i.send(type) }.flatten.uniq.count
    name = "#{name} (#{count})"

    content_tag "li", class: cls do
      link_to name, url_for(controller: 'friends', action: action, scope_id: params[:scope_id]), class: "v-nav-menu"
    end
  end
end
