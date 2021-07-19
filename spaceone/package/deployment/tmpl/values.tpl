enabled: true

# Service
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

console-api:
    enabled: true

identity:
    enabled: true
    replicas: 1
    image:
      name: public.ecr.aws/megazone/spaceone/identity
      version: ${spaceone-version}

secret:
    enabled: true
    replicas: 1
    image:
      name: public.ecr.aws/megazone/spaceone/secret
      version: ${spaceone-version}
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
      name: public.ecr.aws/megazone/spaceone/repository
      version: ${spaceone-version}
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
      name: public.ecr.aws/megazone/spaceone/plugin
      version: ${spaceone-version}
 
    scheduler: true
    worker: true
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
      name: public.ecr.aws/megazone/spaceone/config
      version: ${spaceone-version}

inventory:
    enabled: true
    replicas: 1
    replicas_worker: 2
    image:
      name: public.ecr.aws/megazone/spaceone/inventory
      version: ${spaceone-version}
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
 
    volumeMounts:
        application_grpc: []
        application_scheduler: []
        application_worker: []

######################################
# if you want NLB for spacectl
# change ClusterIP to LoadBalancer
#####################################

#    service:
#      type: LoadBalancer
#      annotations:
#          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
#          external-dns.alpha.kubernetes.io/hostname: inventory.spaceone.dev
#      ports:
#        - name: grpc
#          port: 50051
#          targetPort: 50051
#          protocol: TCP
#


monitoring:
    enabled: true
    replicas: 1
    image:
      name: public.ecr.aws/megazone/spaceone/monitoring
      version: ${spaceone-version}

statistics:
    enabled: true
    replicas: 1
    image:
      name: public.ecr.aws/megazone/spaceone/statistics
      version: ${spaceone-version}
 
    scheduler: true
    worker: true
    application_scheduler:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

billing:
    enabled: false
    replicas: 1
    image:
      name: public.ecr.aws/megazone/spaceone/billing
      version: ${spaceone-version}

power-scheduler:
    enabled: false
    replicas: 1
    image:
      name: public.ecr.aws/megazone/spaceone/power-scheduler
      version: ${spaceone-version}
 
    scheduler: true
    worker: true
    application_scheduler:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

cost-saving:
    enabled: false
    scheduler: true
    worker: true
    replicas: 1
    image:
      name: public.ecr.aws/megazone/spaceone/cost-saving
      version: ${spaceone-version}

    application_grpc:
        CONNECTORS:
            ProductConnector:
                token: ___CHANGE_INVENTORY_MARKETPLACE_TOKEN___
                endpoint:
                    v1: grpc://inventory.portal.dev.spaceone.dev:50051


    application_scheduler:
        SCHEDULERS:
            cost_saving_scheduler:
                backend: spaceone.cost_saving.scheduler.cost_saving_scheduler.CostSavingScheduler
                queue: cost_saving_q
                interval: 3600
            CONNECTORS:
                ProductConnector:
                    token: ___CHANGE_INVENTORY_MARKETPLACE_TOKEN___
                    endpoint:
                        v1: grpc://inventory.portal.dev.spaceone.dev:50051

            TOKEN: ___CHANGE_YOUR_ROOT_TOKEN___ 

    application_worker:
        CONNECTORS:
            ProductConnector:
                token: ___CHANGE_INVENTORY_MARKETPLACE_TOKEN___
                endpoint:
                    v1: grpc://inventory.portal.dev.spaceone.dev:50051

    volumeMounts:
        application: []
        application_worker: []
        application_scheduler: []
        application_rest: []

spot-automation:
    enabled: false
    scheduler: true
    worker: true
    rest: true
    replicas: 1
    image:
      name: public.ecr.aws/megazone/spaceone/spot-automation
      version: ${spaceone-version}

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

    ingress:
        annotations:
            kubernetes.io/ingress.class: alb
            alb.ingress.kubernetes.io/scheme: internet-facing
            external-dns.alpha.kubernetes.io/hostname: spot-automation-proxy.dev.spaceone.dev


marketplace-assets:
    enabled: false


# include config/alb.yaml (for ALB)
# include config/nlb.yaml (for NLB)
supervisor:
    enabled: true
    image:
      name: public.ecr.aws/megazone/spaceone/supervisor
      version: ${spaceone-version}
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
                    inventory.Collector: 2
                    inventory.Collector?aws-ec2: 4
                    inventory.Collector?aws-cloud-services: 4
                    inventory.Collector?aws-power-state: 4
                    monitoring.DataSource: 2

        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server.spaceone.svc.cluster.local
            uri: root/api_key/TOKEN

ingress:
    enabled: false

spaceone-initializer:
    enabled: false
    image:
        version: 1.7.2

domain-initialzer:
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

#######################################
# TYPE 2. global variable (for mongodb cluster)
#######################################
#global:
#    namespace: spaceone
#    supervisor_namespace: root-supervisor
#    backend:
#        sidecar:
#            - name: mongos
#              image: mongo:4.4.0-bionic
#              command: [ 'mongos', '--config', '/mnt/mongos.yml', '--bind_ip_all' ]
#              volumeMounts:
#                - name: mongos-conf
#                  mountPath: /mnt/mongos.yml
#                  subPath: mongos.yml
#                  readOnly: true
#                - name: mongo-shard-key
#                  mountPath: /opt/mongos/mongo-shard.pem
#                  subPath: mongo-shard.pem
#                  readOnly: true
#        volumes:
#            - name: mongo-shard-key
#              secret:
#                  defaultMode: 0400
#                  secretName: mongo-shard-key
#            - name: mongos-conf
#              configMap:
#                  name: mongos-conf
