# EndeavourOS
Script installation logiciels et services.

Le script installation_paquets.sh, installes des paquets en provenance du répertoire Arch principal.

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

*******************

Le script installation_paquets_aur.sh, installes des paquets en provenance du répertoire AUR.

Instructions :
Dans la ligne package_list, remplacez "package1" "package2" "package3" par les noms des paquets que vous souhaitez installer :
package_list=("package1" "package2" "package3")

Par exemple, si vous souhaitez installer spotify, visual-studio-code-bin, et slack-desktop, la ligne deviendra :

package_list=("spotify" "visual-studio-code-bin" "slack-desktop")


Instructions :
SCrée un fichier avec le script ci-dessus, par exemple : installation_paquets_aur.sh

Donnez-lui les permissions d'exécution :

chmod +x installation_paquets_aur.sh

Exécutez le script :

./installation_paquets_aur.sh

Le script installera automatiquement les paquets spécifiés dans la variable package_list.
