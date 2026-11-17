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

Pour déplacer un secret : le copier vers le nouveau chemin, mettre à
jour ses consommateurs, vérifier, puis supprimer l'ancien. Pour ajouter un champ
à un secret existant, utiliser `bao kv patch` : `bao kv put` remplace le secret
entier.

## Secrets Docker Swarm

Le rôle `swarm_secrets` (appelé par `playbooks/sync-docker-secrets.yml`) crée
les secrets Docker du cluster sans liste écrite à la main : il parcourt les
chemins `services/*` d'OpenBao et lit leur `custom_metadata`.

Chaque entrée `<champ>=<N>` de la métadonnée de `services/<service>` devient le
secret Docker `<service>_<champ>_v<N>`, avec la valeur du champ. Un champ sans
métadonnée reste dans OpenBao comme source de vérité et n'est jamais poussé
dans Swarm (secret saisi dans une interface, fichier écrit sur un hôte hors
Swarm…).

`services/komodo`, champ `db_password`, métadonnée `db_password=1`, donne
`komodo_db_password_v1`.

Côté compose, la clé reste stable et seul le nom porte la version : le chemin
dans le conteneur (`/run/secrets/komodo_db_password`) ne change pas d'une
version à l'autre.

```yaml
secrets:
  komodo_db_password: { name: komodo_db_password_v1, external: true }
```

### Ajouter un secret

```bash
bao kv patch -mount=secret services/<service> <champ>=-   # valeur lue sur l'entrée standard
bao kv metadata patch -mount=secret -custom-metadata=<champ>=1 services/<service>
```

Puis lancer le playbook et déclarer le secret `_v1` dans le compose.

### Rotation

Un secret Swarm est immuable : changer une valeur, c'est créer une nouvelle
version.

1. Mettre la nouvelle valeur dans OpenBao (`bao kv patch`).
2. Passer la métadonnée à `N+1` avec `bao kv metadata patch`. Ne jamais
   utiliser `bao kv metadata put` : il remplace toute la `custom_metadata` du
   chemin.
3. Passer le nom à `_v<N+1>` dans le compose, puis committer.
4. Lancer le playbook, qui crée la nouvelle version, puis déployer la stack.

Le passage suivant du playbook supprime l'ancienne version.

### Ménage

En fin de rôle, les secrets créés par Ansible (label `ansible_key`) qui ne
correspondent plus à aucune métadonnée sont supprimés. Docker refuse de
supprimer un secret encore utilisé par un service : un oubli fait échouer le
playbook sans rien casser. Un secret créé par Ansible hors de la convention peut
être protégé du ménage en l'ajoutant à `swarm_secrets_keep` (vide par défaut).

### Saut de ligne final

Une valeur collée ou récupérée par `echo`, `ssh … cat` finit souvent par un
saut de ligne invisible. Certaines applications le gardent dans la valeur
(mot de passe refusé), d'autres le retirent. Pour un mot de passe ou un token,
le retirer :

```bash
bao kv get -mount=secret -field=<champ> services/<service> | tr -d '\n' | bao kv patch -mount=secret services/<service> <champ>=-
```

Les fichiers (clé PEM, YAML) gardent normalement leur saut de ligne final.

## Hôtes hors Swarm

Le VPS et la seedbox lancent leurs conteneurs avec Docker, sans Swarm : ils
n'ont pas de secrets Docker. Le second play de `sync-docker-secrets.yml` écrit
donc les valeurs dans des fichiers, sous `/etc/docker-secrets/` :

- `vault_secrets` : un champ d'OpenBao devient un fichier
  `/etc/docker-secrets/<docker_secret>` (mode `0400`), à monter dans le
  conteneur ;
- `vault_envfiles` : tous les champs d'un chemin deviennent un fichier
  `/etc/docker-secrets/<name>.env` (`CHAMP=valeur`, clés en majuscules), pour
  les applications qui ne lisent leurs secrets que dans l'environnement.

Ces deux listes sont tenues à la main : la découverte par métadonnée ne
concerne que Swarm. Chaque entrée porte le groupe d'hôtes qui la reçoit
(`group`).

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
