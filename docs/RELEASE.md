# Publicação automática (Android + iOS)

Cada push em `main` ou `master` dispara o workflow `.github/workflows/release.yml`:

1. Calcula a versão automaticamente (sem editar `pubspec.yaml` manualmente).
2. Compila release Android (AAB) e iOS (IPA).
3. Publica no Google Play e na App Store Connect (TestFlight).

## Versionamento

| Campo | Origem | Exemplo (run #42, pubspec `1.0.0`) |
|--------|--------|-------------------------------------|
| `BUILD_NUMBER` / `versionCode` / `CFBundleVersion` | `github.run_number` | `42` |
| `BUILD_NAME` / `versionName` / `CFBundleShortVersionString` | `{major}.{minor}.{run_number}` | `1.0.42` |

Para mudar **major** ou **minor**, altere só a linha `version:` no `pubspec.yaml` (ex.: `2.0.0+1`). O CI continua incrementando o patch com o número do build.

Teste local do cálculo:

```bash
GITHUB_RUN_NUMBER=42 bash tool/ci/version.sh
```

## Secrets do GitHub (Settings → Secrets and variables → Actions)

### Android (Google Play)

| Secret | Descrição |
|--------|-----------|
| `ANDROID_KEYSTORE_BASE64` | Arquivo `.jks` ou `.keystore` em base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Senha do keystore |
| `ANDROID_KEY_ALIAS` | Alias da chave |
| `ANDROID_KEY_PASSWORD` | Senha da chave |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | JSON completo da service account do Google Play |

Gerar base64 do keystore:

```bash
base64 -i upload-keystore.jks | pbcopy
```

No Play Console: criar app `com.movly.app`, vincular service account com permissão de release.

### iOS (App Store Connect)

| Secret | Descrição |
|--------|-----------|
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Certificado Distribution `.p12` em base64 |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Senha do `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | Profile App Store `com.movly.app` em base64 |
| `KEYCHAIN_PASSWORD` | Senha aleatória para keychain temporário no CI |
| `APP_STORE_CONNECT_KEY_ID` | Key ID da API key |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Conteúdo do `.p8` em **base64** |

## Variáveis opcionais (Settings → Variables)

| Variable | Padrão | Descrição |
|----------|--------|-----------|
| `PLAY_STORE_TRACK` | `internal` | Faixa do Play: `internal`, `alpha`, `beta`, `production` |

Defina `PLAY_STORE_TRACK` em **Variables** do repositório; o workflow usa `internal` se a variável não existir (via `env` do job).

## Publicação manual (local)

Requer credenciais e assinatura configuradas:

```bash
export BUILD_NUMBER=99
export BUILD_NAME=1.0.99
export PLAY_STORE_SERVICE_ACCOUNT_JSON="$(cat play-store-key.json)"
bundle exec fastlane android deploy
```

## Primeiro deploy

1. Configure todos os secrets no repositório `alissonpissetti/connect-app`.
2. Faça push em `main` — o workflow roda automaticamente.
3. Android: build aparece na faixa **internal** do Play Console.
4. iOS: build aparece em **TestFlight** (não envia para revisão da App Store).

Para promover a produção no Play, altere `PLAY_STORE_TRACK` para `production` nas variáveis do repositório.
