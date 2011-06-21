class XmppHelper

  class Exception < StandardError; end
  class ConnFailed < Exception; end

  class << self
    def debug=(need_debug)
    end

    # -----------------------------
    # Update Management
    # -----------------------------

    def deliver_update(update)
      case update.sender
      when Group      then deliver_group_broadcast(update)
      when Account    then deliver_account_broadcast(update)
      when User       then deliver_user_update(update)
      end
      true
    end

    def deliver_group_broadcast(update, opts = {})
      XmppClient.new.send_group_broadcast(update, opts)
    end

    def deliver_account_broadcast(update, opts = {})
      XmppClient.new.send_account_broadcast(update, opts)
    end

    def deliver_user_update(update, opts = {})
      client = XmppClient.new
      if update.group_message?
        client.send_group_update(update, opts)
      elsif update.direct?
        client.send_direct_message(update, opts)
      else
        # user updates are sent to the user's PEP node, and also to the account's
        # pubsub node (for the 'All Updates' stream)
        client.send_user_update(update, opts)
        unless update.protected?
          client.send_account_copy_update(update, opts)
        end
      end
    end

    def deliver_like(like)
      update = like.update
      sender = update.sender
      case sender
      when Group      then deliver_group_broadcast(update, :type => 'like')
      when Account    then deliver_account_broadcast(update, :type => 'like')
      when User       then deliver_user_update(update, :type => 'like')
      end
    end

    def delete_update(update)
      case update.sender
      when Group      then deliver_group_broadcast(update, :type => 'delete')
      when Account    then deliver_account_broadcast(update, :type => 'delete')
      when User       then deliver_user_update(update, :type => 'delete')
      end
      true
    end

    # -----------------------------
    # Node Management
    # -----------------------------

    def discover_nodes(jid, password, parent_node)
      connect(jid, password) {|step, client|
        step.one { client.discover_nodes(parent_node) }
      }
    end

    def discover_node_info(jid, password, node)
      connect(jid, password) { |step, client|
        step.one { client.discover_node_info(node) }
      }
    end

    def create_pubsub(creator_jid, password, name)
      connect(creator_jid, password) do |step, client|
        step.one { client.create_pubsub_node(name) }
        step.two { client.subscribe_pubsub_node(name) }
      end
    end

    def delete_pubsub(creator_jid, password, name)
      connect(creator_jid, password) { |step, client|
        step.one { client.delete_pubsub_node(name) }
      }
    end

    def subscribe_pubsub(creator_jid, password, user_jid, user_password, group_name)
      return false unless connect(creator_jid, password) { |step, client|
        # this is to allow user_jid publish to the node
        step.one { client.set_affiliations(user_jid, group_name) }
      }

      connect(user_jid, user_password) { |step, client|
        step.one { client.subscribe_pubsub_node(group_name) }
      }
    end

    def unsubscribe_pubsub(creator_jid, password, user_jid, user_password, group_name)
      return false unless connect(creator_jid, password) { |step, client|
        step.one { client.set_affiliations(user_jid, group_name, "none") }
      }

      connect(user_jid, user_password) { |step, client|
        step.one { client.unsubscribe_pubsub_node(group_name) }
      }
    end

    # -----------------------------
    # User Management
    # -----------------------------

    def create_user(user_jid, password)
      connect(user_jid, "", false) { |step, client|
        #create_user is special, it does not wait for an iq reply to send the resgister message
        client.register_user(password)
      }
    end

    #http://xmpp.org/rfcs/rfc3921.html#int
    def follow_user(user_jid, password, other_jids)
      connect(user_jid, password) { |step, client|
        other_jids.each { |other_jid|
          step.one {
            client.follow_user(other_jid)
          }
        }
      }
    end


  end
end
