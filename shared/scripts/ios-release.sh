#!/usr/bin/env bash
# Prepara e valida o release iOS do LagCheck com AdMob obrigatoriamente ativado (LAGCHECK_ADS_ENABLED=YES)
# e gera o diff comercial entre versões para App Store Connect e GitHub.
#
# Uso:
#   shared/scripts/ios-release.sh <versionName> <buildNumber> [--channel testflight|app-store] [--mode archive|notes-only|verify-archive] [--custom-notes "..."]
#
# Saída padronizada:
#   shared/distribution/release/ios/v<versionName>-b<buildNumber>/
#     appstore/release-notes-pt-BR.txt
#     appstore/release-notes-en-US.txt
#     appstore/release-notes-es-ES.txt
#     github-release-notes.md
#     LagCheck-<versionName>-<buildNumber>.xcarchive  (nos modos archive / verify-archive)
set -euo pipefail

MODE="archive"
CHANNEL="testflight"
CUSTOM_NOTES=""
BASE_REF=""
SKIP_TESTS="false"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:?informe --mode archive|verify-archive|notes-only}"
      shift 2
      ;;
    --channel)
      CHANNEL="${2:?informe --channel testflight|app-store}"
      shift 2
      ;;
    --custom-notes)
      CUSTOM_NOTES="${2:-}"
      shift 2
      ;;
    --base-ref)
      BASE_REF="${2:-}"
      shift 2
      ;;
    --skip-tests)
      SKIP_TESTS="true"
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"

VERSION_NAME="${1:?informe o versionName (X.Y, ex.: 1.2)}"
BUILD_NUMBER="${2:?informe o buildNumber inteiro positivo (ex.: 13)}"

[[ "$VERSION_NAME" =~ ^[0-9]+\.[0-9]+$ ]] || { echo "versionName deve usar X.Y (ex.: 1.2)" >&2; exit 2; }
[[ "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]] || { echo "buildNumber deve ser inteiro positivo" >&2; exit 2; }
[[ "$MODE" == "archive" || "$MODE" == "verify-archive" || "$MODE" == "notes-only" ]] || {
  echo "--mode deve ser archive, verify-archive ou notes-only" >&2
  exit 2
}
[[ "$CHANNEL" == "testflight" || "$CHANNEL" == "app-store" ]] || {
  echo "--channel deve ser testflight ou app-store" >&2
  exit 2
}

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IOS_DIR="$ROOT/apps/ios"
OUT="${LAGCHECK_IOS_RELEASE_DIR:-$ROOT/shared/distribution/release/ios/v${VERSION_NAME}-b${BUILD_NUMBER}}"
ARCHIVE_PATH="$OUT/LagCheck-${VERSION_NAME}-${BUILD_NUMBER}.xcarchive"
EXPORT_PATH="$OUT/LagCheck-${VERSION_NAME}-${BUILD_NUMBER}-export"

mkdir -p "$OUT"

# iOS exige anúncios AdMob ativos em produção/TestFlight (Decisão 97 e 146).
export LAGCHECK_ADS_ENABLED="YES"
export LAGCHECK_ADMOB_APP_ID_PROD="ca-app-pub-5542349230926522~8215990145"

grep -Fq "LAGCHECK_ADS_ENABLED: YES" "$IOS_DIR/project.yml" || {
  echo "Erro: apps/ios/project.yml deve manter LAGCHECK_ADS_ENABLED: YES." >&2
  exit 1
}
grep -Fq "$LAGCHECK_ADMOB_APP_ID_PROD" "$IOS_DIR/project.yml" || {
  echo "Erro: ID de produção do AdMob iOS não encontrado em apps/ios/project.yml." >&2
  exit 1
}

python3 "$ROOT/shared/scripts/generate_release_notes.py" \
  --platform ios \
  --channel "$CHANNEL" \
  --version "$VERSION_NAME" \
  --build "$BUILD_NUMBER" \
  --base-ref "$BASE_REF" \
  --custom-notes "$CUSTOM_NOTES" \
  --ads-enabled true \
  --out-appstore-dir "$OUT/appstore" \
  --out-github-md "$OUT/github-release-notes.md" \
  --repo-root "$ROOT"

echo "Notas comerciais geradas em $OUT/appstore e $OUT/github-release-notes.md" >&2

if [[ "$MODE" == "notes-only" ]]; then
  exit 0
fi

cd "$IOS_DIR"
if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate >/dev/null
fi

if [[ "$SKIP_TESTS" != "true" ]]; then
  SIM_DEST="generic/platform=iOS Simulator"
  if command -v xcrun >/dev/null 2>&1; then
    BOOTED_OR_IPHONE="$(xcrun simctl list devices available iPhone | sed -nE 's/.*\(([0-9A-F-]{36})\).*/\1/p' | head -n 1 || true)"
    if [[ -n "$BOOTED_OR_IPHONE" ]]; then
      SIM_DEST="platform=iOS Simulator,id=${BOOTED_OR_IPHONE}"
    fi
  fi
  xcodebuild test \
    -project "$IOS_DIR/Nolaggy.xcodeproj" \
    -scheme NolaggyUnitTests \
    -destination "$SIM_DEST" \
    -quiet
fi

ARCHIVE_EXTRA=()
if [[ "$MODE" == "verify-archive" ]]; then
  ARCHIVE_EXTRA+=(CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="")
fi

xcodebuild archive \
  -project "$IOS_DIR/Nolaggy.xcodeproj" \
  -scheme Nolaggy \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  MARKETING_VERSION="$VERSION_NAME" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  LAGCHECK_ADS_ENABLED=YES \
  "${ARCHIVE_EXTRA[@]}" \
  -quiet

INFO_PLIST="$ARCHIVE_PATH/Products/Applications/Nolaggy.app/Info.plist"
[[ -f "$INFO_PLIST" ]] || { echo "Erro: Info.plist não encontrado no archive em $INFO_PLIST" >&2; exit 1; }

ADS_PLIST_VAL="$(/usr/libexec/PlistBuddy -c 'Print :LagCheckAdsEnabled' "$INFO_PLIST")"
GAD_PLIST_VAL="$(/usr/libexec/PlistBuddy -c 'Print :GADApplicationIdentifier' "$INFO_PLIST")"
[[ "$ADS_PLIST_VAL" == "YES" ]] || {
  echo "Erro: LagCheckAdsEnabled no bundle iOS deveria ser YES, mas foi '$ADS_PLIST_VAL'." >&2
  exit 1
}
[[ "$GAD_PLIST_VAL" == "$LAGCHECK_ADMOB_APP_ID_PROD" ]] || {
  echo "Erro: GADApplicationIdentifier no bundle iOS deveria ser '$LAGCHECK_ADMOB_APP_ID_PROD', mas foi '$GAD_PLIST_VAL'." >&2
  exit 1
}

echo "Archive iOS verificado: LagCheckAdsEnabled=$ADS_PLIST_VAL | GADApplicationIdentifier=$GAD_PLIST_VAL" >&2

if [[ "$MODE" == "archive" ]]; then
  EXPORT_PLIST="${LAGCHECK_IOS_EXPORT_OPTIONS:-$ROOT/shared/distribution/release/ExportOptions-TestFlight.plist}"
  [[ -f "$EXPORT_PLIST" ]] || { echo "Erro: ExportOptions não encontrado em $EXPORT_PLIST" >&2; exit 1; }
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_PLIST" \
    -allowProvisioningUpdates \
    -quiet
  echo "$EXPORT_PATH"
else
  echo "$ARCHIVE_PATH"
fi
