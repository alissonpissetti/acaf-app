# Tema movly. (acaf-app)

App **cliente final** — identidade **movly.** com submarca obrigatória **by ACAF Brasil** (parceria contratual).  
Referência de ecossistema: admin em `acaf-adm/docs/PREMISSAS-VISUAIS.md` (semântica de cores); o app usa a paleta **movly.app** (limão + gradiente céu + roxo).

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `lib/branding/movly_brand.dart` | Wordmark, submarca (`subbrand`), taglines, títulos de sistema |
| `lib/theme/app_colors.dart` | Tokens de cor (hex) |
| `lib/theme/app_typography.dart` | Figtree (corpo) + Unbounded (display) via `google_fonts` |
| `lib/theme/movly_theme_tokens.dart` | `ThemeExtension` (gradientes, lime, ecosystem accent) |
| `lib/theme/movly_theme.dart` | `ThemeData` Material 3 |
| `lib/theme/app_theme.dart` | Alias legado → `MovlyTheme` |
| `lib/widgets/brand_logo.dart` | Lockup (`BrandLogo`) — ver variantes abaixo |

### `BrandLogo` (fundos claros)

| Variante | Asset | Uso |
|----------|--------|-----|
| `purple` (padrão) | `movly-logo-purple.svg` | Wordmark roxo + texto `MovlyBrand.subbrand` (**by ACAF Brasil**) |
| `white` | `movly-logo-white.svg` | Mesmo padrão em fundos escuros (`subbrandColor` claro se necessário) |
| `lockupOnLime` / `lime` | PNG multicolor | Lockup com tagline no PNG; não repetir texto enquanto o artefato estiver correto |

**Regra:** não exibir só o wordmark SVG sem a submarca visível. Em SVG, `BrandLogo` acrescenta `Text(MovlyBrand.subbrand)` automaticamente.

## Cores principais

- **Roxo** `#8254E4` — botões primários, abas ativas, chrome estrutural
- **Limão** `#CBF74F` — energia e acentos (ex.: indicador de aba); não como fundo dominante da navegação
- **Céu / periwinkle** `#89B4E0` / `#7579E5` — gradientes de marca
- **Ink** `#17142B` — texto
- **Fundo suave** `#F4FAE8` — scaffold

`MovlyThemeTokens.ecosystemAccent` (`#E8881C`) — laranja do admin apenas para alertas/ações cross-ecossistema, não como cor primária do app.

## Tipografia

- **Unbounded** — títulos de destaque (`AppTypography.display`, `tagline`)
- **Figtree** — UI, corpos, botões; submarca em `AppTypography.label` (via `BrandLogo`)

## Uso no código

```dart
MaterialApp(
  theme: MovlyTheme.light(),
  // ...
);

// Gradientes / lime
final tokens = context.movlyTokens;

// Preferir Theme.of(context).colorScheme em telas novas
```

## Próxima fase (UI)

Migrar telas que ainda usam aliases `AppColors.orange*` (legado Connect) para `primary` / `lime`.  
Revisar ícones launcher e splash nativos após assets definitivos.  
**Gap de asset:** lockup SVG/PNG unificado com **by ACAF Brasil** (hoje PNGs do manual ainda dizem “by ACAF” sem “Brasil”); wordmark roxo SVG não inclui tagline — compensar com texto até novo artefato.
