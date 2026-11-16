#!/usr/bin/env bash
# Gera o pacote do LagCheck (Android) com ambiente GA4 e política de anúncios explícitos.
#
# Uso:
#   shared/scripts/android-release.sh <versionName> [versionCode] [testing|production] [--artifact aab|apk|both] [--ads-enabled true|false]
#
# Exemplos:
#   shared/scripts/android-release.sh 1.3 "" testing --artifact aab --ads-enabled false
#   shared/scripts/android-release.sh 1.3 9 production --artifact apk --ads-enabled true
#
# Em GitHub Actions, se versionCode vier vazio, usa GITHUB_RUN_NUMBER + LAGCHECK_BUILD_OFFSET.
# Saída padronizada: shared/distribution/release/android/v<versionName>-b<versionCode>-<ambiente>/
#   lagcheck-android-<ambiente>-v<versionName>-b<versionCode>.aab   (quando artifact=aab|both)
#   LagCheck-Android-<versionName>-b<versionCode>.apk               (quando artifact=apk|both em production)
#   mapping.txt                                                     (símbolos do R8)
#   SHA256SUMS.txt
set -euo pipefail

ARTIFACT="${LAGCHECK_ARTIFACT:-aab}"
ADS_ENABLED="${LAGCHECK_ADS_ENABLED:-true}"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact)
      ARTIFACT="${2:?informe --artifact aab|apk|both}"
      shift 2
      ;;
    --artifact=*)
      ARTIFACT="${1#*=}"
      shift
      ;;
    --ads-enabled)
      ADS_ENABLED="${2:?informe --ads-enabled true|false}"
      shift 2
      ;;
    --ads-enabled=*)
      ADS_ENABLED="${1#*=}"
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"

VERSION_NAME="${1:?informe o versionName (ex.: 1.3)}"
if [[ -n "${2:-}" ]]; then
  VERSION_CODE="$2"
elif [[ -n "${GITHUB_RUN_NUMBER:-}" ]]; then
  BUILD_OFFSET="${LAGCHECK_BUILD_OFFSET:?configure LAGCHECK_BUILD_OFFSET para o último build já enviado}"
  [[ "$GITHUB_RUN_NUMBER" =~ ^[1-9][0-9]*$ && "$BUILD_OFFSET" =~ ^[0-9]+$ ]] || {
    echo "run number e offset devem ser inteiros válidos" >&2
    exit 2
  }
  VERSION_CODE="$((GITHUB_RUN_NUMBER + BUILD_OFFSET))"
else
  echo "informe o versionCode ou execute na automação de release do GitHub" >&2
  exit 2
fi

[[ "$VERSION_NAME" =~ ^[0-9]+\.[0-9]+$ ]] || { echo "versionName deve usar X.Y (ex.: 1.3)" >&2; exit 2; }
[[ "$VERSION_CODE" =~ ^[1-9][0-9]*$ ]] || { echo "versionCode deve ser inteiro positivo" >&2; exit 2; }

CHANNEL="${3:-testing}"
[[ "$CHANNEL" == "testing" || "$CHANNEL" == "production" ]] || {
  echo "ambiente deve ser testing ou production" >&2
  exit 2
}
[[ "$ARTIFACT" == "aab" || "$ARTIFACT" == "apk" || "$ARTIFACT" == "both" ]] || {
  echo "--artifact deve ser aab, apk ou both" >&2
  exit 2
}
[[ "$ADS_ENABLED" == "true" || "$ADS_ENABLED" == "false" ]] || {
  echo "--ads-enabled deve ser true ou false" >&2
  exit 2
}

if [[ "$CHANNEL" == "testing" ]]; then
  VARIANT="ValidationRelease"
  BUILD_FLAVOR="validation"
else
  VARIANT="ProductionRelease"
  BUILD_FLAVOR="production"
fi
BUILD_VARIANT="${BUILD_FLAVOR}Release"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${LAGCHECK_RELEASE_DIR:-$ROOT/shared/distribution/release/android/v${VERSION_NAME}-b${VERSION_CODE}-${CHANNEL}}"
AAB_NAME="lagcheck-android-${CHANNEL}-v${VERSION_NAME}-b${VERSION_CODE}.aab"
if [[ "$CHANNEL" == "production" ]]; then
  APK_NAME="LagCheck-Android-${VERSION_NAME}-b${VERSION_CODE}.apk"
else
  APK_NAME="LagCheck-Android-${VERSION_NAME}-b${VERSION_CODE}-${CHANNEL}.apk"
fi

if [[ -d "$ROOT/apps/android" ]]; then
  cd "$ROOT/apps/android"
