Script d'installation et de configuration de Samba (avec des répertoires existants)

Explication des sections modifiées :

Suppression de la création de nouveaux répertoires : Le script ne crée pas de répertoire ; il vous demande de spécifier les chemins des répertoires existants que vous souhaitez partager.

Ajout de plusieurs répertoires : Après avoir demandé un répertoire et son nom de partage, le script vous demande si vous souhaitez en ajouter d'autres. Vous pouvez répéter l'opération pour 

partager plusieurs répertoires.

La configuration de chaque partage : Chaque répertoire est ajouté dans le fichier de configuration de Samba avec ses propres paramètres (browseable, writable, etc.).

Exécution du script :

Enregistrez ce script dans un fichier, par exemple installation_config_samba.sh.

Donnez-lui les droits d'exécution avec chmod +x installation_config_samba.sh.

Exécutez le script avec sudo ./installation_config_samba.sh.

Ce script permet de partager facilement plusieurs répertoires déjà existants sur votre système via Samba.