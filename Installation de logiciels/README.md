####################################################################################
Nouveau menu interactif :

1- Mise à jour système uniquement
2- Paquets de base (nouveaux paquets de base seuls)
3- Paquets de base + XFCE
4- Paquets de base + KDE
5- Paquets de base + GNOME
6- Paquets de base + AUR
7- Paquets de base + XFCE + AUR
8- Paquets de base + KDE + AUR
9- Paquets de base + GNOME + AUR
10- Paquets AUR uniquement (nouvelle option)
11- Mode simulation
12- Aide

Nouvelles options en ligne de commande :

--base : Installe les paquets de base
--aur-only : Installe uniquement les paquets AUR
--xfce/--kde/--gnome : Installe automatiquement les paquets de base + l'environnement

####################################################################################

Exemples d'utilisation

# Mode interactif
sudo ./script.sh

# Paquets de base seulement
sudo ./script.sh --base

# Paquets AUR seulement
sudo ./script.sh --aur-only

# Paquets de base + XFCE
sudo ./script.sh --xfce

# Paquets de base + XFCE + AUR
sudo ./script.sh --xfce --aur