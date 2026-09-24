# Semaine 3 : Terraform + LocalStack + Checkov

Infra AWS simulée avec LocalStack (Docker Compose) et déployée avec Terraform : bucket S3, clé KMS, rôle IAM, fonction Lambda.

## Déploiement
- `docker compose up -d` (token LocalStack dans un `.env` non versionné)
- `cd terraform && terraform init && terraform apply`

## Scan Checkov
- Avant durcissement : 31 checks OK, 14 en échec (`rapport-checkov-avant.txt`)
- Après durcissement : 46 checks OK, 0 en échec, 8 ignorés et justifiés (`rapport-checkov-apres.txt`)

## Corrections faites
- Bucket S3 : chiffrement KMS avec rotation de clé et policy explicite, versioning, blocage d'accès public
- IAM : permission limitée au bucket au lieu de `*`
- Lambda : tracing actif, concurrence limitée

## Findings ignorés (justifiés dans le code)
VPC, dead letter queue, code signing, logs d'accès S3, réplication, lifecycle, notifications : hors périmètre pour un lab local.

## Vérification
La Lambda répond (`invoke` renvoie 200) avant et après le durcissement.
