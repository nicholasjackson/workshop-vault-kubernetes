resource "container" "mongo" {
  image {
    name = "mongo:7.0.9"
  }

  network {
    id = resource.network.local.meta.id
    ip_address = variable.db_address
  }

  port {
    local           = 27017
    remote          = 27017
    host            = 27017
  }

  environment = {
    MONGO_INITDB_ROOT_USERNAME ="payments"
    MONGO_INITDB_ROOT_PASSWORD ="password"
    MONGO_INITDB_DATABASE      ="payments"
  }
}