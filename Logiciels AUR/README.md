# EndeavourOS

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
