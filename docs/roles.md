# Playbooks et rôles

## Points d'entrée

| Fichier           | Rôle                                                      |
| ----------------- | --------------------------------------------------------- |
| `site.yml`        | Bootstrap : socle, Docker, stockage, NFS et cluster Swarm |
| `maintenance.yml` | Mises à jour du système et contrôle de la synchro horaire |

## Playbooks

Les playbooks de `playbooks/` se lancent aussi un par un :

| Playbook                     | Rôle                                                             |
| ---------------------------- | ---------------------------------------------------------------- |
| `bootstrap.yml`              | Socle commun, Docker, disques de données, NFS, Swarm             |
| `upgrade.yml`                | Mise à jour des paquets, redémarrage si nécessaire, notification |
| `dns-setup.yml`              | Serveurs DNS Technitium, primaire puis secondaires               |
| `openbao-setup.yml`          | Installation et mise à jour d'OpenBao et de son certificat       |
| `sync-docker-secrets.yml`    | Secrets d'OpenBao vers Swarm, et en fichiers vers VPS et seedbox |
| `komodo-periphery-setup.yml` | Agent Komodo Periphery sur les hôtes Docker                      |
| `ci-forgejo-runner.yml`      | Runner Forgejo Actions sur Podman, Nix et cache Harmonia         |
| `db-backup.yml`              | Sauvegarde quotidienne des bases de données vers PBS             |
| `forgejo-backup.yml`         | Sauvegarde quotidienne de la forge vers PBS                      |
| `mailcow-backup.yml`         | Sauvegarde quotidienne de Mailcow vers PBS                       |
| `pve-nodes.yml`              | Grafana Alloy sur les nœuds Proxmox (métriques et journal)       |

## Rôles

| Rôle                              | Ce qu'il configure                                                       |
| --------------------------------- | ------------------------------------------------------------------------ |
| `common`                          | Paquets de base, chrony, comptes, durcissement SSH, swap                 |
| `docker`                          | Installation de Docker et configuration du démon                         |
| `podman`                          | Installation de Podman                                                   |
| `disk_data`                       | Disque de données des workers                                            |
| `nfs`                             | Montages réseau NFS                                                      |
| `swarm`                           | Initialisation du cluster et étiquettes des nœuds                        |
| `swarm_secrets`                   | Secrets Swarm découverts dans OpenBao, versionnés, ménage des orphelins  |
| `technitium_dns`, `openbao`       | Services d'infrastructure                                                |
| `certbot`                         | Certificats Let's Encrypt par challenge DNS-01 Cloudflare (pour OpenBao) |
| `forgejo_runner`                  | Runner Forgejo Actions sans root, jobs dans Podman ou sur l'hôte         |
| `nix`                             | Nix (paquets Debian) sur disque dédié `/nix`, builds hors tmpfs, GC auto |
| `harmonia`                        | Cache binaire Nix servant `/nix/store` en HTTP                           |
| `pbs_client`                      | Dépôt et client Proxmox Backup Server                                    |
| `alloy`                           | Grafana Alloy en observateur (métriques unix, journal)                   |
| `forgejo_backup`                  | Sauvegarde de la forge vers PBS                                          |
| `mailcow_backup`                  | Backup officiel de Mailcow (`backup_and_restore.sh`) vers PBS            |
| `db_backup`                       | Dumps des bases conteneurisées (PostgreSQL, MariaDB, MongoDB) vers PBS   |
| `upgrade`, `upgrade_notification` | Mises à jour et compte rendu par notification                            |
| `ntp_check`                       | Contrôle de la synchronisation horaire                                   |

## Sauvegarde des bases

`db_backup` découvre les bases chaque nuit, par les labels de leur conteneur.
Une base se déclare dans son compose, sans rien changer à ce dépôt.

| Label                     | Rôle                                                                   |
| ------------------------- | ---------------------------------------------------------------------- |
| `backup.db.engine`        | `postgres`, `mariadb`, `mongodb`, ou `none` pour l'exclure. Obligatoire |
| `backup.db.user`          | utilisateur du dump (postgres, mongodb)                                |
| `backup.db.name`          | dossier et ID PBS. Défaut : service sans la stack ni `-db`             |
| `backup.db.database`      | mongodb : base sauvegardée                                             |
| `backup.db.auth_database` | mongodb : base d'authentification. Défaut : `backup.db.database`       |

Les mots de passe sont lus dans les secrets Docker, à l'intérieur du conteneur.
Un conteneur Postgres, MariaDB ou Mongo sans label déclenche une alerte.

## Services hors apt

OpenBao et Technitium ne passent pas par `upgrade.yml`.

- **OpenBao** : paquet `.deb` épinglé dans le rôle. Renovate propose les
  nouvelles versions, sans automerge : un restart scelle OpenBao. Snapshot Raft
  avant l'update.
- **Technitium** : l'installeur prend toujours la dernière version. Une action
  Komodo signale les nouvelles releases ; `technitium_dns_update=true` relance
  l'installeur, sur le primaire (tag `dns_primary`) puis les secondaires.

## Collection `homelab.base`

Les rôles génériques sont aussi distribués sous forme de collection,
`homelab.base`, pour être réutilisés depuis d'autres dépôts sans y être
recopiés. Elle ne contient que `common`, `docker`, `podman` et `pbs_client` ;
les autres rôles sont propres à ce homelab et restent dans le dépôt.

Le dépôt Packer s'en sert pendant le build des templates : il installe la
collection à une version donnée et applique les rôles `common` et `docker`, pour
que les paquets de base, chrony et Docker soient déjà dans l'image. Le socle
d'une machine n'est ainsi écrit qu'à un seul endroit, qu'il soit posé au build
du template ou par le bootstrap.
