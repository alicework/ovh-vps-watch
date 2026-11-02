#!/usr/bin/env bash
# Surveille le stock Linux d'un modèle de VPS OVH dans les datacenters français
# et tient une issue ouverte tant qu'il est commandable : l'ouverture notifie,
# la fermeture au retour en rupture réarme l'alerte pour le réapprovisionnement
# suivant.
set -euo pipefail

PLAN_CODE="${PLAN_CODE:-vps-2027-model2}"
# Codes de l'API (champ `code`) : Gravelines, Roubaix, Strasbourg, Paris.
DATACENTERS="${DATACENTERS:-eu-west-gra eu-west-rbx eu-west-sbg eu-west-par}"
LABEL="${LABEL:-stock-disponible}"
API="https://eu.api.ovh.com/v1/vps/order/rule/datacenter?ovhSubsidiary=FR&planCode=${PLAN_CODE}"
CONFIGURATOR="https://www.ovhcloud.com/fr/vps/configurator/?planCode=${PLAN_CODE}"

# Une panne passagère de l'API ne doit pas faire échouer le job toutes les
# dix minutes : on attend le passage suivant.
if ! body=$(curl -fsS --retry 3 --retry-all-errors --max-time 20 "$API"); then
  echo "::warning::API OVH injoignable, nouvel essai au prochain passage"
  exit 0
fi

# Un changement de format, lui, est durable : le job échoue pour qu'on le voie.
if ! jq -e '.datacenters | type == "array"' <<<"$body" >/dev/null; then
  echo "::error::Réponse inattendue de l'API OVH : $body"
  exit 1
fi

jq -r '.datacenters[] | "\(.code)\tlinux=\(.linuxStatus)\twindows=\(.windowsStatus)"' <<<"$body"

# `linuxStatus` et non `status` : ce dernier vaut `available` dès que la
# variante Windows (licence payante) est en stock.
available=$(jq -r --arg dcs "$DATACENTERS" '
  ($dcs | split(" ")) as $wanted
  | .datacenters[]
  | select((.code | IN($wanted[])) and .linuxStatus == "available")
  | .code' <<<"$body")

open_issue=$(gh issue list --label "$LABEL" --state open --json number --jq '.[0].number // empty')

if [[ -n "$available" ]]; then
  if [[ -z "$open_issue" ]]; then
    gh label create "$LABEL" --color 2ea44f --force >/dev/null
    gh issue create \
      --title "${PLAN_CODE} disponible sous Linux : ${available//$'\n'/, }" \
      --label "$LABEL" \
      --assignee "$NOTIFY_USER" \
      --body "@${NOTIFY_USER} stock Linux constaté le $(date -u '+%d/%m/%Y à %H:%M UTC') dans : ${available//$'\n'/, }.

Commander : ${CONFIGURATOR}

Cette issue se ferme d'elle-même au retour en rupture."
  fi
elif [[ -n "$open_issue" ]]; then
  gh issue close "$open_issue" --comment "De nouveau en rupture le $(date -u '+%d/%m/%Y à %H:%M UTC')."
fi
