# ovh-vps-watch

Alerte de réapprovisionnement des VPS-2 et VPS-3 OVH (gamme 2027) dans les
datacenters français.

Toutes les dix minutes, le workflow interroge pour chaque modèle l'API publique
d'OVH, sans authentification. La liste des modèles est la matrice `plan_code`
du workflow :

```
GET https://eu.api.ovh.com/v1/vps/order/rule/datacenter?ovhSubsidiary=FR&planCode=vps-2027-model2
```

Dès que `linuxStatus` passe à `available` à Gravelines, Roubaix, Strasbourg ou
Paris, une issue étiquetée `stock-<planCode>` est ouverte et assignée au
propriétaire du dépôt, ce qui déclenche la notification GitHub (mail et mobile).
Elle se ferme d'elle-même au retour en rupture, pour réarmer l'alerte.

Réglages (variables d'environnement de `watch.sh`) : `PLAN_CODE`, `DATACENTERS`
(codes séparés par des espaces), `LABEL`. Le lancement manuel (onglet Actions,
« Run workflow ») accepte un `plan_code` et des `datacenters` : utile pour
vérifier un autre modèle, ou tester l'alerte sur un stock existant. Les codes
valides se lisent dans la réponse de l'API.

## À savoir

- Le dépôt est public pour que les exécutions ne consomment pas les minutes
  Actions du compte ; le script ne contient aucun secret.
- GitHub **désactive les workflows planifiés d'un dépôt public après 60 jours
  sans activité** (un mail prévient avant) : le réactiver depuis l'onglet Actions.
