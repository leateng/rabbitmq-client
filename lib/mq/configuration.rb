require 'forwardable'

module MQ
  # connections defined in project_root/config/rabbit_mq.yml
  # each vhost has one connection at least
  # for example
  # development:
  #   crm:
  #     connection:
  #       host: localhost
  #       port: 5672
  #       username: guest
  #       password: guest
  #       vhost: crm
  #     exchange:
  #       -
  #         name: alert
  #         type: direct
  #         options:
  #           durable: true
  #           auto_delete: false
  #       -
  #         name: notification
  #         type: direct
  #         options:
  #           durable: true
  #           auto_delete: false
  #     queue:
  #       -
  #         name: alert
  #         bind: alert
  #         routing_key: alert
  #         options:
  #           durable: true
  #           auto_delete: false
  #       -
  #         name: notification
  #         bind: notification
  #         routing_key: notification
  #         options:
  #           durable: true
  #           auto_delete: false
  class Configuration
    class ConfigurationFileMissing < StandardError; end
    class ConfigurationMissing < StandardError; end

    extend Forwardable

    # Map options that Bunny will recognize are
    # :host (string, default: "127.0.0.1")
    # :port (integer, default: 5672)
    # :user or :username (string, default: "guest")
    # :pass or :password (string, default: "guest")
    # :vhost or virtual_host (string, default: '/')
    # :heartbeat or :heartbeat_interval (string or integer, default: :server): standard RabbitMQ server heartbeat. 
    #   :server means "use the value from RabbitMQ config". 0 means no heartbeats (not recommended).
    # :logger (Logger): The logger. If missing, one is created using :log_file and :log_level.
    # :log_level (symbol or integer, default: Logger::WARN): Log level to use when creating a logger.
    # :log_file (string or IO, default: STDOUT): log file or IO object to use when creating a logger
    # :automatically_recover (boolean, default: true): when false, will disable automatic network failure recovery
    # :network_recovery_interval (number, default: 5.0): interval between reconnection attempts
    # :threaded (boolean, default: true): switches to single-threaded connections when set to false. Only recommended for apps that only publish messages.
    # :continuation_timeout (integer, default: 4000 ms): timeout for client operations that expect a response (e.g. Bunny::Queue#get), in milliseconds.
    # :frame_max (integer, default: 131072): maximum permissible size of a frame (in bytes) to negotiate with clients. 
    #   Setting to 0 means "unlimited" but will trigger a bug in some QPid clients.
    #   Setting a larger value may improve throughput; setting a smaller value may improve latency.
    # :auth_mechanism (string or array, default: "PLAIN"): Mechanism to authenticate with the server. Currently supporting "PLAIN" and "EXTERNAL".
    DEFAULT_CONNECTION_OPTIONS = {
      'host' => 'localhost',
      'port' => 5672,
      'username' => 'guest',
      'password' => 'guest',
      'vhost' => '/'
    }

    attr_reader :config_file_path, :configuration, :env_configuration

    def_delegators :@env_configuration, :size, :map, :each, :[], :to_s, :inspect

    def initialize(config_file_path)
      @config_file_path = config_file_path
      check_and_load_file
    end

    def check_and_load_file
      raise ConfigurationFileMissing, "Missing configuration file: #{config_file_path}" unless File.exist?(config_file_path)

      @configuration = YAML.load_file(config_file_path)
      @env_configuration = merge_with_default_options(@configuration[env])

      raise ConfigurationMissing, "Missing configuration for #{env} environment" if @env_configuration.blank?
    end

    def merge_with_default_options(options)
      options.each do |name, opt|
        options[name] = DEFAULT_CONNECTION_OPTIONS.merge(opt)
      end

      options
    end

    def env
      Rails.env.to_s
    end
  end
end
