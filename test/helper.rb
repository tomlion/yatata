class Yatata
  class Helper
    def self.is_subscribed?(node_name, jid, &block)
      subs = Blather::Stanza::PubSub::Subscriptions.new(:get, Yatata.settings['pubsub_url'])
      subs.from = jid

      subs.deliver_with_handler do |result|
        
      end
    end
    
    def self.subscribe(node_name, jid, &block)
      pubsub = Blather::Stanza::PubSub::Subscribe.new(:set, Yatata.settings['pubsub_url'], node_name, jid)
      pubsub.from = jid
      pubsub.deliver_with_handler do |result|
        if block_given?
          yield(node_name, result)
        elsif result.type == :result
          # set subscription config's pubsub#expire to presence
          cfg_stanza = Blather::Stanza::PubSub.new(:set, Yatata.settings['pubsub_url'])
          cfg_stanza.from = jid
          
          options = Blather::XMPPNode.new('options')
          options[:node] = node_name
          options[:jid] = jid
          
          x = Blather::Stanza::X.new(:submit, [
              {var: 'FORM_TYPE', type: 'hidden', value: 'http://jabber.org/protocol/pubsub#subscribe_options'},
              {var: 'pubsub#expire', value: 'presence'}
            ])
          cfg_stanza.pubsub << options << x
          cfg_stanza.deliver!
        end
      end
    end
    
    def self.unsubscribe(node_name, jid, subid)
      puts "unsubscribe #{node_name} #{jid} #{subid}"
      return if node_name.gsub(/.*?\//, '') == jid.gsub(/@.*/, '') # user must subscribe to himself, so ignore unsubscribe to himself command 

      pubsub = Blather::Stanza::PubSub::Unsubscribe.new(:set, Yatata.settings['pubsub_url'], node_name, jid, subid)
      pubsub.from = jid
      pubsub.deliver_with_handler do |result|
        p result
      end
    end

    def self.unsubscribe_all(jid)
      subs = Blather::Stanza::PubSub::Subscriptions.new(:get, Yatata.settings['pubsub_url'])
      subs.from = jid
      
      subs.deliver_with_handler do |result|
        result.list[:subscribed].each do |sub|
          unsubscribe(sub[:node], sub[:jid], sub[:subid])
        end unless result.list[:subscribed].blank?
      end
    end
    
    def self.list_subscriptions(jid)
      subs = Blather::Stanza::PubSub::Subscriptions.new(:get, Yatata.settings['pubsub_url'])
      subs.from = jid

      subs.deliver_with_handler do |result|
        hash = result.list
        subed = hash.delete(:subscribed)
        subed.each do |sub|
          puts "#{sub[:jid]}-->#{sub[:node]}\t\t#{sub[:subid]}"
        end unless subed.blank?
        puts hash unless hash.blank?
      end
    end
    
    def self.subs_notify(jid)
      subs = Blather::Stanza::PubSub::Subscriptions.new(:get, Yatata.settings['pubsub_url'])
      subs.from = jid
      
      subs.deliver_with_handler do |result|
        hash = result.list
        subed = hash.delete(:subscribed)
        unames = []
        subed.each do |sub|
          unames << sub[:node][9..-1]
        end unless subed.blank?
        
        if unames.present?
          msg = Blather::Stanza::Message.new(jid, unames.join(','), :normal)
          msg.subject = 'subscriptions'
          Yatata.deliver msg
        end
        
      end
    end
  end
end
