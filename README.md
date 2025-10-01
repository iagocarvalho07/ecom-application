# E-commerce Application

## 📋 Visão Geral

Este é um projeto de e-commerce desenvolvido em **Spring Boot** com arquitetura monolítica. O sistema oferece funcionalidades básicas de gerenciamento de usuários e produtos, preparando a base para uma futura migração para arquitetura de microserviços.

## 🏗️ Arquitetura Atual

### Branch Main - Arquitetura Monolítica
- **Aplicação única** com todas as funcionalidades integradas
- **Banco de dados compartilhado** (H2 em memória)
- **Deploy simplificado** em um único artefato
- **Desenvolvimento rápido** e fácil de testar

### Evolução para Microserviços (Futuras Branches)
- [ ] **Branch `microservices/user-service`**: Microserviço de usuários
- [ ] **Branch `microservices/product-service`**: Microserviço de produtos
- [ ] **Branch `microservices/order-service`**: Microserviço de pedidos
- [ ] **Branch `microservices/api-gateway`**: Gateway de API
- [ ] **Branch `microservices/infrastructure`**: Configurações de infraestrutura

## 🛠️ Tecnologias Utilizadas

- **Java 17**
- **Spring Boot 3.4.10**
- **Spring Data JPA**
- **H2 Database** (banco em memória)
- **Lombok** (redução de boilerplate)
- **SpringDoc OpenAPI** (documentação Swagger)
- **Maven** (gerenciamento de dependências)

## 📁 Estrutura do Projeto

```
src/main/java/com/ap/ecom/
├── config/                 # Configurações da aplicação
│   └── OpenApiConfig.java
├── controllers/            # Controladores REST
│   ├── ProductController.java
│   └── UseControllerr.java
├── dto/                   # Data Transfer Objects
│   ├── AddressDTO.java
│   ├── ProductRequest.java
│   ├── ProductResponse.java
│   ├── UserRequest.java
│   └── UserResponse.java
├── models/                # Entidades JPA
│   ├── Address.java
│   ├── Product.java
│   ├── User.java
│   └── UserRole.java
├── repository/            # Repositórios de dados
│   ├── ProdutcRepository.java
│   └── UserRepository.java
└── service/               # Lógica de negócio
    ├── ProductService.java
    ├── UserService.java
    └── impl/
        ├── ProductServiceImpl.java
        └── UserServiceImpl.java
```

## 🚀 Como Executar

### Pré-requisitos
- Java 17 ou superior
- Maven 3.6 ou superior

### Executando a Aplicação

1. **Clone o repositório:**
```bash
git clone <url-do-repositorio>
cd ecom-application
```

2. **Execute a aplicação:**
```bash
./mvnw spring-boot:run
```

3. **Acesse a aplicação:**
- **API Base:** http://localhost:8080
- **Swagger UI:** http://localhost:8080/swagger-ui.html
- **H2 Console:** http://localhost:8080/h2-console

## 📚 API Endpoints

### 👥 Gerenciamento de Usuários (`/api/users`)

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/api/users` | Listar todos os usuários |
| GET | `/api/users/{id}` | Buscar usuário por ID |
| POST | `/api/users` | Criar novo usuário |
| PUT | `/api/users/{id}` | Atualizar usuário |

### 🛍️ Gerenciamento de Produtos (`/api/products`)

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/api/products` | Listar todos os produtos |
| GET | `/api/products/{id}` | Buscar produto por ID |
| POST | `/api/products` | Criar novo produto |
| PUT | `/api/products/{id}` | Atualizar produto |
| DELETE | `/api/products/{id}` | Deletar produto |
| GET | `/api/products/search?keyword={termo}` | Buscar produtos |

## 🗄️ Modelo de Dados

### User (Usuário)
- **id**: Identificador único
- **keycloakId**: ID do Keycloak (integração futura)
- **firstName**: Nome
- **lastName**: Sobrenome
- **email**: Email (único)
- **phone**: Telefone
- **role**: Papel do usuário (CUSTOMER, ADMIN)
- **address**: Endereço (relacionamento 1:1)
- **createdAt/updatedAt**: Timestamps

### Product (Produto)
- **id**: Identificador único
- **name**: Nome do produto
- **description**: Descrição
- **price**: Preço
- **stockQuantity**: Quantidade em estoque
- **category**: Categoria
- **imageUrl**: URL da imagem
- **active**: Status ativo/inativo
- **createdAt/updatedAt**: Timestamps

### Address (Endereço)
- **id**: Identificador único
- **street**: Rua
- **city**: Cidade
- **state**: Estado
- **country**: País
- **zipcode**: CEP

## 🔧 Configurações

### Banco de Dados
- **H2 Database** em memória
- **URL:** `jdbc:h2:mem:test`
- **Usuário:** `sa`
- **Senha:** (vazia)
- **Console:** http://localhost:8080/h2-console

### Swagger/OpenAPI
- **Documentação:** http://localhost:8080/swagger-ui.html
- **API Docs:** http://localhost:8080/api-docs

## 🧪 Testes

Execute os testes com:
```bash
./mvnw test
```

## 📦 Build e Deploy

### Build da aplicação:
```bash
./mvnw clean package
```

### Executar JAR:
```bash
java -jar target/ecom-application-0.0.1-SNAPSHOT.jar
```

## 🔮 Roadmap de Evolução

### Branch Main - Melhorias na Arquitetura Monolítica
- [ ] Implementar autenticação e autorização
- [ ] Adicionar validações de negócio
- [ ] Implementar cache (Redis)
- [ ] Adicionar logs estruturados
- [ ] Implementar testes de integração

### Futuras Branches - Migração para Microserviços
- [ ] **Branch `microservices/user-service`**: Extrair lógica de usuários
- [ ] **Branch `microservices/product-service`**: Extrair catálogo de produtos
- [ ] **Branch `microservices/order-service`**: Implementar processamento de pedidos
- [ ] **Branch `microservices/payment-service`**: Implementar processamento de pagamentos
- [ ] **Branch `microservices/notification-service`**: Implementar sistema de notificações
- [ ] **Branch `microservices/api-gateway`**: Implementar gateway de API
- [ ] **Branch `microservices/infrastructure`**: Configurar service discovery, message broker

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 🌳 Estrutura de Branches

### Branch Main (Atual)
- **Arquitetura**: Monolítica
- **Funcionalidades**: Gerenciamento de usuários e produtos
- **Banco**: H2 em memória
- **Deploy**: Aplicação única

### Futuras Branches de Evolução
- **`microservices/user-service`**: Extração do domínio de usuários
- **`microservices/product-service`**: Extração do domínio de produtos  
- **`microservices/order-service`**: Implementação de pedidos
- **`microservices/api-gateway`**: Gateway centralizado
- **`microservices/infrastructure`**: Configurações de infraestrutura

## 👥 Equipe

- **Desenvolvedor Principal**: [Seu Nome]
- **Evolução**: Monolítica (main) → Microserviços (branches futuras)

---

**Nota**: A branch `main` contém a arquitetura monolítica atual. A evolução para microserviços será demonstrada através de branches específicas, mostrando a transição gradual da arquitetura.