Le script activation-service.sh, active les services systemd sur le système.

Explication :

systemctl is-enabled --quiet : Vérifie si un service est activé sans afficher de message. Le --quiet permet de ne pas afficher de sortie, et la commande renvoie simplement un code de sortie (0 si activé, 1 sinon).

systemctl is-active --quiet : Vérifie si le service est en cours d'exécution de manière similaire.

Avec ce script, tu t'assures de ne pas activer ou démarrer des services déjà en état actif, ce qui permet d'éviter des actions redondantes.
