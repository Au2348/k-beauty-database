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

-- =====================================================
-- FONCTION : TOTAL D'UNE COMMANDE
-- =====================================================

CREATE OR REPLACE FUNCTION total_commande(p_commande_id INTEGER)
RETURNS NUMERIC(10, 2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(10, 2);
BEGIN
    SELECT COALESCE(SUM(quantite * prix_unitaire), 0)
    INTO v_total
    FROM details_commande
    WHERE commande_id = p_commande_id;

    RETURN v_total;
END;
$$;

-- =====================================================
-- TRIGGER : PROTECTION DU STOCK
-- =====================================================

CREATE OR REPLACE FUNCTION verifier_et_mettre_a_jour_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock INTEGER;
BEGIN
    SELECT stock INTO v_stock
    FROM produits
    WHERE id = NEW.produit_id
    FOR UPDATE;

    IF v_stock < NEW.quantite THEN
        RAISE EXCEPTION
            'Stock insuffisant pour le produit % : % disponible(s), % demande(s)',
            NEW.produit_id, v_stock, NEW.quantite;
    END IF;

    UPDATE produits
    SET stock = stock - NEW.quantite
    WHERE id = NEW.produit_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_stock_details_commande
BEFORE INSERT ON details_commande
FOR EACH ROW
EXECUTE FUNCTION verifier_et_mettre_a_jour_stock();


-- =====================================================
-- VUES
-- =====================================================

-- Vue du vendeur : voit et gère les commandes, sans accès aux emails des clients
CREATE OR REPLACE VIEW v_vendeur_commandes AS
SELECT id, client_id, date_commande, statut
FROM commandes;

-- Vue du contrôleur : chiffres globaux par statut, aucune donnée personnelle
CREATE OR REPLACE VIEW v_controleur_ventes AS
SELECT
    c.statut,
    COUNT(DISTINCT c.id) AS nb_commandes,
    COALESCE(SUM(d.quantite * d.prix_unitaire), 0) AS chiffre_affaires
FROM commandes c
LEFT JOIN details_commande d ON d.commande_id = c.id
GROUP BY c.statut;

-- =====================================================
-- ROLES ET UTILISATEURS
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_vendeur') THEN
        CREATE ROLE role_vendeur NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_controleur') THEN
        CREATE ROLE role_controleur NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'user_vendeur') THEN
        CREATE ROLE user_vendeur LOGIN PASSWORD 'vendeur_test';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'user_controleur') THEN
        CREATE ROLE user_controleur LOGIN PASSWORD 'controleur_test';
    END IF;
END
$$;

-- Chaque utilisateur reçoit un rôle-métier
GRANT role_vendeur TO user_vendeur;
GRANT role_controleur TO user_controleur;

-- Droits : sur les vues uniquement, jamais sur les tables
GRANT SELECT, INSERT, UPDATE ON v_vendeur_commandes TO role_vendeur;
GRANT SELECT ON v_controleur_ventes TO role_controleur;

-- =====================================================
-- INDEX
-- =====================================================

-- Index 1 : Optimiser la recherche par statut (utile pour la vue du contrôleur)
CREATE INDEX idx_commandes_statut ON commandes(statut);

-- Index 2 : Optimiser la recherche des commandes d'un client spécifique
CREATE INDEX idx_commandes_client_id ON commandes(client_id);