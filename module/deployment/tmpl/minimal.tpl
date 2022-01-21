enabled: true

mongodb:
    enabled: true
redis:
    enabled: true
consul:
    enabled: true
    server:
        replicas: 1
    ui:
        enabled: false
console:
  enabled: true
  developer: false
  name: console
  replicas: 1
  image:
      name: spaceone/console
      version: 1.9.0
  imagePullPolicy: IfNotPresent

  production_json:
      CONSOLE_API:
        ENDPOINT: http://console-api.example.com
      DOMAIN_NAME: spaceone
  service:
      type: LoadBalancer
      annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
          service.beta.kubernetes.io/aws-load-balancer-name: "spaceone-console-nlb"

console-api:
  enabled: true
  developer: false
  name: console-api
  replicas: 1
  image:
      name: spaceone/console-api
      version: 1.9.0
  imagePullPolicy: IfNotPresent

  production_json:
      cors:
      - http://*
      - https://*
      redis:
          host: redis
          port: 6379
          db: 15
      logger:
          handlers:
          - type: console
            level: debug
          - type: file
            level: info
            format: json
            path: "/var/log/spaceone/console-api.log"
      escalation:
        enabled: false
        allowedDomainId: domain_id
        apiKey: apikey
  service:
      type: LoadBalancer
      annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
          service.beta.kubernetes.io/aws-load-balancer-name: "spaceone-console-api-nlb"

identity:
    enabled: true
    replicas: 1
    image:
      name: spaceone/identity
      version: 1.9.0
    imagePullPolicy: Always

    application_grpc:
      HANDLERS:
          authentication:
          - backend: spaceone.core.handler.authentication_handler.AuthenticationGRPCHandler
            uri: grpc://localhost:50051/v1/Domain/get_public_key
          authorization:
          - backend: spaceone.core.handler.authorization_handler.AuthorizationGRPCHandler
            uri: grpc://localhost:50051/v1/Authorization/verify
          mutation:
          - backend: spaceone.core.handler.mutation_handler.SpaceONEMutationHandler

      ENDPOINTS:
      - service: identity
        name: Identity Service
        endpoint: grpc://identity:50051/v1
      - service: inventory
        name: Inventory Service
        endpoint: grpc://inventory:50051/v1
      - service: plugin
        name: Plugin Manager
        endpoint: grpc://plugin:50051/v1
      - service: repository
        name: Repository Service
        endpoint: grpc://repository:50051/v1
      - service: secret
        name: Secret Manager
        endpoint: grpc://secret:50051/v1
      - service: monitoring
        name: Monitoring Service
        endpoint: grpc://monitoring:50051/v1
      - service: config
        name: Config Service
        endpoint: grpc://config:50051/v1
      - service: power_scheduler
        name: Power Scheduler Service
        endpoint: grpc://power-scheduler:50051/v1
      - service: statistics
        name: Statistics Service
        endpoint: grpc://statistics:50051/v1
      - service: billing
        name: Billing Service
        endpoint: grpc://billing:50051/v1

secret:
    enabled: true
    replicas: 1
    image:
      name: spaceone/secret
      version: 1.9.0
    application_grpc:
        BACKEND: ConsulConnector
        CONNECTORS:
            ConsulConnector:
                host: spaceone-consul-server
                port: 8500
    volumeMounts:
        application_grpc: []
        application_scheduler: []
        application_worker: []

repository:
    enabled: true
    replicas: 1
    image:
      name: spaceone/repository
      version: 1.9.0
    application_grpc:
        ROOT_TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

plugin:
    enabled: true
    replicas: 1
    image:
      name: spaceone/plugin
      version: 1.9.0
 
    scheduler: false
    worker: false
    application_scheduler:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

config:
    enabled: true
    replicas: 1
    image:
      name: spaceone/config
      version: 1.9.0

inventory:
    enabled: true
    replicas: 1
    replicas_worker: 1
    image:
      name: spaceone/inventory
      version: 1.9.0
    scheduler: true
    worker: true
    application_grpc:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN
        collect_queue: collector_q

    application_scheduler:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN
    application_worker:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN
        HANDLERS:
          authentication: []
          authorization: []
          mutation: []

    volumeMounts:
        application_grpc: []
        application_scheduler: []
        application_worker: []

