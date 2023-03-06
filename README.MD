## Test HAProxy

To test, run the stack with `docker-compose up -d`

in `client` enter docker 

```
docker-compose exec client bash

kafka-console-producer --bootstrap-server haproxy:9092 --topic example
kafka-console-consumer --bootstrap-server haproxy:9092 --topic example --from-beginning
kafka-topics --bootstrap-server haproxy:9092 --topic example --describe
```