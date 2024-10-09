# EndeavourOS

La première étape sera de changer le nombre de téléchargement parallèles de Pacman. Pour faire ce changement il faut éditer le fichier de configuration de Pacman.

sudo nano /etc/pacman.conf

À la ligne ParallelDownloads = , il faut changer le chiffre pour le nombre souhaité.

*******************

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

*******************

Le script activation-service.sh, active les services systemd sur le système.

Explication :

systemctl is-enabled --quiet : Vérifie si un service est activé sans afficher de message. Le --quiet permet de ne pas afficher de sortie, et la commande renvoie simplement un code de sortie (0 si activé, 1 sinon).

systemctl is-active --quiet : Vérifie si le service est en cours d'exécution de manière similaire.

Avec ce script, tu t'assures de ne pas activer ou démarrer des services déjà en état actif, ce qui permet d'éviter des actions redondantes.

*******************

Le script ajout_repo_arco.sh, ajout le repo de Arcolinux pour avoir accès aux ArcoLinux Spices Application.

Application à installer:

- ArcoLinux Tweak Tool
- Sofirem
