Si vous avez un swap traditionnel basé sur une partition plutôt que sur un fichier, voici comment configurer zram avec zram-generator tout en conservant la partition de swap existante.

1. Installer zram-generator
Installez zram-generator si ce n'est pas déjà fait :

sudo pacman -S zram-generator
2. Identifier la partition de swap existante
Pour trouver votre partition de swap actuelle, utilisez la commande suivante :

sudo swapon --show
Cela affichera une liste des dispositifs de swap actifs, incluant probablement une partition telle que /dev/sdX ou /dev/nvmeXn1pX. Prenez note de cette partition.

3. Configurer zram-generator
Créez ou modifiez le fichier de configuration de zram-generator :

sudo nano /etc/systemd/zram-generator.conf
Ajoutez la configuration suivante pour créer un périphérique zram :

[zram0]
zram-size = 8192
compression-algorithm = zstd
zram-size : Configurez la taille de la zram. Ici, nous avons choisi 8 Go pour une machine avec 16 Go de RAM. Ajustez selon vos besoins (50 % de la RAM est généralement un bon point de départ).
compression-algorithm : Utilisez zstd pour un bon compromis entre vitesse et taux de compression. Vous pouvez aussi utiliser lz4 pour une compression plus rapide avec un ratio légèrement plus faible.

4. Activer et redémarrer
Redémarrez votre système pour que les nouvelles configurations prennent effet :

sudo reboot
5. Vérifier la configuration
Une fois le système redémarré, vous pouvez vérifier que la zram et la partition de swap traditionnelle fonctionnent ensemble.

Vérifiez que les deux dispositifs de swap (la zram et la partition de swap) sont actifs :

swapon --show
Vous devriez voir deux lignes, l'une pour votre partition de swap (par exemple /dev/sdX) et l'autre pour zram (/dev/zram0).

Vérifiez également la configuration dans /proc/swaps :

cat /proc/swaps
Cela affichera une liste des dispositifs de swap actifs, y compris la partition traditionnelle et la zram.

6. Ajuster la priorité du swap
Si vous souhaitez que le système utilise d'abord la zram avant de recourir à la partition de swap, ajustez la priorité dans la configuration.

Ouvrez le fichier de configuration de zram-generator :

sudo nano /etc/systemd/zram-generator.conf
Ajoutez la ligne swap-priority pour donner une priorité plus élevée à la zram :

[zram0]
zram-size = 8192
compression-algorithm = zstd
swap-priority = 100
Ensuite, vérifiez la priorité de votre partition de swap dans /etc/fstab. Par exemple, la ligne pour votre partition de swap pourrait ressembler à ceci :

/dev/sdX none swap defaults,pri=5 0 0
Cela donne une priorité plus élevée à la zram, donc elle sera utilisée avant la partition de swap.


La priorité du swap traditionnel (qu'il s'agisse d'une partition ou d'un fichier) dépend des valeurs que vous définissez dans le fichier /etc/fstab ou via d'autres mécanismes de configuration du swap.

Priorité par défaut du swap traditionnel
Si vous n'avez pas explicitement défini une priorité pour votre swap traditionnel, il utilisera la priorité par défaut, qui est -1. Cette valeur est automatiquement assignée par le système s'il n'y a pas de réglage manuel.

Comment vérifier la priorité actuelle du swap
Pour voir la priorité de vos dispositifs de swap actuels (zram et swap traditionnel), utilisez la commande suivante :

cat /proc/swaps
Cela vous montrera une sortie ressemblant à ceci :

Filename                Type        Size    Used    Priority
/dev/sdX                partition   8388608 0       -1
/dev/zram0              partition   8388608 0       100
Dans cet exemple :

La partition de swap traditionnelle a une priorité de -1.
La zram a une priorité de 100.
Ajuster la priorité du swap traditionnel
Pour définir une priorité spécifique pour le swap traditionnel, vous pouvez modifier votre fichier /etc/fstab et ajouter l'option pri= pour lui assigner une priorité spécifique.

Exemple avec une partition de swap :
Ouvrez /etc/fstab :

sudo nano /etc/fstab
Ajoutez ou modifiez la ligne correspondant à votre partition de swap en incluant pri=5 (ou une autre valeur de votre choix) :

/dev/sdX none swap defaults,pri=5 0 0
Ici, /dev/sdX est votre partition de swap (vérifiez ce que montre la commande swapon --show pour l'identifier).
pri=5 définit la priorité à 5, qui est inférieure à celle de la zram (qui est définie à 100 dans notre exemple).
Exemple avec une partition de swap déjà activée
Si votre swap est déjà activé et vous souhaitez ajuster la priorité sans redémarrer, vous pouvez utiliser la commande suivante :

sudo swapoff /dev/sdX
sudo swapon /dev/sdX --priority 5
Cela définira la priorité du swap pour la session en cours sans modifier le fichier /etc/fstab.

Résultat final attendu
Avec cette configuration, la priorité de la zram est plus élevée que celle de la partition de swap traditionnelle. Le système utilisera donc la zram en premier lieu pour le swap, et passera à la partition de swap traditionnelle seulement si la zram est pleine.

Priorités possibles :

zram : priorité définie à 100.
Partition de swap : priorité définie à 5 (ou une autre valeur inférieure à celle de la zram).
Cela garantit une utilisation optimale de la zram avant d'utiliser la partition de swap plus lente.
