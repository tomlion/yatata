class XmppBuilder
  JABBER_CLIENT_XMLNS = "jabber:client"
  PUBSUB_XMLNS = 'http://jabber.org/protocol/pubsub'
  PUBSUB_OWNER_XMLNS = 'http://jabber.org/protocol/pubsub#owner'
  DISCO_ITEMS_XMLNS = 'http://jabber.org/protocol/disco#items'
  DISCO_INFO_XMLNS = 'http://jabber.org/protocol/disco#info'
  JABBER_REGISTER_XMLNS = 'jabber:iq:register'
  JABBER_IQ_ROSTER_XMLNS = 'jabber:iq:roster'

  attr_accessor :client, :settings

  def initialize(client, settings)
    @client = client
    @settings = settings
  end

  def connection
    @client
  end

  def build_user_direct_message(update, opts)
    iq(:from => update.sender.xmpp_jid, :to => update.receiver.xmpp_jid,
       :type => "set") do |iq|
      iq.query(:xmlns => "urn:presently#direct_post") do |iq|
        add_payload(iq, update, opts)
      end
    end
  end

  def build_user_email(to, title, message, type)
    iq(:type => "set") do |iq|
      iq.query(:xmlns => "urn:presently#email") do |iq|
        iq.to(to)
        iq.title(title)
        iq.message(message)
        iq.type_(type)
      end
    end
  end

  def build_group_broadcast(update, opts)
    group = update.sender
    iq(:from => group.xmpp_jid, :to => "pubsub.#{@settings[:xmpp][:domain]}",
       :type => "set") do |iq|
      iq.pubsub(:xmlns => "http://jabber.org/protocol/pubsub") do |pubsub|
        pubsub.publish(:node => group.xmpp_node) do |publish|
          add_payload(publish, update, opts)
        end
      end
    end
  end

  def build_group_update(update, opts)
    iq(:from => update.sender.xmpp_jid, :to => "pubsub.#{@settings[:xmpp][:domain]}",
       :type => "set") do |iq|
      iq.pubsub(:xmlns => "http://jabber.org/protocol/pubsub") do |pubsub|
        pubsub.publish(:node => update.receiver.xmpp_node) do |publish|
          add_payload(publish, update, opts)
        end
      end
    end
  end

  def build_account_broadcast(update, opts)
    account = update.sender
    return build_user_direct_message(update, opts) if update.direct?
    pubsub(:from => account.xmpp_jid) do |pubsub|
      pubsub.publish(:node => "/home/#{@settings[:xmpp][:domain]}/#{account.subdomain.downcase}") do |publish|
        add_payload(publish, update, opts)
      end
    end
  end

  def build_account_copy_update(update, opts)
    user = update.sender
    pubsub(:from => user.xmpp_jid) do |pubsub|
      pubsub.publish(:node => "/home/#{@settings[:xmpp][:domain]}/#{user.account_subdomain.downcase}") do |publish|
        add_payload(publish, update, {:type => "copy"}.merge(opts))
      end
    end
  end

  def build_user_update(update, opts)
    doc = Nokogiri::XML::Builder.new(:encoding => "UTF-8")
    doc.iq(:from => update.sender.xmpp_jid, :type => "set", :to => update.sender.xmpp_jid) do |iq|
      iq.pubsub(:xmlns => "http://jabber.org/protocol/pubsub") do |pubsub|
        pubsub.publish(:node => "urn:xmpp:microblog") do |publish|
          add_payload(publish, update, opts)
        end
      end
    end
    # doc.to_xml
    doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
  end

  #"<iq from='xmpp_yong@localhost/288786991233292544195033' type='set' id='9796' to='pubsub.localhost'><pubsub xmlns='http://jabber.org/protocol/pubsub'><create node='/home/#{@settings[:xmpp][:domain]}/xmpp_yong/test_group'/><configure/></pubsub></iq>"
  def build_create_node_message(node_name)
    pubsub(:from => connection.jid) do |pubsub|
      pubsub.create(:node => node_name)
      pubsub.configure
    end
  end

  #<iq from='xmpp_yong@localhost/288786991233292544195033' type='set' id='10807' to='pubsub.localhost'><pubsub xmlns='http://jabber.org/protocol/pubsub'><subscribe node='/home/#{@settings[:xmpp][:domain]}/xmpp_yong/test_group' jid='xmpp_yong@localhost'/></pubsub></iq>
  def build_subscribe_message(node_name)
    pubsub(:from => connection.jid) do |pubsub|
      pubsub.subscribe(:node => node_name, :jid => connection.jid)
    end
  end

  def build_unsubscribe_message(node_name)
    pubsub(:from => connection.jid) do |pubsub|
      pubsub.unsubscribe(:node => node_name, :jid => connection.jid)
    end
  end

  #<iq type='set'
  # from='hamlet@denmark.lit/elsinore'
  # to='pubsub.shakespeare.lit'
  # id='delete1'>
  #<pubsub xmlns='http://jabber.org/protocol/pubsub#owner'>
  # <delete node='princely_musings'/>
  #</pubsub>
  #</iq>
  def build_delete_node_message(node_name)
    pubsub(:from => connection.jid, :xmlns => PUBSUB_OWNER_XMLNS) do |pubsub|
      pubsub.delete(:node => node_name)
    end
  end

  #<iq type='set'
  # from='hamlet@denmark.lit/elsinore'
  # to='pubsub.shakespeare.lit'
  # id='ent2'>
  #<pubsub xmlns='http://jabber.org/protocol/pubsub#owner'>
  # <affiliations node='princely_musings'>
  #   <affiliation jid='bard@shakespeare.lit' affiliation='publisher'/>
  # </affiliations>
  #</pubsub>
  #</iq>
  def build_set_affiliations_message(user_jid, node_name, role = 'publisher')
    pubsub(:xmlns => PUBSUB_OWNER_XMLNS, :from => connection.jid) do |pubsub|
      pubsub.affiliations(:node => node_name) do |aff|
        aff.affiliation(:jid => user_jid, :affiliation => role)
      end
    end
  end

  #<iq type='set' xmlns='jabber:client'><query xmlns='jabber:iq:roster'><item name='b' jid='a'/></query></iq>
  def build_roster_add_message(user_jid, other_jid)
    iq(:type => 'set', :xmlns => JABBER_CLIENT_XMLNS, :to => @settings[:xmpp][:domain],
       :from => user_jid, :id => generate_id) do |iq|
      iq.query(:xmlns => JABBER_IQ_ROSTER_XMLNS) do |query|
        query.item(:jid => other_jid)
      end
    end
  end

  def build_subscribe_presence_message(user_jid)
    presence(:to => user_jid, :type => "subscribe")
  end

  def build_subscribed_presence_message(user_jid)
    presence(:to => user_jid, :type => "subscribed")
  end

  def build_unsubscribe_presence_message(user_jid)
    presence(:to => user_jid, :type => "unsubscribe")
  end

  #<iq type='get'
  # from='francisco@denmark.lit/barracks'
  # to='pubsub.shakespeare.lit'
  # id='nodes1'>
  #<query xmlns='http://jabber.org/protocol/disco#items'/>
  #</iq>
  def build_discover_nodes_message(parent_node)
    query(:from => connection.jid, :to => "pubsub.#{@settings[:xmpp][:domain]}",
          :xmlns => DISCO_ITEMS_XMLNS, :node => parent_node)
  end

  #<iq type='get'
  # from='francisco@denmark.lit/barracks'
  # to='pubsub.shakespeare.lit'
  # id='info2'>
  #<query xmlns='http://jabber.org/protocol/disco#info'
  #      node='blogs'/>
  #</iq>
  def build_discover_node_info_message(node)
    query(:from => connection.jid, :to => "pubsub.#{@settings[:xmpp][:domain]}",
          :xmlns => DISCO_INFO_XMLNS, :node => node)
  end

  #<iq type='set' id='1477' to='localhost' xmlns='jabber:client'><query xmlns='jabber:iq:register'><username>strophe</username><password>strophe</password></query></iq>
  def build_register_message(password)
    user_name = connection.jid.split('@')[0]
    iq(:type => 'set', :xmlns => JABBER_CLIENT_XMLNS,
       :to => @settings[:xmpp][:domain], :id => generate_id) do |iq|
      iq.query(:xmlns => JABBER_REGISTER_XMLNS) do |q|
        q.username(user_name)
        q.password(password)
      end
    end
  end

  #<iq type='set' id='1129' to='localhost' xmlns='jabber:client'><query xmlns='jabber:iq:register'><remove/></query></iq>
  def build_unregister_message
    iq(:type => 'set', :xmlns => JABBER_CLIENT_XMLNS,
       :to => @settings[:xmpp][:domain], :id => generate_id) do |iq|
      iq.query(:xmlns => JABBER_REGISTER_XMLNS) do |q|
        q.remove()
      end
    end
  end

  def build_delete_user_message(user_jid)
    iq(:from => connection.jid, :id => generate_id, :to => "pubsub.#{@settings[:xmpp][:domain]}",
       :type => 'set', "xml:lang" => 'en') do |iq|
      iq.command(:xmlns => 'http://jabber.org/protocol/commands',
                 :node => 'http://jabber.org/protocol/admin#delete-user') do |c|
        c.x(:xmlns => 'jabber:x:data', :type => 'submit') do |x|
          x.field(:type => 'hidden', :var => "FORM_TYPE") do |f|
            f.value('http://jabber.org/protocol/admin')
          end
          x.field(:var => 'accountjids') do |f|
            f.value(user_jid)
          end
        end
      end
    end
  end

  def build_list_subscriptions
    iq(:type => 'get', :from => connection.jid, :to => "pubsub.#{@settings[:xmpp][:domain]}",
       :id => generate_id) do |iq|
      iq.pubsub(:xmlns => PUBSUB_XMLNS) do |p|
        p.subscriptions
      end
    end
  end

  def build_list_affiliations
    iq(:type => 'get', :from => connection.jid, :to => "pubsub.#{@settings[:xmpp][:domain]}",
       :id => generate_id) do |iq|
      iq.pubsub(:xmlns => PUBSUB_XMLNS) do |p|
        p.affiliations
      end
    end
  end

  def build_list_roster
    iq(:type => 'get', :id => generate_id, :to => @settings[:xmpp][:domain]) do |iq|
      iq.query(:xmlns => "jabber:iq:roster")
    end
  end


  private

  def generate_id
    Time.now.to_i.to_s
  end

  def queue(*strings)
    strings.each do |stanza|
      publish :xmpp_updates, stanza
    end
  end

  def pubsub(opts={}, &block)
    iq(:type => 'set', :id => generate_id, :from => opts.delete(:from),
       :to => "pubsub.#{@settings[:xmpp][:domain]}") do |iq|
      pubsub_opts = {:xmlns => opts.delete(:xmlns) || PUBSUB_XMLNS}

      if block_given?
        iq.pubsub(pubsub_opts){|pubsub| yield(pubsub) }
      else
        iq.pubsub(pubsub_opts)
      end
    end
  end

  def iq(opts={}, &block)
    doc = Nokogiri::XML::Builder.new(:encoding => "UTF-8")
    if block_given?
      doc.iq(opts) {|iq| yield(iq) }
    else
      doc.iq(opts)
    end
    doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
  end

  def query(opts={}, &block)
    iq(:type => opts.delete(:type) || 'get', :from => opts.delete(:from),
       :to => opts.delete(:to) || @settings[:xmpp][:domain]) do |iq|
      if block_given?
        iq.query(opts){|query| yield(query)}
      else
        iq.query(opts)
      end
    end
  end

  def presence(opts={}, &block)
    doc = Builder::XmlMarkup.new
    if block_given?
      doc.presence(opts) {|pres| yield(pres)}
    else
      doc.presence(opts)
    end
  end

  def add_payload(root, update, opts={})
    update.to_xmpp_payload(opts.merge(:root => root))
  end

end
