#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ICON_SRC="$PROJECT_ROOT/assets/main_logo.svg"
ICONS_DIR="$PROJECT_ROOT/linux/icons"

echo "→ Gerando ícones PNG..."
for SIZE in 16 32 48 64 128 256 512; do
  mkdir -p "$ICONS_DIR/${SIZE}x${SIZE}"
  magick -background none "$ICON_SRC" -resize "${SIZE}x${SIZE}" \
    "$ICONS_DIR/${SIZE}x${SIZE}/nexus_cts.png"
done
echo "  ✓ Ícones gerados em linux/icons/"

echo "→ Executando fastforge..."
export PATH="$PATH:$HOME/.pub-cache/bin"
cd "$PROJECT_ROOT"
fastforge package --platform linux --targets rpm || true
# fastforge vai falhar no rpmbuild — corrigido abaixo

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | tr -d '\r')
RPM_DIR="$PROJECT_ROOT/dist/$VERSION/nexus_cts-${VERSION}-linux_rpm/rpmbuild"

if [[ ! -d "$RPM_DIR" ]]; then
  echo "ERRO: Diretório rpmbuild não encontrado em dist/$VERSION/"
  exit 1
fi

echo "→ Corrigindo spec e copiando ícones para BUILD..."

for SIZE in 16 32 48 64 128 256 512; do
  mkdir -p "$RPM_DIR/BUILD/icons/${SIZE}x${SIZE}"
  cp "$ICONS_DIR/${SIZE}x${SIZE}/nexus_cts.png" \
     "$RPM_DIR/BUILD/icons/${SIZE}x${SIZE}/nexus_cts.png"
done
cp "$ICONS_DIR/256x256/nexus_cts.png" "$RPM_DIR/BUILD/nexus_cts.png"

SPEC="$RPM_DIR/SPECS/nexus_cts.spec"
SPEC="$SPEC" python3 - <<'PYEOF'
import re, os

spec_path = os.environ["SPEC"]
with open(spec_path) as f:
    content = f.read()

install_block = """%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/%{name}
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_datadir}/metainfo
mkdir -p %{buildroot}%{_datadir}/pixmaps
for SIZE in 16 32 48 64 128 256 512; do
  mkdir -p %{buildroot}%{_datadir}/icons/hicolor/${SIZE}x${SIZE}/apps
  cp %{_topdir}/BUILD/icons/${SIZE}x${SIZE}/%{name}.png \\
     %{buildroot}%{_datadir}/icons/hicolor/${SIZE}x${SIZE}/apps/%{name}.png
done
cp -r %{_topdir}/BUILD/%{name}/* %{buildroot}%{_datadir}/%{name}
ln -s %{_datadir}/%{name}/%{name} %{buildroot}%{_bindir}/%{name}
cp %{_topdir}/BUILD/%{name}.desktop %{buildroot}%{_datadir}/applications
cp %{_topdir}/BUILD/icons/256x256/%{name}.png %{buildroot}%{_datadir}/pixmaps/%{name}.png
cp %{_topdir}/BUILD/%{name}*.xml %{buildroot}%{_datadir}/metainfo || :
update-mime-database %{_datadir}/mime &> /dev/null || :

%post
gtk-update-icon-cache -f -t %{_datadir}/icons/hicolor &> /dev/null || :

%postun
gtk-update-icon-cache -f -t %{_datadir}/icons/hicolor &> /dev/null || :
update-mime-database %{_datadir}/mime &> /dev/null || :

%files
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/metainfo
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%{_datadir}/pixmaps/%{name}.png"""

content = re.sub(r'%install.*', install_block, content, flags=re.DOTALL)
with open(spec_path, "w") as f:
    f.write(content)
print("  ✓ Spec atualizado")
PYEOF

echo "→ Executando rpmbuild..."
cd "$RPM_DIR"
rpmbuild --define "_topdir $(pwd)" -bb SPECS/nexus_cts.spec

RPM_FILE=$(find "$RPM_DIR/RPMS" -name "*.rpm" | head -1)
echo ""
echo "✅ RPM gerado: $RPM_FILE"
echo "   Tamanho: $(du -sh "$RPM_FILE" | cut -f1)"
