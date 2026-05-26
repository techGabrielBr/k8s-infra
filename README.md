# K8s Infrastructure

Deploy da infraestrutura principal utilizando Kubernetes (K8s) através de manifests declarativos em YAML.

Este repositório contém os componentes utilizados pela arquitetura de microserviços do projeto:

- RabbitMQ
- MongoDB
- Redis
- Kong API Gateway

A infraestrutura fornece:

- mensageria assíncrona
- banco NoSQL
- cache distribuído
- API Gateway
- autenticação JWT
- comunicação entre microsserviços

Todos os serviços são executados dentro de um cluster Kubernetes.

---

# Arquitetura

```text
                ┌───────────────┐
                │     Kong      │
                │ API Gateway   │
                └───────┬───────┘
                        │
        ┌───────────────┼───────────────┐
        ↓                               ↓
   Users API                       Catalog API
        │                               │
        │                               │
        ▼                               ▼
    RabbitMQ                        MongoDB
        │
        ▼
Notifications

                     Redis
                       ▲
                       │
                 Catalog Cache
```

---

# Tecnologias Utilizadas

Infraestrutura:

- Docker
- Kubernetes
- RabbitMQ
- MongoDB
- Redis
- Kong Gateway
- YAML Manifests
- kubectl

---

# Estrutura do Repositório

```text
k8s-infra
│
├── rabbitmq/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── secret.yaml
│
├── mongodb/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── pvc.yaml
│
├── redis/
│   ├── deployment.yaml
│   └── service.yaml
│
├── kong/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── secret.yaml
│
└── README.md
```

---

# Pré-requisitos

Para executar o projeto é necessário possuir instalado:

- Docker
- Kubernetes cluster
- kubectl

Clusters locais recomendados:

- Minikube
- Kind
- Docker Desktop Kubernetes

---

# Deploy no Kubernetes

Os manifests Kubernetes estão organizados por serviço.

Para aplicar toda a infraestrutura:

```bash
kubectl apply -f rabbitmq/
kubectl apply -f mongodb/
kubectl apply -f redis/
kubectl apply -f kong/
```

---

# Verificando os Recursos

Listar todos os recursos criados:

```bash
kubectl get all
```

Ver pods:

```bash
kubectl get pods
```

Ver services:

```bash
kubectl get svc
```

Ver logs:

```bash
kubectl logs <nome-do-pod>
```

---

# RabbitMQ

RabbitMQ é responsável pela comunicação assíncrona entre microsserviços.

Utilizado para:

- filas de mensagens
- processamento assíncrono
- event-driven architecture

---

# Portas RabbitMQ

| Porta | Função |
|---|---|
| 5672 | Comunicação AMQP |
| 15672 | Interface Web |

---

# Acessando RabbitMQ

```bash
kubectl port-forward svc/rabbitmq 15672:15672
```

URL:

```text
http://localhost:15672
```

---

# MongoDB

MongoDB é utilizado como banco NoSQL para persistência de dados.

Utilizado principalmente pelo Catalog API.

---

# Recursos MongoDB

- persistência de catálogo
- persistência de jogos
- persistência de biblioteca do usuário

---

# Acessando MongoDB

```bash
kubectl port-forward svc/mongodb 27017:27017
```

---

# Redis

Redis é utilizado como cache distribuído.

Atualmente utilizado para:

- cache de listagem de jogos
- redução de consultas ao MongoDB
- melhoria de performance

---

# Acessando Redis

```bash
kubectl port-forward svc/redis 6379:6379
```

---

# Kong Gateway

Kong é utilizado como API Gateway da arquitetura.

Responsável por:

- roteamento
- autenticação JWT
- proxy reverso
- controle de entrada dos microsserviços

---

# Rotas do Kong

| Serviço | Rota |
-------------------------------
| Users API | `/users` |
| Catalog API | `/catalog` |

---

# JWT Authentication

O Kong valida tokens JWT antes de encaminhar requisições para APIs protegidas.

Fluxo:

```text
Client
   ↓
Kong Gateway
   ↓
JWT Validation
   ↓
Microservice
```

---

# Acessando Kong

```bash
kubectl port-forward svc/kong 8000:8000
```

URL:

```text
http://localhost:8000
```

---

# Secrets

A infraestrutura utiliza Kubernetes Secrets para armazenar:

- JWT secret
- credenciais RabbitMQ
- senhas de banco
- configurações sensíveis

---

# Persistent Volumes

Serviços que utilizam persistência:

- MongoDB
- Grafana

Utilizam PVCs para evitar perda de dados após reinício dos pods.

---

# Objetivo do Projeto

Este repositório foi criado para demonstrar:

- infraestrutura de microserviços em Kubernetes
- arquitetura orientada a eventos
- mensageria assíncrona
- API Gateway
- cache distribuído
- persistência NoSQL
- autenticação JWT
- deploy declarativo com YAML

A stack pode ser utilizada como base para arquiteturas modernas baseadas em microsserviços.