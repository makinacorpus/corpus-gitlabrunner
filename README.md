# gitlab runner configuration with makina-states

## Services activated on mostly all nodes:
- memcached
- mysql:
  - root password: secret
  - db0 -> db9, user & password are the same as the database.
- elasticsearch:
  - http://127.0.0.1:9200
  - no restriction
- redis
- pgsql
  - local user postgres is superuser
  - db0 -> db9, user & password are the same as the database
- mongodb
  - db0 -> db9, user & password are the same as the database

## Workers types
### drupal
### python
