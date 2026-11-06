# Secrets

Aucun secret n'est stocké dans ce dépôt.

## Lecture depuis OpenBao

- Les mots de passe et les tokens sont lus dans OpenBao au moment de
  l'exécution, par le plugin `community.hashi_vault`. Le token de l'API Proxmox
  utilisé par l'inventaire suit le même chemin.
- À l'entrée dans le dossier, `.envrc` réutilise la session OpenBao de `yoann`
  (`~/.vault-token`, partagée avec les dépôts opentofu et packer), ou l'ouvre
  avec le mot de passe lu dans Bitwarden via rbw. Il en dérive un token enfant
  valable une heure, limité à `ansible-policy`, et l'exporte dans
  `VAULT_TOKEN` ; `ansible-navigator.yml` le transmet à l'execution
  environment. L'adresse d'OpenBao et la méthode d'authentification (`token`)
  sont dans `ansible.cfg`.

## Convention de rangement

Le chemin d'un secret dit ce qu'il protège et à qui il appartient, pas qui le
lit. Le droit de lecture est donné par les policies OpenBao.

| Chemin                 | Contenu                                                                     |
| ---------------------- | --------------------------------------------------------------------------- |
| `services/<service>/…` | tout ce que possède un service : mots de passe de sa base, clés, tokens API |
| `<outil>/…`            | les identifiants qui sont l'identité propre d'un outil (`ci/`, …)           |

Le chemin d'un service ne change pas quand sa base déménage : il ne dépend pas
de l'endroit où elle tourne.

Les anciens chemins (`databases/`, `stacks/`, `configs/`) migrent service par
service. Pour déplacer un secret : le copier vers le nouveau chemin, mettre à
jour ses consommateurs, vérifier, puis supprimer l'ancien. Pour ajouter un champ
à un secret existant, utiliser `bao kv patch` : `bao kv put` remplace le secret
entier.

## Secrets Docker Swarm

`playbooks/sync-docker-secrets.yml` copie des secrets d'OpenBao vers les secrets
Docker du cluster. Le champ `<champ>` de `services/<service>` devient le secret
Docker `<service>_<champ>` : `services/komodo`, champ `db_password`, donne
`komodo_db_password`.

## Clé de signature d'Harmonia

Le rôle `harmonia` lit la clé dans OpenBao (`ci/harmonia`, champ `secret_key`)
mais ne la génère pas. À faire une seule fois, avant le premier passage :

```bash
nix key generate-secret --key-name mouse.macopla.home-1 > cache.secret
bao kv put -mount=secret ci/harmonia secret_key=@cache.secret
nix key convert-secret-to-public < cache.secret   # clé publique pour les laptops
shred -u cache.secret
```

Les laptops déclarent `http://mouse.macopla.home:5000` dans `substituters` et la
clé publique dans `trusted-public-keys`.
