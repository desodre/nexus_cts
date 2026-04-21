# nexus_cts — Google Suite Centralizer

Ferramenta de automação e análise Flutter para unificar o fluxo de trabalho das suítes de teste oficiais do Android (CTS/VTS/GTS). Executa testes, coleta resultados em tempo real e oferece dashboard centralizado com gerenciamento dinâmico de suites.

**Plataformas:** Linux, macOS, Windows  
**Arquitetura:** MVVM com Models, Services, ViewModels e Views em Flutter puro  
**Estado:** Production-ready com streaming ao vivo e persistência

---

## ✨ Funcionalidades

### 📊 Dashboard Home
- Listagem de dispositivos ADB com status (device/offline/unauthorized)
- Resultados agrupados por suite com cards expansíveis
- Parse automático de `test_result.xml` com progresso visual
- Meta-dados: serial, build fingerprint, plano, timestamp

### ⚙️ Configurações Dinâmicas
- Adicione/remova suites ilimitadas com alias, tipo e caminho customizado
- Flags globais: `autoRetest`, `rebootOnFail`
- Persistência automática via SharedPreferences
- Suporte para CTS, VTS, GTS e tipos customizados

### ⚡ Execução em Tempo Real
- Streaming de logs durante execução via `Process.start`
- Output ao vivo com auto-scroll automático
- Botão stop/cancel com feedback imediato
- Suporte para workDir e device serial customizados

### 🔍 Análise de Resultados
- Parse XML robusto com tratamento de erros
- Extração: Summary, Build info, Plan, Start time
- Taxa de aprovação em percentual com indicador visual
- Scans de subplans `/subplans/*.xml` para retests

### 🚀 Performance
- I/O e XML parsing em isolate separado (sem bloqueio da UI)
- Responsive mesmo com diretórios de resultados grandes
- ScrollController com auto-scroll incremental

---

## 🏗️ Arquitetura

```
lib/
├── models/              # SuiteEntry, AdbDevice, TestResult
├── services/            # AdbService, SuiteResultService, SuiteRunnerService
├── viewmodels/          # HomeViewModel, SettingsViewModel, RunSuiteViewModel
├── view/
│   ├── home/           # HomePage com dashboard
│   ├── settings/       # Settings para CRUD de suites
│   ├── run/            # RunSuitePage com output ao vivo
│   └── widgets/        # AppDrawer reutilizável
└── main.dart           # MaterialApp entry point
test/
└── widget_test.dart    # Testes de widget
```

**Pattern:** MVVM com ChangeNotifier (sem Provider package)

---

## 🚀 Seu Primeiro Uso

1. **Clone e instale dependências:**
```bash
git clone <repo>
cd nexus_cts
flutter pub get
```

2. **Abra Configurações e crie uma suite:**
   - Nome: `CTS-16.1`
   - Tipo: `CTS`
   - Caminho: `/path/to/android-cts-16.1_r3`
   - Salva automaticamente

3. **Conecte um dispositivo ADB:**
```bash
adb devices
```

4. **Acesse Home e clique Atualizar Resultados**
   - Scanneia `/path/to/.../results/*/test_result.xml`
   - Exibe resultados com progresso

5. **Execute nova suite:**
   - Menu → Executar Suíte
   - Selecione suite, device, modo (newRun/retest/subplan)
   - Observe logs em tempo real
   - Clique Stop para cancelar

---

## 🛠️ Comandos

```bash
flutter pub get          # Instalar dependências
flutter run              # Executar em modo debug
flutter analyze lib/     # Análise estática
dart format lib/ test/   # Formatar código
flutter test             # Executar testes
flutter build linux --release  # Build Linux produção
```

---

## 📦 Distribuição (Fastforge)

