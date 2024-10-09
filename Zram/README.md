Explication du script :

Mise à jour du système : Le script commence par mettre à jour votre système pour garantir que tous les paquets sont à jour.

Installation de ZRAM : Le paquet zram-generator est installé pour permettre la configuration de ZRAM via systemd.

Configuration de ZRAM :

Le script crée un fichier de configuration pour ZRAM dans /etc/systemd/zram-generator.conf.d/.

La taille de ZRAM est définie à 50% de la RAM disponible.

L'algorithme de compression lz4 est utilisé pour de bonnes performances.

La priorité de swap est définie sur 100, ce qui donne à ZRAM la plus haute priorité.

************

Activation du swap traditionnel :

Si un swap traditionnel n'est pas déjà actif, il est activé (en supposant que vous avez une partition swap existante).

Vous devez remplacer /dev/sdX par la bonne partition de swap sur votre système (par exemple /dev/sda2).

Ajustement de la priorité de swap :

Le script s'assure que la priorité du swap traditionnel est définie à une valeur plus faible (50 dans l'exemple), afin que ZRAM soit utilisé en priorité.

Vérification de l'état du swap :

Le script affiche l'état du swap actif à la fin pour confirmer que tout est configuré correctement.

************

Comment utiliser ce script :

Sauvegardez ce script dans un fichier, par exemple installation_configuration_zram.sh.

Rendez-le exécutable avec la commande : chmod +x installation_configuration_zram.sh.

Exécutez-le avec sudo ./installation_configuration_zram.sh.

Personnalisation :

Vous pouvez ajuster la taille de ZRAM (par exemple, size = 70% ou size = 8G si vous préférez une taille fixe).

Changez la priorité du swap traditionnel selon vos besoins (par exemple, en définissant priority = 50 pour une faible priorité).

Avec ce script, ZRAM sera utilisé en priorité, et le swap traditionnel sur disque ne sera activé que si ZRAM n'est pas suffisant.
