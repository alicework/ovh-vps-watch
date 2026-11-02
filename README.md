# ovh-vps-watch

Alerte de réapprovisionnement d'un VPS OVH (par défaut le VPS-2 de la gamme 2027)
dans les datacenters français.

Toutes les dix minutes, le workflow interroge l'API publique d'OVH, sans
authentification :

```
GET https://eu.api.ovh.com/v1/vps/order/rule/datacenter?ovhSubsidiary=FR&planCode=vps-2027-model2
```

Dès que `linuxStatus` passe à `available` à Gravelines, Roubaix, Strasbourg ou
Paris, une issue étiquetée `stock-disponible` est ouverte et assignée au
propriétaire du dépôt, ce qui déclenche la notification GitHub (mail et mobile).
Elle se ferme d'elle-même au retour en rupture, pour réarmer l'alerte.

Réglages (variables d'environnement de `watch.sh`, à poser dans le workflow) :
`PLAN_CODE`, `DATACENTERS` (codes séparés par des espaces), `LABEL`.

## À savoir

- Le dépôt est public pour que les exécutions ne consomment pas les minutes
  Actions du compte ; le script ne contient aucun secret.
- GitHub **désactive les workflows planifiés d'un dépôt public après 60 jours
  sans activité** (un mail prévient avant) : le réactiver depuis l'onglet Actions.
- Lancement manuel : onglet Actions, « Run workflow ».
