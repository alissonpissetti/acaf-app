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

## Changelog (admin → Sistema → Atualizações)

Cada commit neste repositório pode registrar automaticamente uma entrada no changelog central (`acaf-api/changelog/changelog.json`), com ambiente **App**. O admin lê via API (`GET /api/admin/changelog`).

Instale o hook **uma vez** por clone (na pasta irmã `acaf-api` ou no app):

```bash
chmod +x ../acaf-api/scripts/install-changelog-hooks-all.sh
../acaf-api/scripts/install-changelog-hooks-all.sh
```

Ou só neste repo:

```bash
chmod +x .githooks/post-commit
git config core.hooksPath .githooks
```

Após cada `git commit`, inclua o `changelog/changelog.json` atualizado na API no mesmo commit (ou num commit seguinte `chore: sincroniza changelog.json commits`). Use `[skip changelog]` na mensagem para pular. Formato recomendado:

```
feat(app): nova tela de reservas

Changelog:
- Reservas com calendário semanal
```

No admin, **Importar do Git** (`POST /api/admin/changelog/sync`) importa commits que ainda não estão no banco.

Release local (requer assinatura):

```bash
flutter build appbundle --release
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```
