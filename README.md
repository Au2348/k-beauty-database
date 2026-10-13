# K-Beauty Database

Projet de SQL avancé : une base PostgreSQL pour une boutique de cosmétiques coréens.
Elle gère le catalogue, les ingrédients, les clients, les commandes et les stocks.

## Fichiers

- `projet.sql` : tables, données, fonction, trigger, vues, rôles et index, dans l'ordre demandé.
- `docker-compose.yml` : PostgreSQL 17 en local, avec un volume persistant.
- `conception.md` : description des tables et de leurs relations.

## Démarrer et se connecter

Avec Docker Desktop démarré, depuis le dossier du projet :

```powershell
docker compose up -d
docker compose ps
```

Dans IntelliJ : **Database → + → Data Source → PostgreSQL**, puis **Test Connection**.

- Hôte : `localhost`
- Port : `15432`
- Base : `kbeauty_db`
- Utilisateur : `kbeauty_user`
- Mot de passe : valeur de `POSTGRES_PASSWORD`, ou `changeme` par défaut.

TablePlus utilise les mêmes paramètres. Le volume conserve les données entre les démarrages. Changer `POSTGRES_PASSWORD` ne change pas le mot de passe d'une base déjà initialisée.

Sur une base vide, ouvrir `projet.sql`, choisir cette connexion et exécuter tout le fichier. Docker ne l'importe pas automatiquement. Ne pas relancer le script entier sur des tables existantes.

Pour importer avec le terminal :

```powershell
docker compose cp projet.sql db:/tmp/projet.sql
docker compose exec db psql -U kbeauty_user -d kbeauty_db -v ON_ERROR_STOP=1 -f /tmp/projet.sql
```

## Tables et données

Les sept tables sont `marques`, `produits`, `ingredients`, `produits_ingredients`, `clients`, `commandes` et `details_commande`.
Les clés étrangères relient les marques aux produits, les produits aux ingrédients et les clients aux commandes et à leurs détails. Les contraintes protègent notamment les prix, les stocks, les quantités et les statuts.

Le script insère quatre marques, six produits, cinq ingrédients et trois clients fictifs. Il crée trois commandes de test, puis 10 000 commandes supplémentaires avec `generate_series` et leurs détails.

```sql
SELECT COUNT(*) AS nb_commandes FROM commandes;
SELECT COUNT(*) AS nb_details FROM details_commande;
```

Résultats attendus après un import sur base vide : **10 003 commandes** et **10 004 détails**. Les données sont chargées avant le trigger et ne décrémentent donc pas le stock initial.

## Fonction : total d'une commande

`total_commande(integer)` additionne les quantités multipliées par les prix unitaires des détails. Elle centralise le calcul et utilise le prix enregistré à la commande, indépendamment du prix actuel du catalogue. Sans détail correspondant, elle renvoie zéro.

```sql
SELECT total_commande(1) AS total;
```

Résultat attendu : **63,70**, soit deux produits à 22,90 et un à 17,90.

## Trigger : protection du stock

`trg_stock_details_commande` appelle `verifier_et_mettre_a_jour_stock()` avant chaque insertion d'un détail. Il verrouille le produit, refuse une quantité supérieure au stock et décrémente le stock si l'insertion réussit.
La règle est dans PostgreSQL pour s'appliquer depuis n'importe quel logiciel, notamment IntelliJ et TablePlus.

Preuve d'une insertion autorisée, sans conserver les changements :

```sql
BEGIN;
SELECT stock FROM produits WHERE id = 2;
INSERT INTO details_commande (commande_id, produit_id, quantite, prix_unitaire)
VALUES (1, 2, 1, 12.50);
SELECT stock FROM produits WHERE id = 2;
ROLLBACK;
```

Sur les données initiales, le stock passe de **40 à 39**, puis revient à 40 après le rollback.

Preuve d'un refus, à exécuter séparément :

```sql
BEGIN;
INSERT INTO details_commande (commande_id, produit_id, quantite, prix_unitaire)
VALUES (1, 2, 1000, 12.50);
```

Une erreur « Stock insuffisant » est attendue. Exécuter ensuite `ROLLBACK;` séparément pour terminer la transaction en erreur. Le stock reste inchangé.
Le trigger couvre uniquement les insertions : modifications, suppressions et annulations ne réajustent pas le stock.

## Vues, rôles et utilisateurs

Les droits sont accordés aux rôles métiers, puis les rôles aux utilisateurs. Le script n'accorde aucun accès direct aux tables à ces deux rôles.

- `role_vendeur`, attribué à `user_vendeur` : lecture, insertion et modification sur `v_vendeur_commandes`. La vue présente les identifiants, dates et statuts des commandes sans les e-mails.
- `role_controleur`, attribué à `user_controleur` : lecture de `v_controleur_ventes`. Elle présente le nombre de commandes et la somme des montants par statut, sans noms ni e-mails. Tous les statuts sont inclus ; cette somme n'est pas uniquement le montant encaissé.