monitoring:
    enabled: true
    grpc: true
    scheduler: true
    worker: true
    rest: true
    replicas: 1
    replicas_rest: 1
    replicas_worker: 1
    image:
      name: spaceone/monitoring
      version: 1.9.0
    application_grpc:
      WEBHOOK_DOMAIN: https://monitoring-webhook.example.com
      TOKEN_INFO:
          protocol: consul
          config:
              host: spaceone-consul-server
          uri: root/api_key/TOKEN
      INSTALLED_DATA_SOURCE_PLUGINS:
        - name: AWS CloudWatch
          plugin_info:
            plugin_id: plugin-41782f6158bb
            provider: aws
        - name: Azure Monitor
          plugin_info:
            plugin_id: plugin-c6c14566298c
            provider: azure
        - name: Google Cloud Monitoring
          plugin_info:
            plugin_id: plugin-57773973639a
            provider: google_cloud

    application_rest:
      TOKEN_INFO:
          protocol: consul
          config:
              host: spaceone-consul-server
          uri: root/api_key/TOKEN

    application_scheduler:
      TOKEN_INFO:
          protocol: consul
          config:
              host: spaceone-consul-server
          uri: root/api_key/TOKEN

    application_worker:
      WEBHOOK_DOMAIN: https://monitoring-webhook.example.com
      TOKEN_INFO:
          protocol: consul
          config:
              host: spaceone-consul-server
          uri: root/api_key/TOKEN

    service:
        type: LoadBalancer
        annotations:
            service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
            service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
            service.beta.kubernetes.io/aws-load-balancer-name: "spaceone-monitoring-nlb"

statistics:
    enabled: true
    replicas: 1
    image:
      name: spaceone/statistics
      version: 1.9.0
 
    scheduler: false
    worker: false
    application_scheduler:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

billing:
    enabled: true
    replicas: 1
    image:
      name: spaceone/billing
      version: 1.9.0

notification:
    enabled: true
    replicas: 1
    image:
      name: public.ecr.aws/megazone/spaceone/notification
      version: 1.9.0 
    application_grpc:
        INSTALLED_PROTOCOL_PLUGINS:
          - name: Slack
            plugin_info:
              plugin_id: slack-notification-protocol
              options: {}
              schema: slack_webhook
          - name: Telegram
            plugin_info:
              plugin_id: plugin-telegram-noti-protocol
              options: {}
              schema: telegram_auth_token
          - name: Email
            plugin_info:
              plugin_id: plugin-email-noti-protocol
              options: {}
              secret_data:
                smtp_host: ${smpt_host}
                smtp_port: ${smpt_port}
                user: ${smpt_user}
                password: ${smpt_password}
              schema: email_smtp

power-scheduler:
    enabled: false
    replicas: 1
    image:
      name: spaceone/power-scheduler
      version: 1.9.0
 
    scheduler: true
    worker: true
    application_scheduler:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

cost-analysis:
    enabled: true
    scheduler: false
    worker: true
    replicas: 1
    replicas_worker: 2
    image:
      name: public.ecr.aws/megazone/spaceone/cost-analysis
      version: 1.9.0.1

    # Overwrite scheduler config
    application_scheduler:
        TOKEN: <root_token>

    application_grpc:
        DEFAULT_EXCHANGE_RATE:
            KRW: 1178.7
            JPY: 114.2
            CNY: 6.3

    application_worker:
        DEFAULT_EXCHANGE_RATE:
            KRW: 1178.7
            JPY: 114.2
            CNY: 6.3

    volumeMounts:
        application: []
        application_worker: []
        application_scheduler: []
        application_rest: []

    pod:
        spec: {}

spot-automation:
    enabled: false
    scheduler: true
    worker: true
    rest: true
    replicas: 1
    image:
      name: spaceone/spot-automation
      version: 1.9.0

