require 'hashie'

class XmppClient
  DEFAULT_TIMEOUT_IN_MILLISECONDS = 5000

  attr_reader :client

  def initialize(jid, password, host = nil, port = nil)
    @client = Yatata::Client.setup jid, password, host, port
  end

  class << self

    def settings
      @settings if @settings
      setting_yaml = File.expand_path("../../../settings.yml", __FILE__)
      @settings = Hashie::Mash.new(YAML.load(File.read(setting_yaml)))
    end

    def connect(jid, password, host = nil, port = nil)
      self.new(jid, password, host, port).client.run
    end

  end


  def method_missing(method, *args, &block)
    if method.to_s =~ /build_/
      builder.send(method, *args, &block)
    end
  end

  def discover_nodes(parent_node)
    deliver(build_discover_nodes_message(parent_node))
  end

  def discover_node_info(node)
    deliver(build_discover_node_info_message(node))
  end

  def create_pubsub_node(node)
    deliver(build_create_node_message("/home/#{settings[:xmpp][:domain]}/#{node.downcase}"))
  end

  def subscribe_pubsub_node(node)
    deliver(build_subscribe_message("/home/#{settings[:xmpp][:domain]}/#{node.downcase}"))
  end

  def delete_pubsub_node(node)
    deliver(build_delete_node_message("/home/#{settings[:xmpp][:domain]}/#{node.downcase}"))
  end

  def set_affiliations(user_jid, node, role = "publisher")
    deliver(build_set_affiliations_message(user_jid, "/home/#{settings[:xmpp][:domain]}/#{node.downcase}", role))
  end

  def unsubscribe_pubsub_node(node)
    deliver(build_unsubscribe_message("/home/#{settings[:xmpp][:domain]}/#{node.downcase}"))
  end

  # --------------------
  # User Management
  # --------------------

  def register_user(password)
    deliver(build_register_message(password))
  end

  def delete_user
    deliver(build_unregister_message)
  end

  def delete_user_by_admin(user_jid)
    deliver(build_delete_user_message(user_jid))
  end

  #http://xmpp.org/rfcs/rfc3921.html#int
  def follow_user(user_jid)
    deliver(build_subscribe_presence_message(user_jid))
  end

  def unfollow_user(user_jid)
    deliver(build_unsubscribe_presence_message(user_jid))
  end

  def list_subscriptions
    deliver(build_list_subscriptions)
  end

  def list_affiliations
    deliver(build_list_affiliations)
  end

  def list_roster
    deliver(build_list_roster)
  end

  # --------------------
  # Update Management
  # --------------------

  def send_mail(to, title, message, type)
    queue(build_user_email(to, title, message, type))
  end

  def send_direct_message(update, opts = {})
    queue(build_user_direct_message(update, opts))
  end

  def send_user_update(update, opts = {})
    queue(build_user_update(update, opts))
  end

  def send_group_broadcast(update, opts = {})
    queue(build_group_broadcast(update, opts))
  end

  def send_group_update(update, opts = {})
    queue(build_group_update(update, opts))
  end

  def send_account_broadcast(update, opts = {})
    queue(build_account_broadcast(update, opts))
  end

  def send_account_copy_update(update, opts = {})
    queue(build_account_copy_update(update, opts))
  end


  private

  def settings
    XmppClient.settings
  end

  def deliver stnz
    @client.deliver stnz
  end

  def builder
    @builder if @builder
    @builder = XmppBuilder.new(@client, settings)
  end

end

