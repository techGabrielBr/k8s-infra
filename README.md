# K8s RabbitMQ

Deploy do **RabbitMQ** utilizando **Kubernetes (K8s)** através de manifests declarativos em YAML.

Este repositório demonstra como executar um **message broker RabbitMQ containerizado** dentro de um cluster Kubernetes, permitindo que microserviços se comuniquem de forma **assíncrona utilizando filas de mensagens**.

RabbitMQ é amplamente utilizado em arquiteturas de microserviços para:

* comunicação entre serviços
* processamento assíncrono
* filas de tarefas
* event-driven architecture

Este projeto faz parte de um conjunto de serviços utilizados para demonstrar **microserviços executando em um cluster Kubernetes**.

---

# Arquitetura

O RabbitMQ atua como intermediário entre serviços.

```
Users API
     │
     │ publish event
     ▼
 RabbitMQ
     │
     │ consume message
     ▼
Notifications API
```

Dentro do Kubernetes a estrutura funciona da seguinte forma:

```
Pods (RabbitMQ)
      │
      ▼
Kubernetes Service
      │
      ▼
Other Microservices
```

---

# Tecnologias Utilizadas

Infraestrutura

* Docker
* Kubernetes
* RabbitMQ
* YAML Manifests
* kubectl

---

# Estrutura do Repositório

```
k8s-rabbitmq
│
├── k8s/
│   ├── secret.yaml
│   ├── deployment.yaml
│   └── service.yaml
│
└── README.md
```

---

# Pré-requisitos

Para executar o projeto é necessário possuir instalado:

* Docker
* Kubernetes cluster
* kubectl

Clusters locais recomendados:

* Minikube
* Kind
* Docker Desktop Kubernetes

---

# Deploy no Kubernetes

Os manifests Kubernetes estão localizados no diretório:

```
k8s/
```

Para aplicar todos os recursos:

```bash
kubectl apply -f k8s/
```

---

# Verificando os Recursos

Listar todos os recursos criados:

```bash
kubectl get all
```

Ver pods do RabbitMQ:

```bash
kubectl get pods
```

Ver service:

```bash
kubectl get svc
```

Ver logs do container:

```bash
kubectl logs <nome-do-pod>
```

---

# Acessando o RabbitMQ

RabbitMQ normalmente utiliza as seguintes portas:

| Porta | Função                     |
| ----- | -------------------------- |
| 5672  | Comunicação AMQP           |
| 15672 | Interface de gerenciamento |

Caso seja necessário acessar localmente:

```bash
kubectl port-forward svc/rabbitmq 5672:5672
```

Interface web:

```
http://localhost:15672
```

---

# Descrição dos Manifests Kubernetes

## Secret

Arquivo:

```
k8s/secret.yaml
```

Armazena dados sensíveis do RabbitMQ.

Exemplos:

* usuário administrador
* senha
* credenciais de acesso

Secrets são armazenados em **base64** e consumidos pelos containers como variáveis de ambiente.

---

## Deployment

Arquivo:

```
k8s/deployment.yaml
```

Define o Deployment do RabbitMQ.

Responsabilidades:

* criar pods
* manter pods ativos
* reiniciar pods em caso de falha
* permitir atualização da aplicação

Configurações típicas:

* imagem Docker do RabbitMQ
* portas do container
* variáveis de ambiente
* configuração via ConfigMap e Secret

---

## Service

Arquivo:

```
k8s/service.yaml
```

Cria um Service para expor o RabbitMQ dentro do cluster Kubernetes.

Funções:

* endpoint estável
* comunicação entre microserviços
* balanceamento de conexões

---

# Exemplo de Uso

Um microserviço pode publicar mensagens na fila:

```
UserCreatedEvent
```

Outro microserviço pode consumir essa mensagem:

```
Notifications API → envia email ou push notification
```

Isso permite:

* desacoplamento entre serviços
* processamento assíncrono
* melhor escalabilidade

---

# Objetivo do Projeto

Este repositório foi criado para demonstrar:

* execução de RabbitMQ em Kubernetes
* comunicação assíncrona entre microserviços
* deploy de infraestrutura usando manifests declarativos
* arquitetura baseada em eventos

Ele pode ser utilizado como base para sistemas baseados em **event-driven architecture**.
