# this is a ultility class
# a Singleton instance of MQ::Client class
module MQ
  class ClientSingleton
    include Singleton
    extend Forwardable

    attr_reader :client

    def_delegators :@client, :start_connection, :declare_exchanges, :declare_queues, :publish, :subscribe

    def initialize
      config_file_path = "#{Rails.root}/config/rabbit_mq.yml"
      @configuration = Configuration.new(config_file_path)
      @client = Client.new(@configuration)
    end

    class << self
      def start_connection
        instance.start_connection
      end

      def declare_exchanges
        instance.declare_exchanges
      end

      def declare_queues
        instance.declare_queues
      end

      def publish(vhost, exchange, routing_key, msg, options={})
        instance.publish(vhost, exchange, routing_key, msg, options)
      end

      def subscribe(vhost, queue, options={}, &block)
        instance.subscribe(vhost, queue, options, &block)
      end
    end
  end
end
