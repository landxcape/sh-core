# Flutter Shortcuts
alias fcbuild="flutter pub get && cd ios && pod install --repo-update && cd .. && flutter build appbundle --release"
alias fcbuild-reset="flutter clean && flutter pub get && cd ios && pod deintegrate && pod update && pod install --repo-update && cd .. && flutter build appbundle --release"

# Parallel clean for all Flutter projects
fpclean_all() {
  find . -name pubspec.yaml -exec grep -l "flutter:" {} \; |
    xargs -I {} -P $(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo 6) \
      sh -c 'd=${1%/*}; echo "Cleaning $d"; cd "$d" && flutter clean' _ {}
}
