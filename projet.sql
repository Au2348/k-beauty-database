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
-- DONNEES
-- On remplit d'abord les tables référencées,
-- puis celles qui pointent vers elles.
-- =====================================================

-- Marques (ids 1 à 5)
INSERT INTO marques (nom, pays_origine) VALUES
    ('COSRX', 'Corée du Sud'),
    ('Beauty of Joseon', 'Corée du Sud'),
    ('Anua', 'Corée du Sud'),
    ('Innisfree', 'Corée du Sud'),
    ('Laneige', 'Corée du Sud');

-- Ingrédients (ids 1 à 8)
INSERT INTO ingredients (nom, fonction) VALUES
    ('Niacinamide', 'Uniformise le teint'),
    ('Acide hyaluronique', 'Hydrate'),
    ('Centella asiatica', 'Apaise'),
    ('Mucine d''escargot', 'Répare et hydrate'),
    ('Propolis', 'Nourrit et apaise'),
    ('Thé vert', 'Antioxydant'),
    ('Rétinol', 'Anti-âge'),
    ('Extrait de riz', 'Éclat et douceur');

-- Produits (ids 1 à 20), 500 en stock chacun
-- Les prix sont fictifs, ce n'est pas grave pour le projet.
INSERT INTO produits (marque_id, nom, categorie, prix, stock) VALUES
    (1, 'Advanced Snail 96 Mucin Power Essence', 'essence', 21.00, 500),
    (1, 'Low pH Good Morning Gel Cleanser', 'nettoyant', 12.00, 500),
    (1, 'BHA Blackhead Power Liquid', 'exfoliant', 25.00, 500),
    (1, 'Aloe Soothing Sun Cream', 'solaire', 15.00, 500),
    (2, 'Glow Serum Propolis + Niacinamide', 'sérum', 17.00, 500),
    (2, 'Relief Sun Rice + Probiotics', 'solaire', 16.00, 500),
    (2, 'Dynasty Cream', 'crème', 28.00, 500),
    (2, 'Green Plum Refreshing Cleanser', 'nettoyant', 14.00, 500),
    (3, 'Heartleaf 77% Soothing Toner', 'tonique', 22.00, 500),
    (3, 'Heartleaf Pore Control Cleansing Oil', 'nettoyant', 20.00, 500),
    (3, 'Niacinamide 10% + TXA 4% Serum', 'sérum', 24.00, 500),
    (3, 'Rice 70 Glow Milky Toner', 'tonique', 23.00, 500),
    (4, 'Green Tea Seed Serum', 'sérum', 28.00, 500),
    (4, 'Daily UV Protection Cream', 'solaire', 13.00, 500),
    (4, 'Jeju Volcanic Pore Clay Mask', 'masque', 15.00, 500),
    (4, 'Retinol Cica Moisture Barrier Cream', 'crème', 26.00, 500),
    (5, 'Water Sleeping Mask', 'masque', 29.00, 500),
    (5, 'Cream Skin Refiner', 'tonique', 32.00, 500),
    (5, 'Lip Sleeping Mask', 'soin lèvres', 24.00, 500),
    (5, 'Water Bank Blue Hyaluronic Cream', 'crème', 35.00, 500);

-- Produits <-> ingrédients (quelques exemples)
INSERT INTO produits_ingredients (produit_id, ingredient_id, concentration) VALUES
    (1, 4, 96.00),
    (5, 5, 60.00),
    (5, 1, 2.00),
    (11, 1, 10.00),
    (12, 8, 70.00),
    (13, 6, NULL),
    (16, 7, NULL),
    (16, 3, NULL),
    (20, 2, NULL);

-- Clients : 100 clients générés
INSERT INTO clients (nom, email)
SELECT 'Client ' || i,
       'client' || i || '@example.com'
FROM generate_series(1, 100) AS i;

-- Commandes : 10 000 commandes générées
INSERT INTO commandes (client_id, date_commande, statut)
SELECT 1 + (i % 100),
       timestamp '2026-01-01' + (i % 300) * interval '1 day',
       (ARRAY['en_attente','payee','expediee','livree','annulee'])[1 + (i % 5)]
FROM generate_series(1, 10000) AS i;

-- Détails : 2 produits différents par commande = 20 000 lignes
INSERT INTO details_commande (commande_id, produit_id, quantite, prix_unitaire)
SELECT i, p.id, 1 + (i % 3), p.prix
FROM generate_series(1, 10000) AS i
JOIN produits p ON p.id = 1 + (i % 20);

INSERT INTO details_commande (commande_id, produit_id, quantite, prix_unitaire)
SELECT i, p.id, 1 + (i % 3), p.prix
FROM generate_series(1, 10000) AS i
JOIN produits p ON p.id = 1 + ((i + 7) % 20);