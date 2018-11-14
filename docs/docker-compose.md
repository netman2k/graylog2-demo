[TOC]



# 개요

Docker Compose 를 통하여 Graylog2 기능을 확인하고자 할 때 사용

## 구성 컴포넌트 

 ![1541819026824](assets/1541819026824.png)

# 2. 구성

## 2.1. OS setting
### vm.max_map_count 증가
다음 설정을 적용하지 않을 경우, 컨테이너가 실행되지 않을 수 있으니 반드시 설정할 수 있도록 한다. 자세한 사항은 [Reference Document](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/docker.html)를 참조할 것.
```bash
cat <<EOF > /etc/sysctl.d/20-vm-max-map-count.conf 
vm.max_map_count=262144
sysctl -p
```

## 2.2. MaxMind GeoLite2 Database

Graylog2에서 IP의 위치 정보를 사용하기 위해 다음 URL에서 GeoLite2 City Database를 다운로드 받은 후 graylog2/GeoLite2-City 디렉토리에 GeoLite2-City.mmdb 파일을 위치 시킨다.

* [다운로드 링크](https://dev.maxmind.com/geoip/geoip2/geolite2/)

```bash
wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz -O /tmp/GeoLite2-City.tar.gz
tar zxvf /tmp/GeoLite2-City.tar.gz --strip 1 -C ./graylog2/GeoLite2-City
```

## 2.3. Start containers
### GRAYLOG2 Web listen URI

bootstrap.sh는 내부적으로 `GRAYLOG_WEB_ENDPOINT_URI=http://${HOST_IP}:9000/api`가 설정되어있는데, 이 값에 넘겨줄 호스트의 IP 정보를 얻은 후 `docker-compose up` 을 실행시켜 서비스를 구동시킨다.

```
./bootstrap.sh
```

# 3. 관리 도구

## 3.1. Kafka-manager
Apache Kafka Cluster 및 Topic 설정 관리를 위해 kafka-manager를 사용할 수 있다.
접속 정보는 다음과 같다.
*  http://<호스트 IP>:9009

## 3.2. Kibana 접속 정보
Graylog2의 시각화의 단점을 보완하기위해 Kibana를 사용할 수 있다. 
* http://<호스트 IP>:5601

## 3.3. Cerebro 접속 정보
> Graylog2의 Web binding port와 곂치는 관계로 9000 -> 9100으로 변경처리
직접적인 Elasticsearch 클러스터를 관리하기 위한 목적의 관리도구로 Cerebro를 사용할 수 있다.

* http://<호스트 IP>:9100

접속 시 ES URL을 물어볼 경우 다음과 같이 입력한다.
* http://elasticsearch:9200

# 4. Clean up containers
다음 명령을 사용하면 사용중인 모든 컨테이너 및 볼륨들을 삭제한다.
```bash
docker-compose down -v
```

# 5. 기타사항

## 5.1. Elasticsearch 서비스 스케일링 업/다운

`docker compose up --scale` 명령으로 Elasticsearch 의 replica 수를 조정할 수 있다.
다음 명령은 Elasticsearch 노드를 3개까지 증가시킨다.
```bash
docker-compose up --scale elasticsearch=3
```