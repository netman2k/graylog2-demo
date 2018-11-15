[TOC]



> 본 예제는 모두 CentOS 7.4이상 환경에서 테스트 되었음을 먼저 알려드립니다.

# 1. 개요

- Docker swarm을 통하여 로그 수집 시스템을 구성

# 2. 기본 컴포넌트 구성

## 2.1. Docker 설치 및 Swarm 클러스터 구성

* 참조문서 
	* https://docs.docker.com/install/linux/docker-ce/centos/
	* https://docs.docker.com/engine/swarm/swarm-tutorial/

### 2.2.1 Docker 설치
편리를 위해 본인 경우 설치 스크립트를 만들어놓고 사용한다. 이 방법이 좋다고는 할 수 없으니 다른 더 좋은 방법이 있다면 그 방법을 이용하도록 한다.

```
git clone https://github.com/netman2k/bash_scripts.git
cd bash_scripts/etc
sudo ./install_docker.sh -m 262144
```

이 스크립트 경우 다음과 같은 설정을 하도록 되어있다.
* Docker experimental feature 활성화
* Prometheus metric 포트(4999) 설정
* Elasticsearch를 위한 vm.max_map_count 설정
* net.bridge.bridge-nf-call-iptables 설정
* Max locked memory unlimited 설정

### 2.2.2 Swarm Cluster 생성

#### 메니저(Manager) 생성

Swarm Manager 역할을 할 서버에서 다음 커맨드를 입력하여 Swarm 클러스터를 생성한다. 생성 후에는 다른 Worker 노드들이 클러스터에 Join 할 수 있는 명령어를 제공해준다.

```bash
ip=$(ip addr show $(/sbin/ip route | awk '/default/ { print $5 }') | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
docker swarm init --advertise-addr $ip
```

#### 워커(worker)

위에서 생성된 커맨드를 입력하여 클러스터 조인(Join)을 진행한다.

```bash
docker swarm join --token SWMTKN-1-2clri82tu6olhie5dkrhtjp1vb7g7tbyfixgnmlkl8nb1lkplj-7dj5tscihde1s8scatql9qzfa <manager IP>:2377

```

## 2.2. Monitoring 서비스 구성

* https://github.com/netman2k/docker-prometheus-swarm.git

## 2.3. Docker Flow Proxy 서비스 구성

* https://proxy.dockerflow.com/
* https://proxy.dockerflow.com/swarm-mode-stack/

## 2.4. Apache Zookeeper ensemble 구성

* https://github.com/netman2k/docker-kafka-swarm.git 

## 2.5. Apache Kafka 구성

* https://github.com/netman2k/docker-kafka-swarm.git

## 2.6. Logstash 구성 

* https://github.com/netman2k/docker-logstash-stack.git

## 2.7. Elasticsearch 구성
* https://github.com/netman2k/docker-elasticsearch-swarm.git

## 2.7. MongoDB Cluster 구성

	* https://github.com/smartsdk/mongo-rs-controller-swarm

## 2.8. Graylog2 구성

* https://github.com/netman2k/docker-graylog2-swarm.git


# 3. 기타