-- =====================================================
-- GESTION DES PRIVILÈGES ET SCHÉMAS EXTERNES
-- =====================================================

-- =====================================================
-- CRÉATION DES VUES POUR LES CLIENTS
-- =====================================================

-- Vue pour que les clients puissent voir leurs propres commandes
CREATE OR REPLACE VIEW V_CLIENT_COMMANDES AS
SELECT 
    c.nocde,
    c.datecde,
    c.etatcde,
    CASE c.etatcde
        WHEN 'EC' THEN 'En Cours'
        WHEN 'PR' THEN 'Prête'
        WHEN 'LI' THEN 'En Livraison'
        WHEN 'SO' THEN 'Sortie/Livrée'
        WHEN 'AN' THEN 'Annulée'
        WHEN 'AL' THEN 'Annulée Livreur'
    END AS etat_libelle,
    c.noclt,
    cl.nomclt,
    cl.prenomclt
FROM Commandes c
JOIN Clients cl ON c.noclt = cl.noclt;

-- Vue pour que les clients puissent voir les détails de leurs commandes
CREATE OR REPLACE VIEW V_CLIENT_LIGNES_COMMANDES AS
SELECT 
    lc.nocde,
    lc.refart,
    a.designation,
    a.prixV,
    lc.qtecde,
    (lc.qtecde * a.prixV) AS montant_ligne,
    c.noclt
FROM LigCdes lc
JOIN Articles a ON lc.refart = a.refart
JOIN Commandes c ON lc.nocde = c.nocde
WHERE a.supp = 'N';

-- Vue pour que les clients puissent suivre leurs livraisons
CREATE OR REPLACE VIEW V_CLIENT_LIVRAISONS AS
SELECT 
    lv.nocde,
    lv.dateliv,
    lv.modepay,
    lv.etaliv,
    CASE lv.etaliv
        WHEN 'EP' THEN 'En Préparation'
        WHEN 'EL' THEN 'En Livraison'
        WHEN 'LV' THEN 'Livrée'
    END AS etat_livraison,
    p.nompers || ' ' || p.prenompers AS livreur,
    p.telpers AS tel_livreur,
    c.noclt
FROM LivraisonCom lv
JOIN Personnel p ON lv.livreur = p.idpers
JOIN Commandes c ON lv.nocde = c.nocde;

-- Vue du catalogue d'articles pour les clients
CREATE OR REPLACE VIEW V_CATALOGUE_ARTICLES AS
SELECT 
    refart,
    designation,
    prixV,
    codetva,
    categorie,
    CASE 
        WHEN qtestk > 0 THEN 'Disponible'
        ELSE 'Rupture de stock'
    END AS disponibilite
FROM Articles
WHERE supp = 'N';

-- =====================================================
-- CRÉATION DES VUES POUR LE PERSONNEL
-- =====================================================

-- Vue pour le personnel : statistiques des commandes
CREATE OR REPLACE VIEW V_STATS_COMMANDES AS
SELECT 
    TO_CHAR(datecde, 'YYYY-MM') AS mois,
    etatcde,
    COUNT(*) AS nb_commandes,
    SUM(
        (SELECT SUM(lc.qtecde * a.prixV)
         FROM LigCdes lc
         JOIN Articles a ON lc.refart = a.refart
         WHERE lc.nocde = c.nocde)
    ) AS montant_total
FROM Commandes c
GROUP BY TO_CHAR(datecde, 'YYYY-MM'), etatcde;

-- Vue pour le personnel : livraisons du jour
CREATE OR REPLACE VIEW V_LIVRAISONS_JOUR AS
SELECT 
    lv.nocde,
    c.noclt,
    cl.nomclt,
    cl.prenomclt,
    cl.adrclt,
    cl.code_postal,
    cl.telclt,
    lv.dateliv,
    lv.livreur,
    p.nompers || ' ' || p.prenompers AS nom_livreur,
    lv.modepay,
    lv.etaliv
FROM LivraisonCom lv
JOIN Commandes c ON lv.nocde = c.nocde
JOIN Clients cl ON c.noclt = cl.noclt
JOIN Personnel p ON lv.livreur = p.idpers
WHERE TRUNC(lv.dateliv) = TRUNC(SYSDATE);

-- Vue pour le personnel : articles en rupture de stock
CREATE OR REPLACE VIEW V_ARTICLES_RUPTURE AS
SELECT 
    refart,
    designation,
    categorie,
    qtestk,
    prixV
