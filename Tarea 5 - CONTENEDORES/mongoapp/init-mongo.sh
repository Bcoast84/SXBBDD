#!/bin/bash

echo "Ejecutando script de inicialización..."
sleep 5  # Esperar a que MongoDB esté listo

# Este script se ejecuta automáticamente al iniciar el contenedor de MongoDB
# porque está montado en /docker-entrypoint-initdb.d/
mongo --username root --password example --authenticationDatabase admin <<EOF
use testdb
db.createUser({
  user: "appuser",
  pwd: "apppass",
  roles: [ { role: "readWrite", db: "testdb" } ]
})
EOF

echo "Inicialización completada."
