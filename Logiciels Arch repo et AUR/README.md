Pour installer des applications à partir des répertoires Arch (officiels) et AUR (Arch User Repository), un script bash peut automatiser le processus en utilisant le

gestionnaire de paquets Pacman (pour les dépôts officiels) et un outil comme yay (pour AUR).

Voici un script simple pour installer des paquets à partir des deux sources :

Étapes préalables :

Pacman est déjà installé sur Arch Linux pour gérer les paquets du dépôt officiel.

Vous devez installer un gestionnaire AUR. L'un des plus populaires est yay, que nous installerons dans le script.


*******************


Explication du script :

Mise à jour du système : Le script commence par une mise à jour complète du système avec pacman -Syu.

Installation de yay : Si yay n'est pas déjà installé, le script le télécharge et l'installe.

Installation des applications :

Les applications des dépôts officiels Arch sont installées avec pacman.

Les applications de AUR sont installées via yay.

Nettoyage : Le répertoire cloné pour installer yay est supprimé après l'installation.


*******************


Instructions :

Copiez le script ci-dessus dans un fichier (par exemple, installation_paquets_officiel_aur.sh).

Rendez-le exécutable avec la commande :

chmod +x installation_paquets_officiel_aur.sh

Exécutez-le avec :

./installation_paquets_officiel_aur.sh

Ce script automatisera l'installation des paquets à partir des dépôts Arch et AUR.