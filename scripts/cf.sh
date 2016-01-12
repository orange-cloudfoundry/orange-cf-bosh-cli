#!/bin/bash
# This script should be placed in /etc/profile.d
# It define default CF values

CF_COLOR=true
CF_HOME=${HOME}/.cf
CF_PLUGIN_HOME=${HOME}_non_persistent_storage/cf_plugins
# CF_STAGING_TIMEOUT=15              Temps d'attente maximum pour le chargement de buildpack, en minutes
# CF_STARTUP_TIMEOUT=5               Temps d'attente maximum pour le démarrage d'instance, en minutes
# CF_TRACE=true                      API d'impression de diagnostic sur stdout
# CF_TRACE=path/to/trace.log         Ajouter les diagnostiques de la requête d'API à un fichier de logs
