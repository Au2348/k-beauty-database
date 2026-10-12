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