FROM Articles
WHERE qtestk <= 5 AND supp = 'N'
ORDER BY qtestk, categorie;

-- Vue pour le personnel : charges de travail des livreurs
CREATE OR REPLACE VIEW V_CHARGE_LIVREURS AS
SELECT 
    p.idpers,
    p.nompers,
    p.prenompers,
    TRUNC(lv.dateliv) AS date_livraison,
    cl.code_postal,
    COUNT(*) AS nb_livraisons
FROM Personnel p
LEFT JOIN LivraisonCom lv ON p.idpers = lv.livreur
LEFT JOIN Commandes c ON lv.nocde = c.nocde
LEFT JOIN Clients cl ON c.noclt = cl.noclt
WHERE p.codeposte = 4 -- Poste de livreur
GROUP BY p.idpers, p.nompers, p.prenompers, TRUNC(lv.dateliv), cl.code_postal
ORDER BY date_livraison DESC, p.nompers;

-- =====================================================
-- CRÉATION DES UTILISATEURS ET ATTRIBUTION DES DROITS
-- =====================================================

-- Script pour créer des utilisateurs (à exécuter en tant que DBA/SYSTEM)
-- Note: Adapter les noms d'utilisateurs selon vos besoins

/*
-- Création d'utilisateurs pour les différents rôles
CREATE USER admin_user IDENTIFIED BY Admin2024;
CREATE USER magasinier_user IDENTIFIED BY Mag2024;
CREATE USER chef_livreur_user IDENTIFIED BY Chef2024;
CREATE USER client_user IDENTIFIED BY Client2024;

-- Attribution des privilèges de connexion
GRANT CONNECT TO admin_user;
GRANT CONNECT TO magasinier_user;
GRANT CONNECT TO chef_livreur_user;
GRANT CONNECT TO client_user;

-- Privilèges pour l'administrateur (tous les droits)
GRANT ALL PRIVILEGES ON Poste TO admin_user;
GRANT ALL PRIVILEGES ON Personnel TO admin_user;
GRANT ALL PRIVILEGES ON Articles TO admin_user;
GRANT ALL PRIVILEGES ON Clients TO admin_user;
GRANT ALL PRIVILEGES ON Commandes TO admin_user;
GRANT ALL PRIVILEGES ON LigCdes TO admin_user;
GRANT ALL PRIVILEGES ON LivraisonCom TO admin_user;
GRANT ALL PRIVILEGES ON HCommandesAnnulees TO admin_user;

-- Privilèges sur les séquences
GRANT SELECT ON seq_refart TO admin_user;
GRANT SELECT ON seq_noclt TO admin_user;
GRANT SELECT ON seq_nocde TO admin_user;
GRANT SELECT ON seq_idpers TO admin_user;
GRANT SELECT ON seq_codeposte TO admin_user;

-- Privilèges sur les packages
GRANT EXECUTE ON PKG_MESSAGES TO admin_user;
GRANT EXECUTE ON PKG_COMMANDES TO admin_user;
GRANT EXECUTE ON PKG_LIVRAISONS TO admin_user;
GRANT EXECUTE ON PKG_ARTICLES TO admin_user;

-- Privilèges pour le magasinier
GRANT SELECT, INSERT, UPDATE ON Articles TO magasinier_user;
GRANT SELECT ON Commandes TO magasinier_user;
GRANT SELECT ON LigCdes TO magasinier_user;
GRANT SELECT ON Clients TO magasinier_user;
GRANT SELECT ON seq_refart TO magasinier_user;

GRANT EXECUTE ON PKG_MESSAGES TO magasinier_user;
GRANT EXECUTE ON PKG_ARTICLES TO magasinier_user;
GRANT EXECUTE ON PKG_COMMANDES TO magasinier_user;

GRANT SELECT ON V_STATS_COMMANDES TO magasinier_user;
GRANT SELECT ON V_ARTICLES_RUPTURE TO magasinier_user;

-- Privilèges pour le chef livreur
GRANT SELECT ON LivraisonCom TO chef_livreur_user;
GRANT SELECT, UPDATE ON Commandes TO chef_livreur_user;
GRANT SELECT ON Clients TO chef_livreur_user;
GRANT SELECT ON Personnel TO chef_livreur_user;
GRANT SELECT ON LigCdes TO chef_livreur_user;
GRANT SELECT ON Articles TO chef_livreur_user;

GRANT EXECUTE ON PKG_MESSAGES TO chef_livreur_user;
GRANT EXECUTE ON PKG_LIVRAISONS TO chef_livreur_user;
GRANT EXECUTE ON PKG_COMMANDES TO chef_livreur_user;

GRANT SELECT ON V_LIVRAISONS_JOUR TO chef_livreur_user;
GRANT SELECT ON V_CHARGE_LIVREURS TO chef_livreur_user;

-- Privilèges pour les clients (lecture seule de leurs données)
GRANT SELECT ON V_CLIENT_COMMANDES TO client_user;
GRANT SELECT ON V_CLIENT_LIGNES_COMMANDES TO client_user;
GRANT SELECT ON V_CLIENT_LIVRAISONS TO client_user;
GRANT SELECT ON V_CATALOGUE_ARTICLES TO client_user;
*/

