#!/bin/bash

###
# Инициализируем бд
###

docker compose exec -it configSrv mongosh --port 27017 <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
exit();
EOF

docker compose exec -it shard1 mongosh --port 27018 <<EOF
rs.initiate({_id: "shard1", members: [
{_id: 0, host: "shard1:27018"},
{_id: 1, host: "shard1_repl1:27021"},
{_id: 2, host: "shard1_repl2:27022"},
{_id: 3, host: "shard1_repl3:27023"}
]}); 
exit();
EOF

docker compose exec -it shard2 mongosh --port 27019 <<EOF
rs.initiate({_id: "shard2", members: [
{_id: 0, host: "shard2:27019"},
{_id: 1, host: "shard2_repl1:27024"},
{_id: 2, host: "shard2_repl2:27025"},
{_id: 3, host: "shard2_repl3:27026"}
]}) 
exit();
EOF

docker compose exec -it mongos_router mongosh --port 27020 <<EOF
sh.addShard( "shard1/shard1:27018");
sh.addShard( "shard2/shard2:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})
db.helloDoc.countDocuments()
EOF