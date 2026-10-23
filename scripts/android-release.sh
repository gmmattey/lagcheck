#!/usr/bin/env bash
# Gera o pacote do LagCheck (Android) para o teste interno do Google Play.
# Uso: scripts/android-release.sh <versionName> <versionCode>      ex.: scripts/android-release.sh 1.0.0 1
# Saída padronizada: release/android/v<versionName>-b<versionCode>/
#   lagcheck-android-v<versionName>-b<versionCode>.aab   (enviar ao Play Console)
#   mapping.txt                                          (símbolos do R8; enviar junto, em "Arquivos de desofuscação")
#   SHA256SUMS.txt
set -euo pipefail
VERSION_NAME="${1:?informe o versionName (ex.: 1.0.0)}"
VERSION_CODE="${2:?informe o versionCode crescente (ex.: 1)}"
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
