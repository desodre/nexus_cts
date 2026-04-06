# nexus_cts — Google Suite Centralizer

Ferramenta de automação e análise projetada para unificar o fluxo de trabalho das suítes de teste oficiais do Android. Transforma a execução fragmentada em um ecossistema inteligente que analisa falhas em tempo real e dispara re-testes baseados em subprocessos específicos.

Desenvolvido em **Flutter**, com suporte a Linux, macOS e Windows.

---

## Escopo

O nexus_cts atua como camada de orquestração sobre:

| Suite | Descrição |
|---|---|
| **CTS** | Compatibility Test Suite — validação de compatibilidade padrão |
| **VTS** | Vendor Test Suite — testes de interface de hardware e kernel |
| **GTS** | Google Test Suite — verificação de aplicativos e serviços Google |
| **CTS Verifier** | Instalação e coleta/análise de resultados manuais |

---

## Funcionalidades Core

**Centralizador de Execução**
Interface unificada para disparar comandos `tradefed` sem alternar entre diretórios ou variáveis de ambiente manualmente.

**Analisador de Resultados Dinâmico**
Processa `test_result.xml` imediatamente após a conclusão de cada suite ou módulo — separando erros de infraestrutura de falhas reais e agrupando por pacote.

**Smart Trigger (Gatilhos de Subprocessos)**
Isola módulos que falharam em um plano de teste temporário. Permite condicionais: se o módulo X falhar com o erro Y, reseta `adb`, reinicia o dispositivo e dispara o teste novamente.

**Gestão do CTS Verifier**
Automatiza a instalação do APK correto por nível de API/ABI e importa o report final para o dashboard centralizado.

---

## Fluxo de Trabalho

```
Setup → Execution → Monitoring → Analysis → Action
```

1. **Setup** — detecta dispositivos via `adb`
2. **Execution** — usuário seleciona suite (CTS/VTS/GTS)
3. **Monitoring** — acompanha saída do console e logs do sistema
4. **Analysis** — analisador lê os resultados ao fim da execução
5. **Action** — Pass: gera relatório final / Fail: avalia trigger automático de re-teste isolado

---

## Estrutura do Projeto

```
lib/
├── core/        # Lógica de interação com Tradefed
├── parsers/     # Extração de dados (XML/Logs)
├── triggers/    # Regras para re-testes baseados em resultados
└── dashboard/   # Interface de visualização dos status
test/            # Testes de widget e unitários
```

---

## Requisitos de Ambiente

- **Flutter SDK** com suporte desktop habilitado
- **JDK 17+**
- **Python 3.10+** (scripts de análise e triggers)
- **Android SDK Platform Tools** no `PATH`
- Variáveis de ambiente: `$CTS_ROOT`, `$VTS_ROOT`, `$GTS_ROOT`

---

## Comandos

```bash
# Dependências
flutter pub get

# Executar em modo debug
flutter run

# Testes
flutter test

# Análise estática
flutter analyze

# Build desktop (Linux)
flutter build linux --release
```
