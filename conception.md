# 🧴🌾🧴Conception de la base de données K-Beauty🧴🌾🧴◝(ᵔᗜᵔ)◜

## 1. Objectifִֶָ𓂃 ࣪ ִֶָ🐇་༘࿐

Créer une base de données PostgreSQL pour gérer une boutique de cosmétiques coréens.

## 2. Tables prévues✮⋆˙

### marques⋆✴︎˚｡⋆

Contient les marques de cosmétiques commercialisées.

* id : identifiant unique
* nom : nom de la marque
* pays_origine : pays d'origine

### produits⋆✴︎˚｡⋆

Contient les produits du catalogue.

* id : identifiant unique
* marque_id : marque du produit
* nom : nom du produit
* categorie : type de cosmétique
* prix : prix de vente
* stock : quantité disponible

### ingredients⋆✴︎˚｡⋆

Contient les ingrédients utilisés dans les cosmétiques.

* id : identifiant unique
* nom : nom de l'ingrédient
* fonction : fonction cosmétique déclarée

### produits_ingredients⋆✴︎˚｡⋆

Relie les produits aux ingrédients.

* produit_id : identifiant du produit
* ingredient_id : identifiant de l'ingrédient
* concentration : concentration, si connue

### clients⋆✴︎˚｡⋆

Contient les clients de la boutique.

* id : identifiant unique
* nom : nom du client
* email : adresse e-mail unique

### commandes⋆✴︎˚｡⋆

Contient les commandes passées par les clients.

* id : identifiant unique
* client_id : client ayant passé la commande
* date_commande : date de la commande
* statut : état de la commande

### details_commande⋆✴︎˚｡⋆

Contient les produits et les quantités associés à chaque commande.

* commande_id : identifiant de la commande
* produit_id : identifiant du produit
* quantite : quantité commandée
* prix_unitaire : prix du produit au moment de la commande

## 3. Relations✮⋆˙

* Une marque possède plusieurs produits.
* Un produit peut contenir plusieurs ingrédients.
* Un ingrédient peut être présent dans plusieurs produits.
* Un client peut passer plusieurs commandes.
* Une commande peut contenir plusieurs produits.
* Un produit peut apparaître dans plusieurs commandes.

## 4. Règles métier envisagées✮⋆˙

* Le prix et la quantité en stock ne peuvent pas être négatifs.
* Une commande doit appartenir à un client existant.
* Une commande ne peut pas être réalisée si le stock est insuffisant.
* Le total d'une commande est calculé à partir des détails de commande.

## 5. Fonctionnalités SQL avancées prévues✮⋆˙

* Une fonction ou procédure de calcul du total d'une commande.
* Un trigger pour contrôler le stock.
* Deux rôles métiers aux permissions différentes.
* Une vue adaptée à chaque rôle.
* Deux index avec mesure des performances avant et après leur création.
* Au moins 10 000 lignes dans la plus grosse table.
