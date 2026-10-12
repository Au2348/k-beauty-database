-- =====================================================
-- TABLES
-- =====================================================

-- 1. Marques
CREATE TABLE marques (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(100) NOT NULL UNIQUE,
    pays_origine VARCHAR(100) NOT NULL
);

-- 2. Produits
CREATE TABLE produits (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    marque_id INTEGER NOT NULL REFERENCES marques(id),
    nom VARCHAR(150) NOT NULL,
    categorie VARCHAR(80) NOT NULL,
    prix NUMERIC(10, 2) NOT NULL CHECK (prix >= 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0)
);

-- 3. Ingrédients
CREATE TABLE ingredients (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(120) NOT NULL UNIQUE,
    fonction VARCHAR(200)
);

-- 4. Relation produits <-> ingrédients
CREATE TABLE produits_ingredients (
    produit_id INTEGER NOT NULL REFERENCES produits(id),
    ingredient_id INTEGER NOT NULL REFERENCES ingredients(id),
    concentration NUMERIC(5, 2)
        CHECK (concentration IS NULL OR concentration >= 0),
    PRIMARY KEY (produit_id, ingredient_id)
);

-- 5. Clients
CREATE TABLE clients (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(120) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE
);

-- 6. Commandes
CREATE TABLE commandes (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id INTEGER NOT NULL REFERENCES clients(id),
    date_commande TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(30) NOT NULL DEFAULT 'en_attente'
        CHECK (statut IN ('en_attente', 'payee', 'expediee', 'livree', 'annulee'))
);

-- 7. Détails des commandes
CREATE TABLE details_commande (
    commande_id INTEGER NOT NULL REFERENCES commandes(id),
    produit_id INTEGER NOT NULL REFERENCES produits(id),
    quantite INTEGER NOT NULL CHECK (quantite > 0),
    prix_unitaire NUMERIC(10, 2) NOT NULL CHECK (prix_unitaire >= 0),
    PRIMARY KEY (commande_id, produit_id)
);


-- =====================================================
-- INSERTION DES DONNEES DE TEST
-- =====================================================

-- MARQUES
INSERT INTO marques (nom, pays_origine) VALUES
('COSRX', 'Coree du Sud'),
('Beauty of Joseon', 'Coree du Sud'),
('Anua', 'Coree du Sud'),
('SKIN1004', 'Coree du Sud');

-- INGREDIENTS
INSERT INTO ingredients (nom, fonction) VALUES
('Niacinamide', 'Soin de la peau'),
('Acide hyaluronique', 'Hydratation'),
('Centella asiatica', 'Apaisement'),
('Riz', 'Ingredient cosmetique'),
('Mucine d escargot', 'Ingredient cosmetique');

-- CLIENTS
INSERT INTO clients (nom, email) VALUES
('Camille Martin', 'camille@example.com'),
('Alex Bernard', 'alex@example.com'),
('Sarah Petit', 'sarah@example.com');


-- PRODUITS
INSERT INTO produits (marque_id, nom, categorie, prix, stock) VALUES
(1, 'Advanced Snail 96 Mucin Essence', 'Essence', 22.90, 50),
(1, 'Low pH Good Morning Gel Cleanser', 'Nettoyant', 12.50, 40),
(2, 'Glow Serum', 'Serum', 17.90, 35),
(2, 'Relief Sun', 'Protection solaire', 18.90, 60),
(3, 'Heartleaf 77 Soothing Toner', 'Toner', 21.00, 30),
(4, 'Centella Ampoule', 'Serum', 19.90, 45);

-- ASSOCIATION ENTRE PRODUITS ET INGREDIENTS
INSERT INTO produits_ingredients
    (produit_id, ingredient_id, concentration)
VALUES
(1, 5, NULL),
(3, 1, NULL),
(3, 4, NULL),
(5, 3, NULL),
(6, 3, NULL);


-- COMMANDES
INSERT INTO commandes (client_id, statut) VALUES
(1, 'payee'),
(2, 'en_attente'),
(3, 'expediee');

-- DETAILS DES COMMANDES
INSERT INTO details_commande
    (commande_id, produit_id, quantite, prix_unitaire)
VALUES
(1, 1, 2, 22.90),
(1, 3, 1, 17.90),
(2, 2, 1, 12.50),
(3, 5, 2, 21.00);


-- =====================================================
-- GENERATION DE 10 000 COMMANDES SUPPLEMENTAIRES
-- =====================================================

INSERT INTO commandes (client_id, date_commande, statut)
SELECT
    1 + (i % 3),
    TIMESTAMP '2026-01-01 10:00:00'
        + (i % 365) * INTERVAL '1 day',
    CASE
        WHEN i % 4 = 0 THEN 'payee'
        WHEN i % 4 = 1 THEN 'expediee'
        WHEN i % 4 = 2 THEN 'livree'
        ELSE 'en_attente'
    END
FROM generate_series(1, 10000) AS i;


-- GENERATION DES DETAILS DE COMMANDE

INSERT INTO details_commande
    (commande_id, produit_id, quantite, prix_unitaire)
SELECT
    c.id,
    1 + ((c.id - 1) % 6),
    1 + (c.id % 3),
    p.prix
FROM commandes c
JOIN produits p
    ON p.id = 1 + ((c.id - 1) % 6)
WHERE c.id > 3;