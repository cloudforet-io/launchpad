console:
  enabled: true
  developer: false
  name: console
  replicas: 2
  image:
      name: public.ecr.aws/megazone/spaceone/console
      version: 1.10.0.5
  imagePullPolicy: IfNotPresent

  # For production.json (nodejs)
  # Domain name of console-api (usually ALB of console-api)
#######################
# TODO: Update value
#  - ENDPOINT
#  - GTAG_ID (if you have google analytics ID)
#  - AMCHARTS_LICENSE (for commercial use only)
#######################
  production_json:
    CONSOLE_API:
        ENDPOINT: http://console-api.example.com
    DOMAIN_NAME: spaceone
    DOMAIN_NAME_REF: domain_reference
#    GTAG_ID: UA-111111111-1
#    AMCHARTS_LICENSE:
#        ENABLED: true
#        CHARTS: CH111111111
#        MAPS: MP111111111
#        TIMELINE: TL111111111

###############################################
# TODO: Update value
#  - host
#  - alb.ingress.kubernetes.io/certificate-arn
#  - external-dns.alpha.kubernetes.io/hostname
###############################################
  # Ingress
#  ingress:
#    enabled: true
#    host: '${console-domain}'   # host for ingress (ex. *.console.spaceone.dev)
#    annotations:
#      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
#      alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
#      alb.ingress.kubernetes.io/inbound-cidrs: 0.0.0.0/0 # replace or leave out
#      alb.ingress.kubernetes.io/scheme: "internet-facing" # internet-facing
#      alb.ingress.kubernetes.io/target-type: instance # Your console and console-api should be NodePort for this configuration.
#      alb.ingress.kubernetes.io/load-balancer-name: spaceone-prd-core-console

  pod:
    spec: {}

###############################
# Console-API
###############################
console-api:
  enabled: true
  developer: false
  name: console-api
  replicas: 2
  image:
      name: public.ecr.aws/megazone/spaceone/console-api
      version: 1.10.0
  imagePullPolicy: IfNotPresent

###############################################
# TODO: Update value
#  - cors
###############################################

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
###############################################
# TODO: Update value
#  - host
#  - alb.ingress.kubernetes.io/certificate-arn
#  - external-dns.alpha.kubernetes.io/hostname
###############################################

  # Ingress
#  ingress:
#    enabled: true
#    host: '${console-api-domain}'   # host for ingress (ex. console-api.spaceone.dev)
#    annotations:
#        alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
#        alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
#        alb.ingress.kubernetes.io/inbound-cidrs: 0.0.0.0/0 # replace or leave out
#        alb.ingress.kubernetes.io/scheme: "internet-facing" # internet-facing
#        alb.ingress.kubernetes.io/target-type: instance # Your console and console-api should be NodePort for this configuration.
#        alb.ingress.kubernetes.io/load-balancer-name: spaceone-prd-core-console-api

  pod:
    spec: {}