# Overwrite application config
    application_grpc:
        CONNECTORS:
            ProductConnector:
                endpoint:
                    v1: grpc://inventory.portal.dev.spaceone.dev:50051 
                token: ___CHANGE_INVENTORY_MARKETPLACE_TOKEN___
        INTERRUPT:
            salt: ___CHANGE_SALT___
            endpoint: http://spot-automation-proxy.dev.spaceone.dev
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN


    # Overwrite scheduler config
    #application_scheduler: {}
    application_scheduler:
        TOKEN: ___CHANGE_YOUR_ROOT_TOKEN___

    # Overwrite worker config
    #application_worker: {}
    application_worker:
        QUEUES:
            spot_controller_q:
                backend: spaceone.core.queue.redis_queue.RedisQueue
                host: redis
                port: 6379
                channel: spot_controller
        CONNECTORS:
            ProductConnector:
                endpoint:
                    v1: grpc://inventory.portal.dev.spaceone.dev:50051 
                token: ___CHANGE_INVENTORY_MARKETPLACE_TOKEN___
        INTERRUPT:
            salt: ___CHANGE_SALT___
            endpoint: http://spot-automation-proxy.dev.spaceone.dev
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

marketplace-assets:
    enabled: false

supervisor:
    enabled: true
    image:
      name: spaceone/supervisor
      version: 1.9.0
    application: {}
    application_scheduler:
        NAME: root
        HOSTNAME: root-supervisor.svc.cluster.local
        BACKEND: KubernetesConnector
        CONNECTORS:
            RepositoryConnector:
                endpoint:
                    v1: grpc://repository.spaceone.svc.cluster.local:50051
            PluginConnector:
                endpoint:
                    v1: grpc://plugin.spaceone.svc.cluster.local:50051
            KubernetesConnector:
                namespace: root-supervisor
                start_port: 50051
                end_port: 50052
                headless: true
                replica:
                    inventory.Collector: 1
                    inventory.Collector?aws-ec2: 1
                    inventory.Collector?aws-cloud-services: 1
                    inventory.Collector?aws-power-state: 1
                    monitoring.DataSource: 1

        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server.spaceone.svc.cluster.local
            uri: root/api_key/TOKEN

ingress:
    enabled: false

#######################################
# TYPE 1. global variable (for docdb) 
#######################################
global:
    namespace: spaceone
    supervisor_namespace: root-supervisor
    backend:
        sidecar: []
        volumes: []
    frontend:
        sidecar: []
        volumes: []

    shared_conf:
        HANDLERS:
            authentication:
            - backend: spaceone.core.handler.authentication_handler.AuthenticationGRPCHandler
              uri: grpc://identity:50051/v1/Domain/get_public_key
            authorization:
            - backend: spaceone.core.handler.authorization_handler.AuthorizationGRPCHandler
              uri: grpc://identity:50051/v1/Authorization/verify
            mutation:
            - backend: spaceone.core.handler.mutation_handler.SpaceONEMutationHandler
        CONNECTORS:
            IdentityConnector:
                endpoint:
                    v1: grpc://identity:50051
            SecretConnector:
                endpoint:
                    v1: grpc://secret:50051
            RepositoryConnector:
                endpoint:
                    v1: grpc://repository:50051
            PluginConnector:
                endpoint:
                    v1: grpc://plugin:50051
            ConfigConnector:
                endpoint:
                    v1: grpc://config:50051
            InventoryConnector:
                endpoint:
                    v1: grpc://inventory:50051
            MonitoringConnector:
                endpoint:
                    v1: grpc://monitoring:50051
            StatisticsConnector:
                endpoint:
                    v1: grpc://statistics:50051
            BillingConnector:
                endpoint:
                    v1: grpc://billing:50051
            NotificationConnector:
                endpoint:
                    v1: grpc://notification:50051
            PowerSchedulerConnector:
                endpoint:
                    v1: grpc://power-scheduler:50051
        CACHES:
            default:
                backend: spaceone.core.cache.redis_cache.RedisCache
                host: redis
                port: 6379
                db: 0
                encoding: utf-8
                socket_timeout: 10
                socket_connect_timeout: 10