O projeto usa [Fastforge](https://pub.dev/packages/fastforge) para empacotar e publicar releases em múltiplos formatos.

### Instalação

```bash
dart pub global activate fastforge
```

### Build local (dev)

```bash
# Pacote ZIP (sem dependências extras)
fastforge package --platform linux --targets zip

# Pacote DEB (requer dpkg-dev)
fastforge package --platform linux --targets deb

# AppImage (requer locate + appimagetool)
fastforge package --platform linux --targets appimage

# RPM (requer rpmbuild + patchelf)
fastforge package --platform linux --targets rpm

# Todos os targets Linux de uma vez
fastforge release --name dev
```

Os artefatos são gerados em `dist/`.

### Build por plataforma

| Plataforma | Comando | Pré-requisitos |
|---|---|---|
| **Linux DEB** | `fastforge package --platform linux --targets deb` | `sudo apt install dpkg-dev` |
| **Linux AppImage** | `fastforge package --platform linux --targets appimage` | `sudo apt install locate` + [appimagetool](https://github.com/AppImage/appimagetool) |
| **Linux RPM** | `fastforge package --platform linux --targets rpm` | `sudo apt install rpm patchelf` |
| **Linux ZIP** | `fastforge package --platform linux --targets zip` | `p7zip` |
| **macOS DMG** | `fastforge package --platform macos --targets dmg` | `npm install -g appdmg` (apenas macOS) |
| **Windows EXE** | `fastforge package --platform windows --targets exe` | [Inno Setup 6](https://jrsoftware.org/isinfo.php) (apenas Windows) |

### Publicar no GitHub Releases

```bash
export GITHUB_TOKEN="seu_personal_access_token"
fastforge release --name production
```

Isso empacota e publica automaticamente em [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases). Configure o token em [Personal Access Tokens](https://github.com/settings/tokens).

### Configuração

A configuração de distribuição fica em `distribute_options.yaml` na raiz do projeto. As configs de empacotamento por plataforma ficam em:

```
linux/packaging/
├── deb/make_config.yaml
├── appimage/make_config.yaml
└── rpm/make_config.yaml
macos/packaging/
└── dmg/make_config.yaml
windows/packaging/
└── exe/make_config.yaml
```

---

## 📦 Dependências

| Package | Versão | Uso |
|---------|--------|-----|
| **flutter** | latest | Framework |
| **shared_preferences** | ^2.3.4 | Persistência de suites |
| **xml** | ^6.5.0 | Parse de test_result.xml |
| **cupertino_icons** | ^1.0.8 | Ícones iOS |

---

## 🔧 Configuração de Suite

Cada suite requer:
- **Nome (alias):** Identificação livre (ex: `CTS-16.1_r3_pab`)
- **Tipo:** `CTS`, `VTS`, `GTS` ou customizado
- **Caminho:** Absoluto para raiz da suite (tem `tools/cts-tradefed`)

O app constrói automaticamente: `{caminho}/tools/{tipo-lowercase}-tradefed`

---

## 📋 Fluxos de Execução

| Modo | Comportamento |
|------|---------------|
| **newRun** | Executa suite completa |
| **retest** | Re-executa apenas módulos que falharam |
| **subplan** | Executa arquivo XML customizado em `/subplans/` |

---

## 🎯 Requisitos

- **Flutter SDK:** ^3.11.4 com desktop enabled
- **Dart SDK:** ^3.11.4
- **JDK:** 17+ (para tradefed)
- **Android SDK:** Platform Tools no `$PATH`
- **Linux/macOS/Windows:** Para desktop targets
- **Google Tests Suits** As suits não são embarcadas, baixe no site da distribuidora https://source.android.com/docs/compatibility/cts/downloads
---

## 📝 Changelog Recente

- ✅ I/O em isolate para UI responsiva
- ✅ Streaming de logs em tempo real
- ✅ Suites ilimitadas e dinâmicas
- ✅ Full MVVM architecture
- ✅ Parse XML com meta-dados completos
- ✅ Device listing com status visual

---

## �️ Roadmap — Futuras Adições

| Feature | Prioridade | Status | Descrição |
|---------|-----------|--------|-----------|
| 🔄 Retry Automático | Alta | ☐ | Re-execução automática de módulos falhados com backoff exponencial |
| 📊 Gráfico de Histórico | Alta | ☐ | Timeline de taxa de aprovação ao longo do tempo por suite |
| 📈 Comparação de Execuções | Alta | ☐ | Diff entre duas execuções (módulos novos/removidos/regressões) |
| ✅ CTS Verifier Results | Alta | ✅ | Parse e display de relatórios do CTS Verifier (testes manuais) |
| 📷 Camera ITS Execution | Alta | ✅ | Suporte para executar Camera ITS com automação de testes ópticos |
| 🔔 Notificações | Média | ☐ | Desktop notifications ao completar testes (sucesso/falha) |
| 📥 Export de Resultados | Média | ☐ | Gerar PDF/CSV com summary, detalhes por módulo, gráficos |
| 🌙 Tema Escuro | Média | ☐ | Suporte a modo dark com persistência de preferência |
| 📱 Multi-Device | Média | ☐ | Executar suite em paralelo em múltiplos dispositivos |
| 🔗 CI/CD Integration | Média | ☐ | Webhooks ou API REST para integrar com Jenkins/GitHub Actions |
| 🔍 Filtro Avançado | Baixa | ☐ | Buscar resultados por status, seria, plano, intervalo de tempo |
| ⏱️ Métricas de Performance | Baixa | ☐ | Tempo de execução por módulo, gargalos identificados |
| 💾 Cache Inteligente | Baixa | ☐ | Cache de resultados com invalidação baseada em timestamp |
| 📋 Relatório Customizado | Baixa | ☐ | Editor de templates para exportação de relatórios |
| 🔐 Suporte a Credenciais | Baixa | ☐ | Autenticação para suites remotas (SSH/local storage seguro) |
| 🌐 Sincronização de Suites | Baixa | ☐ | Importar suites de arquivo config central ou servidor |

---

## �📄 Licença

Interno — Google Suite Centralizer
