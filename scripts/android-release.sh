#!/usr/bin/env bash
# Gera o pacote do LagCheck (Android) para o teste interno do Google Play.
# Uso: scripts/android-release.sh <versionName> [versionCode]     ex.: scripts/android-release.sh 1.0
# Em GitHub Actions, versionCode é GITHUB_RUN_NUMBER + LAGCHECK_BUILD_OFFSET.
# Fora dele, informe-o explicitamente: scripts/android-release.sh 1.0 12
# Saída padronizada: release/android/v<versionName>-b<versionCode>/
#   lagcheck-android-v<versionName>-b<versionCode>.aab   (enviar ao Play Console)
#   mapping.txt                                          (símbolos do R8; enviar junto, em "Arquivos de desofuscação")
#   SHA256SUMS.txt
set -euo pipefail
VERSION_NAME="${1:?informe o versionName (ex.: 1.0)}"
if [[ -n "${2:-}" ]]; then
  VERSION_CODE="$2"
elif [[ -n "${GITHUB_RUN_NUMBER:-}" ]]; then
  BUILD_OFFSET="${LAGCHECK_BUILD_OFFSET:?configure LAGCHECK_BUILD_OFFSET para o último build já enviado}"
  [[ "$GITHUB_RUN_NUMBER" =~ ^[1-9][0-9]*$ && "$BUILD_OFFSET" =~ ^[0-9]+$ ]] || { echo "run number e offset devem ser inteiros válidos" >&2; exit 2; }
  VERSION_CODE="$((GITHUB_RUN_NUMBER + BUILD_OFFSET))"
else
  echo "informe o versionCode ou execute na automação de release do GitHub" >&2
  exit 2
fi
[[ "$VERSION_NAME" =~ ^[0-9]+\.[0-9]+$ ]] || { echo "versionName deve usar X.Y (ex.: 1.0)" >&2; exit 2; }
[[ "$VERSION_CODE" =~ ^[1-9][0-9]*$ ]] || { echo "versionCode deve ser inteiro positivo" >&2; exit 2; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${LAGCHECK_RELEASE_DIR:-$ROOT/release/android/v${VERSION_NAME}-b${VERSION_CODE}}"
NAME="lagcheck-android-v${VERSION_NAME}-b${VERSION_CODE}"

cd "$ROOT/android"
./gradlew clean :app:bundleRelease \
  -Plagcheck.versionName="$VERSION_NAME" -Plagcheck.versionCode="$VERSION_CODE"

AAB="app/build/outputs/bundle/release/app-release.aab"
MAPPING="app/build/outputs/mapping/release/mapping.txt"
mkdir -p "$OUT"
cp "$AAB" "$OUT/$NAME.aab"
[ -f "$MAPPING" ] && cp "$MAPPING" "$OUT/mapping.txt"

# Confere a assinatura antes de entregar.
jarsigner -verify "$OUT/$NAME.aab" >/dev/null && echo "assinatura OK" || { echo "AAB SEM ASSINATURA VÁLIDA" >&2; exit 1; }
( cd "$OUT" && shasum -a 256 "$NAME.aab" mapping.txt > SHA256SUMS.txt )
echo "$OUT/$NAME.aab"
