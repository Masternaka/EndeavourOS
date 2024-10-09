Explication du script :

Vérification des privilèges : Le script commence par vérifier qu'il est exécuté avec les privilèges root (via sudo).

Mise à jour du système : Le script effectue une mise à jour du système avant l'installation des nouveaux paquets.

Installation de systemd-swap : Ce paquet est nécessaire pour configurer ZSWAP. Il est installé via pacman.

Configuration de ZSWAP : Le fichier de configuration /etc/systemd/swap.conf est modifié pour activer ZSWAP et le configurer avec une taille équivalente à 50% de la RAM disponible. La compression zstd est choisie car elle est rapide et efficace.

Activation de systemd-swap : Le service systemd-swap est activé et démarré pour appliquer la configuration.

Vérification du service : Enfin, le script affiche le statut du service pour s'assurer que ZSWAP est bien activé et fonctionne correctement.

Utilisation du script :
Copiez le script dans un fichier, par exemple installation_configuration_zswap.sh.

Rendez le script exécutable :

chmod +x installation_configuration_zswap.sh

Exécutez le script avec les privilèges root :

sudo ./installation_configuration_zswap.sh

Le script s'occupera de tout : installation, configuration et activation de ZSWAP sur votre système EndeavourOS.
