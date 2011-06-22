class XmppHelper

  class Exception < StandardError; end
  class ConnFailed < Exception; end

  class << self
    def debug=(need_debug)
    end

    def builder
      @builder if @builder
      @builder = XmppBuilder.new(XmppClient.settings)
    end

    def queue(*strings)
      return true if Rails.env == "test"
      strings.each do |stanza|
        publish :xmpp_updates, stanza
      end
    end

    def method_missing(method, *args, &block)
      if method.to_s =~ /^build_/
        builder.send(method, *args, &block)
      else
        super
      end
    end
    # -----------------------------
    # Update Management
    # -----------------------------

    def send_mail(to, title, message, type)
      queue(build_user_email(to, title, message, type))
    end

    def deliver_update(update)
      case update.sender
      when Group      then deliver_group_broadcast(update)
      when Account    then deliver_account_broadcast(update)
      when User       then deliver_user_update(update)
      end
      true
    end

    def deliver_group_broadcast(update, opts = {})
      queue(build_group_broadcast(update, opts))
    end

    def deliver_account_broadcast(update, opts = {})
      queue(build_account_broadcast(update, opts))
    end

    def deliver_user_update(update, opts = {})
      if update.group_message?
        queue(build_group_update(update, opts))
      elsif update.direct?
        queue(build_user_direct_message(update, opts))
      else
        # user updates are sent to the user's PEP node, and also to the account's
        # pubsub node (for the 'All Updates' stream)
        queue(build_user_update(update, opts))
        unless update.protected?
          queue(build_account_copy_update(update, opts))
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
      connect(jid, password) {|client|
        client.discover_nodes(parent_node)
      }
    end

    def discover_node_info(jid, password, node)
      connect(jid, password) { |client|
        client.discover_node_info(node)
      }
    end

    def create_pubsub(creator_jid, password, name)
      connect(creator_jid, password) do |client|
        client.create_pubsub_node(name) do
          client.subscribe_pubsub_node(name)
        end
      end
    end

    def delete_pubsub(creator_jid, password, name)
      connect(creator_jid, password) { |client|
        client.delete_pubsub_node(name)
      }
    end

    def subscribe_pubsub(creator_jid, password, user_jid, user_password, group_name)
      return false unless connect(creator_jid, password) { |client|
        # this is to allow user_jid publish to the node
        client.set_affiliations(user_jid, group_name)
      }

      connect(user_jid, user_password) { |client|
        client.subscribe_pubsub_node(group_name)
      }
    end

    def unsubscribe_pubsub(creator_jid, password, user_jid, user_password, group_name)
      return false unless connect(creator_jid, password) { |client|
        client.set_affiliations(user_jid, group_name, "none")
      }

      connect(user_jid, user_password) { |client|
        client.unsubscribe_pubsub_node(group_name)
      }
    end

    # -----------------------------
    # User Management
    # -----------------------------

    def create_user(user_jid, password)
      connect(user_jid, "", false) { |client|
        #create_user is special, it does not wait for an iq reply to send the resgister message
        client.register_user(password)
      }
    end

    #http://xmpp.org/rfcs/rfc3921.html#int
    def follow_user(user_jid, password, other_jids)
      connect(user_jid, password) { |client|
        other_jids.each { |other_jid|
          client.follow_user(other_jid)
        }
      }
    end

    def connect(jid, password)
      client = XmppClient.connect(jid, password)
      yield client
    end


  end
end
