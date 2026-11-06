# Intégration continue

La CI tourne sur Forgejo Actions, sur un runner sans root installé par ce dépôt
(`playbooks/ci-forgejo-runner.yml`). Il expose deux labels :

- `podman-nix` : le job tourne dans un conteneur Podman ;
- `nixos` : le job tourne directement sur l'hôte, pour réutiliser le store Nix
  persistant de la machine plutôt que de reconstruire le devShell à chaque run.

Les workflows sont dans `.forgejo/workflows/`.

| Workflow       | Déclencheur                                                  | Ce qu'il fait                                                                                                                                 |
| -------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `ci.yml`       | push sur une branche autre que `main`                        | sur l'hôte : gitleaks sur les commits de la branche et pre-commit sur tous les fichiers ; en parallèle, ansible-lint dans l'image d'exécution |
| `ee-image.yml` | push sur `main` touchant la définition de l'image, ou manuel | construit l'image d'exécution, liste les collections, vérifie les dépendances Python par `pip check`, puis la pousse                          |

Deux choix à noter :

- ansible-lint ne tourne pas dans l'environnement de la CI mais dans l'image
  d'exécution qui sert ensuite à jouer les playbooks, pour que le linter voie
  les mêmes collections que l'exécution réelle.
- Les actions tierces sont épinglées par empreinte et non par étiquette, pour
  qu'une étiquette redéplacée ne change pas le contenu d'un job.