Les mots de passe `vendeur_test` et `controleur_test` sont destinés à la démonstration locale.
Depuis la connexion administrateur, exécuter les requêtes suivantes une par une. Après un refus attendu, exécuter `RESET ROLE` séparément.

```sql
SET ROLE user_vendeur;
SELECT * FROM v_vendeur_commandes LIMIT 5; -- Autorisé.
UPDATE v_vendeur_commandes SET statut = 'payee' WHERE id = 1; -- Autorisé.
SELECT * FROM clients; -- Refusé.
RESET ROLE;

SET ROLE user_controleur;
SELECT * FROM v_controleur_ventes; -- Autorisé.
SELECT * FROM commandes; -- Refusé.
RESET ROLE;
```

L'insertion du vendeur reste à vérifier : la génération d'un identifiant peut nécessiter un droit sur la séquence d'identité. Le script accorde actuellement les droits sur la vue uniquement.

## Index : mesures avant et après

`idx_commandes_statut` vise les recherches par statut ; `idx_commandes_client_id` vise les commandes d'un client.
L'intérêt doit être démontré par les mesures. Avec trois clients et quatre statuts, PostgreSQL peut préférer un parcours séquentiel : un gain n'est pas garanti.

Sur une base locale de test, avec la connexion administrateur :

```sql
DROP INDEX IF EXISTS idx_commandes_statut;
DROP INDEX IF EXISTS idx_commandes_client_id;
ANALYZE commandes;

-- Avant : relever le plan et Execution Time.
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM commandes WHERE statut = 'payee';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM commandes WHERE client_id = 1;

CREATE INDEX idx_commandes_statut ON commandes(statut);
CREATE INDEX idx_commandes_client_id ON commandes(client_id);
ANALYZE commandes;

-- Après : mêmes requêtes et mêmes données.
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM commandes WHERE statut = 'payee';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM commandes WHERE client_id = 1;
```

Résultats mesurés sur 10 003 commandes :

- Statut : avant **0.480 ms** (Seq Scan), après **0.360 ms** (Bitmap Heap Scan via `idx_commandes_statut`). Gain d'environ 25 %. L'index est utilisé car seulement 4 valeurs de statut existent, ce qui rend le filtrage sélectif.
- Client : avant **0.435 ms** (Seq Scan), après **0.458 ms** (Bitmap Heap Scan via `idx_commandes_client_id`). Gain négligeable. Avec seulement 3 clients, chaque requête retourne environ un tiers de la table ; l'index est utilisé mais son surcoût de lecture compense le bénéfice.

## Tester sur une base vide

La base de validation permet de préserver `kbeauty_db`. Attention : ces commandes effacent l'éventuelle base `kbeauty_validation` et son contenu avant de la recréer.

```powershell
docker compose exec db psql -U kbeauty_user -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS kbeauty_validation WITH (FORCE)" -c "CREATE DATABASE kbeauty_validation"
docker compose cp projet.sql db:/tmp/projet.sql
docker compose exec db psql -U kbeauty_user -d kbeauty_validation -v ON_ERROR_STOP=1 -f /tmp/projet.sql
```

Le script doit terminer sans erreur. Exécuter ensuite les preuves sur `kbeauty_validation`.
Les rôles sont communs au serveur : le script vérifie leur existence avant de les créer.

## État et prochaines étapes

Les tables, données, fonction, trigger, vues, rôles, utilisateurs et index sont présents dans le script. Leur validation reste à effectuer :

- [ ] Tester le script complet sur une base vide.
- [ ] Exécuter les preuves de la fonction et du trigger.
- [ ] Vérifier les droits des utilisateurs, notamment l'insertion du vendeur.
- [ ] Mesurer les deux index avant et après et compléter les résultats.
- [ ] Compléter les noms des membres et leurs contributions.
- [ ] Répéter la démonstration et vérifier que le dépôt est public.

## Groupe et rendu

Membres et contributions à compléter : Aurélie, Patrick et autres membres éventuels.
Chaque membre commite son propre travail et doit pouvoir expliquer toutes les parties.

**Présentation : jeudi 15 octobre 2026**, huit minutes de démonstration et quatre minutes de questions, sans diaporama. Montrer dans l'ordre : un rôle avec une action autorisée et une refusée, une vue, un index avant/après et un trigger.

**Rendu : vendredi 16 octobre 2026 à 23 h 59.** Le dépôt GitHub public doit contenir `projet.sql` et `README.md`. Un membre dépose sur Moodle un fichier `.txt` avec le lien du dépôt et les prénoms et noms de tous les membres.
