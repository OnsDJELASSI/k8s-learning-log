# Semaine 2 : sécuriser un cluster K8s local

Cluster Minikube (profil `secu`) relancé avec Calico, parce que le CNI par défaut ne fait pas appliquer les NetworkPolicies.

## RBAC
- Un ServiceAccount `app-reader` dans le namespace `secu-lab`
- Un Role qui autorise seulement get/list/watch sur les pods (et leurs logs)
- Vérifié avec `kubectl auth can-i` : list pods = yes, delete pods = no, list secrets = no, list pods dans `default` = no

## NetworkPolicies
- Une policy `default-deny-ingress` qui bloque tout le trafic entrant du namespace
- Une policy `allow-frontend-to-backend` qui n'ouvre que le port 80 du backend, et seulement pour les pods `app=frontend`
- Résultat : frontend -> backend = 200, intruder -> backend = timeout (000)

## Fichiers
- `rbac.yaml`, `netpol-deny-all.yaml`, `netpol-allow-frontend.yaml`
- `resultats-tests.txt` : sortie des tests

## Pas fait pour l'instant
Le scan Trivy des images est repris en semaine 5, dans le pipeline de scan complet.
