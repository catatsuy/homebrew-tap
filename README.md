# homebrew-tap

```bash
brew install catatsuy/tap/bento
brew install catatsuy/tap/notify-slack
brew install catatsuy/tap/purl
brew install catatsuy/tap/curl-http3-libressl
```

Managed formula updates are applied with:

```bash
./scripts/update-formula.sh --all
./scripts/update-formula.sh curl-http3-libressl
```

CI behavior:

- `.github/workflows/homebrew-tap.yml` builds and tests every `Formula/*.rb`
- `.github/workflows/update-formulas.yml` runs scheduled updates and opens one PR per managed formula when changes are detected
