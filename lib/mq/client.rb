module MQ
  class Client
    attr_reader :configuration, :connections, :channels, :exchanges, :queues

    def initialize(configuration)
      @channel_mutex = Mutex.new
      @configuration = configuration
      @connections = {}
      @channels = {}
      @exchanges = {}
      @queues = {}

      create_connections
    end

    def create_connections
      configuration.each do |name, cfg|
        @connections[name] = Bunny.new(cfg['connection'].transform_keys(&:to_sym))
      end
    end

    def start_connection
      connections.values.map(&:start)
    end

    def declare_exchanges
      configuration.each do |conn_name, cfg|
        @exchanges ||= {}
        @exchanges[conn_name] ||= {}

        conn = connections[conn_name]
        channels[conn_name] ||= conn.create_channel  
        ch = channels[conn_name]

        cfg['exchange'].to_a.each do |ex_cfg|
          ex = Bunny::Exchange.new(ch, ex_cfg['type'].to_sym, ex_cfg['name'], ex_cfg['options'].transform_keys(&:to_sym))
          @exchanges[conn_name][ex_cfg['name']] = ex
        end
      end
    end

    def declare_queues
      configuration.each do |conn_name, cfg|
        @queues ||= {}
        @queues[conn_name] ||= {}

        conn = connections[conn_name]
        channels[conn_name] ||= conn.create_channel  
        ch = channels[conn_name]

        cfg['queue'].to_a.each do |qu_cfg|
          ex = exchanges[conn_name][qu_cfg['bind']]
          qu = ch.queue(qu_cfg['name'], qu_cfg['options'].transform_keys(&:to_sym))
          qu.bind(qu_cfg['bind'], :routing_key => qu_cfg['routing_key'])
          @queues[conn_name][qu_cfg['name']] = qu
        end
      end
    end

    # def create_channels
    #   connections.each do |name, conn|
    #     channels[name] = conn.create_channel
    #   end
    # end

    def with_connection(vhost_name)
      conn = connections[vhost_name]
      raise "unknown vhost #{vhost_name}" if conn.blank?

      yield conn
    end

    def with_exchange(vhost_name, exchange_name)
      ex = exchanges[vhost_name][exchange_name]
      raise "unknown exchange #{vhost_name}/#{exchange_name}" if ex.blank?
      yield ex
    end

    def with_queue(vhost_name, queue_name)
      qu = queues[vhost_name][queue_name]
      raise "unknown queue #{vhost_name}/#{queue_name}" if qu.blank?
      yield qu
    end

    def publish(vhost_name, exchange_name, routing_key, message, opts = {})
      with_exchange(vhost_name, exchange_name) do |ex|
        @channel_mutex.synchronize do
          ex.publish(message, routing_key: routing_key, persistent: true)
        end
      end
    end

    # options
    #
    # {
    #   mannual_ack: true,
    #   block: true,
    # }
    def subscribe(vhost_name, queue_name, options={}, &block)
      default_options = {
        manual_ack: true,
        block: true
      }
      with_queue(vhost_name, queue_name) do |qu|
        qu.subscribe(default_options.merge(options.transform_keys(&:to_sym))) do |delivery_info, properties, content|
          block.call delivery_info, properties, content
        end
      end
    end
  end
end
