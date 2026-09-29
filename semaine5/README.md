# Semaine 5 : gestion des vulnérabilités (Trivy, Checkov, OpenVAS)

## Pipeline de scan

    Image conteneur  ->  Trivy         (paquets et dependances de l'image)
    Code Terraform   ->  Checkov       (mauvaises configurations IaC)
    Service deploye  ->  OpenVAS       (vulnerabilites vues depuis le reseau)
              \-> remediation -> rescan -> rapport avant / apres

## Ce que chaque outil a apporte
- Checkov (semaine 3) : 14 echecs avant, 0 apres durcissement du Terraform
- Trivy : 86 CVE HIGH/CRITICAL avant (image httpd:2.4.49, Debian 10 EOL), 0 apres passage a httpd:2.4
- OpenVAS : 1 finding Medium (HTTP TRACE/TRACK, CVSS 5.8) avant, corrige avec TraceEnable off

## Cible de test
Conteneur httpd:2.4.49 (image basee sur Debian 10, non supporte) remplace par httpd:2.4 avec TraceEnable off.

## Fichiers
- rapport-trivy-avant.txt, rapport-trivy-apres.txt
- rapport-openvas-avant.pdf, rapport-openvas-apres.pdf
- CVE-analyse.md : fiche detaillee (CVE-2022-1664 CVSS 9.8, et TRACE/TRACK CVSS 5.8)
- httpd-fix/disable-trace.conf : correctif applique

## Mise en place d'OpenVAS
Greenbone Community Edition en Docker Compose, a partir du fichier compose.yaml officiel (non recopie ici). Scans limites a des conteneurs de test locaux.

## Limites
- Trivy et OpenVAS ne voient pas la meme couche : Trivy analyse les paquets de l'image, OpenVAS teste le comportement du service en fonctionnement. Les deux sont necessaires pour une vue complete.
- Environnement de lab, pas de scan de systemes tiers.
