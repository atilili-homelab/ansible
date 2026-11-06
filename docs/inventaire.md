# Inventaire

L'inventaire est dynamique : `inventory/inventory.proxmox.yml` interroge l'API
de Proxmox et ne retient que les machines démarrées. Le token de l'API est lu
dans OpenBao, comme les autres secrets.

Les tags posés sur les machines par OpenTofu deviennent des groupes Ansible, que
`inventory/groups.yml` assemble en groupes fonctionnels (`swarm_managers`,
`swarm_workers`, `gluster`, `nfs_media`…).

Aucun fichier n'est échangé entre OpenTofu et Ansible : ajouter une machine à un
groupe revient à lui poser un tag.

Le VPS, hors du cluster, est décrit dans `inventory/inventory.ovh.ini`.

Pour vérifier le résultat :

```bash
ansible-inventory --graph
```