-- =====================================================
-- PROCÉDURE POUR CRÉER UN UTILISATEUR CLIENT
-- =====================================================

CREATE OR REPLACE PROCEDURE CREER_UTILISATEUR_CLIENT(
    p_noclt IN NUMBER,
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) AS
    v_sql VARCHAR2(1000);
BEGIN
    -- Créer l'utilisateur
    v_sql := 'CREATE USER ' || p_username || ' IDENTIFIED BY ' || p_password;
    EXECUTE IMMEDIATE v_sql;
    
    -- Donner le privilège de connexion
    EXECUTE IMMEDIATE 'GRANT CONNECT TO ' || p_username;
    
    -- Donner accès aux vues client
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_CLIENT_COMMANDES TO ' || p_username;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_CLIENT_LIGNES_COMMANDES TO ' || p_username;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_CLIENT_LIVRAISONS TO ' || p_username;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_CATALOGUE_ARTICLES TO ' || p_username;
    
    DBMS_OUTPUT.PUT_LINE('Utilisateur client créé avec succès: ' || p_username);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur lors de la création de l''utilisateur: ' || SQLERRM);
END;
/

-- =====================================================
-- CRÉATION DES RÔLES (Optionnel mais recommandé)
-- =====================================================

/*
-- Créer des rôles pour faciliter la gestion des privilèges
CREATE ROLE role_administrateur;
CREATE ROLE role_magasinier;
CREATE ROLE role_chef_livreur;
CREATE ROLE role_client;

-- Attribuer les privilèges aux rôles
GRANT ALL PRIVILEGES ON Commandes TO role_administrateur;
GRANT ALL PRIVILEGES ON LivraisonCom TO role_administrateur;
GRANT ALL PRIVILEGES ON Articles TO role_administrateur;
-- ... etc pour toutes les tables

-- Attribuer les rôles aux utilisateurs
GRANT role_administrateur TO admin_user;
GRANT role_magasinier TO magasinier_user;
GRANT role_chef_livreur TO chef_livreur_user;
GRANT role_client TO client_user;
*/

-- =====================================================
-- POLITIQUE DE SÉCURITÉ AU NIVEAU DES LIGNES (RLS)
-- =====================================================

-- Créer une fonction de politique pour les clients
-- Les clients ne peuvent voir que leurs propres données
CREATE OR REPLACE FUNCTION politique_client_commandes(
    schema_var IN VARCHAR2,
    table_var IN VARCHAR2
) RETURN VARCHAR2 AS
    v_user VARCHAR2(100);
    v_noclt NUMBER;
BEGIN
    v_user := SYS_CONTEXT('USERENV', 'SESSION_USER');
    
    -- Récupérer le numéro client associé à l'utilisateur
    -- (Nécessite une table de mapping user -> noclt)
    -- Pour simplifier, on retourne une condition générique
    
    RETURN 'noclt = (SELECT noclt FROM user_client_mapping WHERE username = ''' || v_user || ''')';
EXCEPTION
    WHEN OTHERS THEN
        RETURN '1=0'; -- Aucune donnée accessible en cas d'erreur
END;
/

-- Exemple d'application de la politique (à adapter selon vos besoins)
/*
BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'VOTRE_SCHEMA',
        object_name     => 'V_CLIENT_COMMANDES',
        policy_name     => 'politique_client_cde',
        function_schema => 'VOTRE_SCHEMA',
        policy_function => 'politique_client_commandes',
        statement_types => 'SELECT'
    );
END;
/
*/

COMMIT;