# Installation Samba Arch Linux / EndeavourOS

Ce dossier contient un script d'installation et de configuration de **Samba** pour Arch Linux / EndeavourOS.

## 📌 Ce que fait le script

Le script `installation_samba_arch.sh` :

- Met à jour la base de données pacman (`pacman -Sy`)
- Installe le paquet **samba**
- Crée un fichier `/etc/samba/smb.conf` minimal si aucun n'existe
- Active et démarre les services **smb** et **nmb**
- Configure le pare-feu (si **firewalld** ou **ufw** est présent)

## ▶️ Utilisation

Ouvrez un terminal et exécutez :

```bash
sudo bash EndeavourOS/samba/installation_samba_arch.sh
```

### 👇 Après l'installation

- Vérifiez la configuration :
  ```bash
testparm
```
- Ajoutez un utilisateur Samba :
  ```bash
sudo smbpasswd -a <utilisateur>
```
- Vérifiez le statut des services :
  ```bash
systemctl status smb nmb
```

## 📝 Personnaliser le partage

Le fichier `/etc/samba/smb.conf` contient un exemple de partage commenté. Pour ajouter un partage :

1) Décommentez et adaptez la section `[#partage]`
2) Créez le dossier de partage et ajustez les permissions
3) Redémarrez Samba :

```bash
sudo systemctl restart smb nmb
```

---

> Note : Ce script est conçu pour Arch Linux / EndeavourOS. Sur d'autres distributions, adaptez les commandes d'installation et de gestion de pare-feu.
