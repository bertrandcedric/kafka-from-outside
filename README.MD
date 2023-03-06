## Test HAProxy

To test, run the stack with `docker-compose up -d`

in `client` enter docker 

```
docker-compose exec client bash

kafka-console-producer --bootstrap-server haproxy:9092 --topic example --producer.config /tmp/client.properties
kafka-console-consumer --bootstrap-server haproxy:9092 --topic example --from-beginning --consumer.config /tmp/client.properties
kafka-topics --bootstrap-server haproxy:9092 --topic example --describe --command-config /tmp/client.properties
```