Explication du script :

Vérification des privilèges : Le script commence par vérifier qu'il est exécuté avec les privilèges root (via sudo).

Mise à jour du système : Le script effectue une mise à jour du système avant l'installation des nouveaux paquets.

Installation de systemd-swap : Ce paquet est nécessaire pour configurer ZRAM. Il est installé via pacman.

Configuration de ZRAM : Le fichier de configuration /etc/systemd/swap.conf est modifié pour activer ZRAM et configurer sa taille comme étant 50% de la RAM disponible. L'algorithme zstd est choisi pour la compression car il est rapide et efficace.

Activation de systemd-swap : Le service systemd-swap est activé et démarré pour appliquer la configuration de ZRAM.

Vérification du service : Le script affiche le statut du service pour s'assurer que ZRAM est bien activé et fonctionne correctement.

Utilisation du script :

Copiez le script dans un fichier, par exemple installation_configuration_zram.sh.

Rendez le script exécutable :


chmod +x installation_configuration_zram.sh
Exécutez le script avec les privilèges root :


sudo ./installation_configuration_zram.sh

Le script s'occupera de tout : installation, configuration et activation de ZRAM sur votre système EndeavourOS.