else
  cd "$ROOT/android"
fi

echo "Gerando Android ${VARIANT} | version=${VERSION_NAME} (${VERSION_CODE}) | artifact=${ARTIFACT} | adsEnabled=${ADS_ENABLED}" >&2

MERGED_MANIFEST="app/build/intermediates/merged_manifest/${BUILD_VARIANT}/process${VARIANT}MainManifest/AndroidManifest.xml"

if [[ "$ARTIFACT" == "aab" || "$ARTIFACT" == "both" ]]; then
  ./gradlew clean ":app:bundle${VARIANT}" \
    -Plagcheck.versionName="$VERSION_NAME" \
    -Plagcheck.versionCode="$VERSION_CODE" \
    -Plagcheck.adsEnabled="$ADS_ENABLED" \
    -Plagcheck.allowApkSelfUpdate=false

  if [[ -f "$MERGED_MANIFEST" ]] && grep -Fq "android.permission.REQUEST_INSTALL_PACKAGES" "$MERGED_MANIFEST"; then
    echo "Erro: AAB da Play Store não deve declarar REQUEST_INSTALL_PACKAGES." >&2
    exit 1
  fi
fi

if [[ "$ARTIFACT" == "apk" || "$ARTIFACT" == "both" ]]; then
  APK_CLEAN_TASK=()
  if [[ "$ARTIFACT" == "apk" ]]; then
    APK_CLEAN_TASK=("clean")
  fi
  ./gradlew "${APK_CLEAN_TASK[@]}" ":app:assemble${VARIANT}" \
    -Plagcheck.versionName="$VERSION_NAME" \
    -Plagcheck.versionCode="$VERSION_CODE" \
    -Plagcheck.adsEnabled="$ADS_ENABLED" \
    -Plagcheck.allowApkSelfUpdate=true

  if [[ ! -f "$MERGED_MANIFEST" ]] || ! grep -Fq "android.permission.REQUEST_INSTALL_PACKAGES" "$MERGED_MANIFEST"; then
    echo "Erro: APK direto deve declarar REQUEST_INSTALL_PACKAGES no manifest." >&2
    exit 1
  fi
fi

mkdir -p "$OUT"
SHA_FILES=()

MAPPING="app/build/outputs/mapping/${BUILD_VARIANT}/mapping.txt"
if [[ -f "$MAPPING" ]]; then
  cp "$MAPPING" "$OUT/mapping.txt"
  SHA_FILES+=("mapping.txt")
fi

verify_apk_signature() {
  local apk_file="$1"
  local sdk_root="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  local apksigner_bin=""
  if [[ -n "$sdk_root" && -d "$sdk_root/build-tools" ]]; then
    apksigner_bin="$(find "$sdk_root/build-tools" -maxdepth 2 -name apksigner -type f 2>/dev/null | sort -V | tail -n 1 || true)"
  fi
  if [[ -n "$apksigner_bin" ]]; then
    "$apksigner_bin" verify "$apk_file" >/dev/null
  else
    jarsigner -verify "$apk_file" >/dev/null
  fi
}

if [[ "$ARTIFACT" == "aab" || "$ARTIFACT" == "both" ]]; then
  AAB="app/build/outputs/bundle/${BUILD_VARIANT}/app-${BUILD_FLAVOR}-release.aab"
  [[ -f "$AAB" ]] || { echo "AAB não encontrado em $AAB" >&2; exit 1; }
  cp "$AAB" "$OUT/$AAB_NAME"
  jarsigner -verify "$OUT/$AAB_NAME" >/dev/null && echo "assinatura AAB OK" >&2 || {
    echo "AAB SEM ASSINATURA VÁLIDA" >&2
    exit 1
  }
  SHA_FILES+=("$AAB_NAME")
  echo "$OUT/$AAB_NAME"
fi

if [[ "$ARTIFACT" == "apk" || "$ARTIFACT" == "both" ]]; then
  APK="app/build/outputs/apk/${BUILD_FLAVOR}/release/app-${BUILD_FLAVOR}-release.apk"
  [[ -f "$APK" ]] || { echo "APK assinado não encontrado em $APK (verifique a configuração de assinatura)" >&2; exit 1; }
  cp "$APK" "$OUT/$APK_NAME"
  verify_apk_signature "$OUT/$APK_NAME" && echo "assinatura APK OK" >&2 || {
    echo "APK SEM ASSINATURA VÁLIDA" >&2
    exit 1
  }
  SHA_FILES+=("$APK_NAME")
  echo "$OUT/$APK_NAME"
fi

( cd "$OUT" && shasum -a 256 "${SHA_FILES[@]}" > SHA256SUMS.txt )
