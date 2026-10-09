# # 💮💮💮💮💮 K-Beauty Database 💮💮💮💮💮

##🌺 Présentation du projet

Ce projet consiste à concevoir une base de données PostgreSQL pour une boutique spécialisée dans les cosmétiques coréens (K-Beauty).

La base permettra de gérer les marques, les produits, les ingrédients, les clients et les commandes. Elle devra garantir la cohérence des données, sécuriser les accès et optimiser les performances des requêtes.

## 🌺Objectifs

* Concevoir des tables relationnelles avec des clés primaires et étrangères.
* Gérer les produits, les stocks et les commandes.
* Créer une fonction ou procédure PostgreSQL.
* Ajouter un trigger pour faire respecter une règle métier.
* Mettre en place deux rôles avec des permissions différentes.
* Créer une vue adaptée à chaque rôle.
* Créer deux index et mesurer les performances avant et après leur création.
* Générer au moins 10 000 lignes de données dans une table.

## 🌺Modèle de données prévu

* `marques` : informations sur les marques.
* `produits` : catalogue des cosmétiques.
* `ingredients` : ingrédients présents dans les produits.
* `produits_ingredients` : relation entre les produits et leurs ingrédients.
* `clients` : informations sur les clients.
* `commandes` : commandes passées par les clients.
* `details_commande` : produits et quantités de chaque commande.

## 🌺Règles métier envisagées

* Calculer le montant total d'une commande.
* Empêcher une commande lorsque le stock disponible est insuffisant.
* Séparer les permissions du gestionnaire du catalogue et du service client.

## 🌺Technologies

* PostgreSQL
* SQL
* GitHub

## 🌺État du projet

Projet en cours de conception. Le modèle de données, les fonctionnalités SQL et les tests seront complétés progressivement.
