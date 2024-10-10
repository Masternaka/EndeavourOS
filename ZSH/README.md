Explication des étapes pour Arch Linux :

Vérification de l'utilisateur root : Le script doit être exécuté avec les droits d'administrateur (root).

Installation de Zsh : Utilisation de pacman, le gestionnaire de paquets d'Arch, pour installer zsh, curl, et git.

Définir Zsh comme shell par défaut : Cette commande utilise chsh pour définir Zsh comme shell par défaut.

Installation de Zinit : Zinit est téléchargé et installé à l'aide d'un script curl.

Configuration des plugins : Les mêmes plugins populaires que ceux mentionnés dans le script précédent pour Ubuntu sont installés :

fast-syntax-highlighting : colorisation des commandes.

zsh-autosuggestions : suggestions automatiques basées sur l'historique.

zsh-completions : améliore les complétions automatiques.

zsh-history-substring-search : permet la recherche dans l'historique.

Thème Agnoster : Un thème visuel apprécié pour Zsh.

Alias et options Zsh : Quelques alias pratiques et options pour améliorer l'utilisation de Zsh.

Finalisation : Après l'installation, le script te recommande de redémarrer ton terminal ou de relancer Zsh via exec zsh.

Exécution du script :

Sauvegarde le script dans un fichier (par exemple, installation_zsh_zinit_p10k_arch.sh), rends-le exécutable et exécute-le avec les droits administrateur :

chmod +x installation_zsh_zinit_p10k_arch.sh

sudo ./installation_zsh_zinit_p10k_arch.sh

Cela installera Zsh, Zinit et configurera les plugins. Après avoir exécuté le script, n'oublie pas de redémarrer ton terminal ou de lancer exec zsh pour utiliser immédiatement Zsh.

********************

Modifications importantes pour Powerlevel10k :

Installation de Powerlevel10k : Le thème Powerlevel10k est installé via Zinit avec la commande zinit light romkatv/powerlevel10k.

Chargement de la configuration Powerlevel10k : Une vérification est effectuée pour charger la configuration existante de Powerlevel10k via le fichier ~/.p10k.zsh, qui sera créé lors de la première configuration.

Lancement automatique de la configuration Powerlevel10k : Après l'installation, la commande p10k configure est lancée automatiquement pour te permettre de configurer Powerlevel10k (choisir les couleurs, la disposition du prompt, etc.).

Exécution du script :

Sauvegarde ce script dans un fichier (par exemple, installation_zsh_zinit_p10k_arch.sh), rends-le exécutable et exécute-le avec les droits administrateur :

chmod +x installation_zsh_zinit_p10k_arch.sh

sudo ./installation_zsh_zinit_p10k_arch.sh

Lancement de la configuration Powerlevel10k :

À la fin de l'installation, la commande p10k configure sera automatiquement exécutée pour te guider à travers la configuration du thème Powerlevel10k. C'est là que tu pourras choisir ton style de prompt, les symboles, les couleurs, etc.

Après avoir finalisé la configuration, Powerlevel10k sera activé dans Zsh, et tu auras un prompt élégant et performant.