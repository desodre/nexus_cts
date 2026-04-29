# Build com Docker (Compatibilidade Linux)

Para garantir que o `nexus_cts` funcione em distribuições Linux mais antigas (como Ubuntu 20.04), o build deve ser realizado em um ambiente com uma versão da `libc6` (glibc) igual ou inferior à do sistema alvo.

## Estrutura do Ambiente
- **Base:** Ubuntu 20.04 (Focal Fossa)
- **Flutter SDK:** 3.11.4
- **JDK:** 17
- **Ferramentas:** ADB, Fastforge, CMake, Ninja, GTK3 Dev.

## Como Executar o Build

### Pré-requisitos
- Docker e Docker Compose instalados.

### Passo a Passo

1. **Construir e Iniciar:**
   Execute o comando abaixo na raiz do projeto. Ele irá criar a imagem (na primeira execução) e iniciar o processo de build e empacotamento.
   ```bash
   docker-compose up --build
   ```

2. **Resultados:**
   - O executável compilado estará em: `build/linux/x64/release/bundle/`
   - Os pacotes (.deb, .AppImage) estarão em: `dist/` (conforme configuração do fastforge).

## Variáveis de Ambiente
O `docker-compose.yml` utiliza as variáveis `UID` e `GID` para garantir que os arquivos gerados pertençam ao seu usuário local:
```bash
export UID=$(id -u)
export GID=$(id -g)
docker-compose up
```

## Comandos Úteis
- **Entrar no container para debug:**
  ```bash
  docker-compose run builder bash
  ```
- **Limpar apenas os artefatos de build:**
  ```bash
  docker-compose run builder flutter clean
  ```
