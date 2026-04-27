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
# Adicionar ao PATH (se ainda não estiver)
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### Build local por target

| Plataforma | Comando | Pré-requisitos |
|---|---|---|
| **Linux ZIP** | `fastforge package --platform linux --targets zip` | `p7zip-full` |
| **Linux DEB** | `fastforge package --platform linux --targets deb` | `sudo apt install dpkg-dev` |
| **Linux AppImage** | `fastforge package --platform linux --targets appimage` | `appimagetool` no `$PATH` |
| **Linux RPM** | `bash scripts/build_rpm.sh` | `sudo apt install rpm patchelf imagemagick` |
| **macOS DMG** | `fastforge package --platform macos --targets dmg` | `npm install -g appdmg` (apenas macOS) |
| **Windows EXE** | `fastforge package --platform windows --targets exe` | [Inno Setup 6](https://jrsoftware.org/isinfo.php) (apenas Windows) |

> **⚠️ RPM:** O fastforge possui um bug com versões no formato `x.y.z+n` que gera um spec com caminhos relativos incorretos. Use sempre o script `scripts/build_rpm.sh` em vez do comando fastforge direto — ele corrige o spec automaticamente e instala os ícones no hicolor theme.

Os artefatos são gerados em `dist/`.

### Script RPM (workaround automático)

```bash
# Gera ícones, corrige spec e executa rpmbuild
bash scripts/build_rpm.sh
```

O script realiza automaticamente:
1. Converte `assets/main_logo.svg` para PNG em 7 tamanhos (16–512px) em `linux/icons/`
2. Executa `fastforge package --platform linux --targets rpm` (falha esperada no rpmbuild)
3. Copia os ícones para o diretório `BUILD/` do rpmbuild
4. Reescreve o `%install` do spec com caminhos absolutos e entradas no hicolor theme
5. Executa `rpmbuild` diretamente com o spec corrigido

### Ícones

Os PNGs são pré-gerados em `linux/icons/{size}x{size}/nexus_cts.png` (16, 32, 48, 64, 128, 256, 512px).
O ícone da janela GTK é carregado em runtime a partir de `data/nexus_cts.png` no bundle — configurado em `linux/runner/my_application.cc` e instalado via `linux/CMakeLists.txt`.

### Publicar no GitHub Releases (manual)

```bash
export GITHUB_TOKEN="seu_personal_access_token"
fastforge release --name production
```

### Configuração de packaging

```
linux/packaging/
├── deb/make_config.yaml
├── appimage/make_config.yaml
└── rpm/make_config.yaml        # icon: linux/icons/512x512/nexus_cts.png
macos/packaging/
└── dmg/make_config.yaml
windows/packaging/
└── exe/make_config.yaml
distribute_options.yaml         # Targets dev e production com publish no GitHub
```

---

## 🤖 CI/CD — GitHub Actions

O workflow `.github/workflows/build.yml` automatiza o build e release para todos os targets Linux.

### Triggers

| Evento | Ação |
|---|---|
| `git push --tags v*.*.*` | Build completo + GitHub Release automático |
| `Actions → Run workflow` | Build manual com opção de publicar |

### Jobs

```
build-linux (matrix: zip / deb / appimage / rpm)
└── Roda em paralelo no ubuntu-latest
    ├── Instala dependências específicas do target
    ├── Gera PNGs de ícone via ImageMagick
    ├── Executa fastforge
    ├── [RPM only] Aplica fix de spec + rpmbuild
    └── Upload do artefato (retido 7 dias)

release
└── Só executa em push de tag ou workflow_dispatch com publish=true
    ├── Baixa todos os 4 artefatos
    └── Cria GitHub Release com todos os arquivos
```

### Como fazer uma release

```bash
# Atualizar version em pubspec.yaml, então:
git add pubspec.yaml
git commit -m "chore: bump version to 0.4.0"
git tag v0.4.0
git push origin main --tags
```

O GitHub Actions gera ZIP, DEB, AppImage e RPM e publica automaticamente em Releases.

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
- ✅ Ícone da janela GTK carregado em runtime via `my_application.cc`
- ✅ Ícones hicolor completos (16–512px) para DEB/RPM/AppImage
- ✅ Script `scripts/build_rpm.sh` com fix automático do spec fastforge
- ✅ CI/CD via GitHub Actions (ZIP, DEB, AppImage, RPM + GitHub Releases)

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
| 🔗 CI/CD Integration | Média | ✅ | GitHub Actions: build automático de ZIP/DEB/AppImage/RPM + GitHub Releases |
| 🔍 Filtro Avançado | Baixa | ☐ | Buscar resultados por status, seria, plano, intervalo de tempo |
| ⏱️ Métricas de Performance | Baixa | ☐ | Tempo de execução por módulo, gargalos identificados |
| 💾 Cache Inteligente | Baixa | ☐ | Cache de resultados com invalidação baseada em timestamp |
| 📋 Relatório Customizado | Baixa | ☐ | Editor de templates para exportação de relatórios |
| 🔐 Suporte a Credenciais | Baixa | ☐ | Autenticação para suites remotas (SSH/local storage seguro) |
| 🌐 Sincronização de Suites | Baixa | ☐ | Importar suites de arquivo config central ou servidor |

---

## �📄 Licença

Interno — Google Suite Centralizer
