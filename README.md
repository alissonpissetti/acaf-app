# acaf

App Flutter (usuário final).

## Publicação automática

Cada push em `main` ou `master` compila e publica Android (Google Play) e iOS (TestFlight) com versão incrementada automaticamente.

Configuração de secrets e versionamento: [docs/RELEASE.md](docs/RELEASE.md).

## Desenvolvimento local

```bash
flutter pub get
flutter run
```

Release local (requer assinatura):

```bash
flutter build appbundle --release
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```
