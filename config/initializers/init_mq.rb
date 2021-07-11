require 'mq'

MQ::ClientSingleton.start_connection
MQ::ClientSingleton.instance.declare_exchanges
MQ::ClientSingleton.instance.declare_queues
