# Procedures

Guarded operational procedures that complement the formal SOPs and service overviews.

- [NPM API token creation and rotation](npm-api-token-rotation.md) — create and validate a long-lived Nginx Proxy Manager token before synchronising its encrypted recovery source.
- [NPM token SOPS synchronisation](npm-token-sops-synchronisation.md) — synchronise TestServer's protected Nginx Proxy Manager environment into its SOPS recovery source without exposing credentials or disturbing a dirty checkout.
