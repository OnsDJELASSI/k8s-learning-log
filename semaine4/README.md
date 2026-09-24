# Semaine 4 : IAM / Zero Trust avec Keycloak

Keycloak (Docker Compose) comme fournisseur d'identité OIDC pour une petite appli Flask de test.

## Mise en place
- `docker compose up -d` (mot de passe admin dans un `.env` non versionné)
- Realm `lab`, rôles `admin` et `user`
- Client OIDC public `test-app` (authorization code + PKCE S256)
- Utilisateurs `alice` (admin) et `bob` (user)
- MFA : TOTP obligatoire (action requise `CONFIGURE_TOTP`), code demandé à la connexion

## RBAC dans l'appli (`app/app.py`)
- `/profile` : tout utilisateur connecté
- `/admin` : rôle `admin` uniquement (alice : accès OK, bob : 403 Forbidden)
- Les rôles sont lus dans l'access token (`realm_access.roles`)

## Fichiers
- `docker-compose.yml`
- `app/app.py`
- `realm-lab-export.json` : export partiel du realm (rôles et client, sans utilisateurs)

## Limites (lab)
- Keycloak en mode `start-dev` (pas pour la production)
- L'appli lit les rôles sans vérifier la signature du token (acceptable ici car reçu directement du serveur, à faire en production)

## Suite possible
Brancher Keycloak comme fournisseur d'auth de l'app déployée sur Minikube (semaines 1-2).
