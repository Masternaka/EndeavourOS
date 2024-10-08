# EndeavourOS
Script installation logiciels et services

Instructions :
Crée un fichier avec le script ci-dessus, par exemple :

nano installation_paquets.sh

Rends le fichier exécutable :

chmod +x installation_paquets.sh

Exécute le script avec les droits root :

sudo ./installation_paquets.sh

Explications :
Le script commence par vérifier que l'utilisateur a les droits root.
Il met ensuite à jour les dépôts et les paquets système (pacman -Syu).
Ensuite, il installe les paquets spécifiés dans la liste pacman_packages si ceux-ci ne sont pas déjà installés.
