identity:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: identity
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 0
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10

secret:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: secret
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 4
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10

repository:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: repository
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 3
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10



plugin:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: plugin
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 2
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10


config:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: config
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 0
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10



inventory:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: inventory
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 1
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10

monitoring:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: monitoring
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 5
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10

statistics:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: statistics
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 5
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10

billing:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: billing
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 5
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10

notification:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: notification
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 5
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10

power-scheduler:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: power-scheduler
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 12
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10

cost-saving:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: cost-saving
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 13
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10

spot-automation:
    database:
        DATABASES:
            default:
              username: ${database_user_name}
              password: ${database_user_password}
              db: spot-automation
              host: ${endpoint}
              port: 27017
              ssl: False
              read_preference: PRIMARY
              maxPoolSize: 200
              retryWrites: false
        CACHES:
            default:
              backend: spaceone.core.cache.redis_cache.RedisCache
              host: redis
              port: 6379
              db: 14
              encoding: utf-8
              socket_timeout: 10
              socket_connect_timeout: 10
