-- =====================================================
-- TRIGGERS POUR LES RÈGLES D'INTÉGRITÉ
-- =====================================================

-- =====================================================
-- TRIGGERS POUR LA TABLE PERSONNEL
-- =====================================================

-- Trigger pour valider le login et mot de passe (obligatoires)
CREATE OR REPLACE TRIGGER trg_pers_login_motP
BEFORE INSERT OR UPDATE ON Personnel
FOR EACH ROW
BEGIN
    -- Vérifier que le login n'est pas NULL ou vide
    IF :NEW.login IS NULL OR TRIM(:NEW.login) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20301, PKG_MESSAGES.MSG_LOGIN_REQUIRED);
    END IF;
    
    -- Vérifier que le mot de passe n'est pas NULL ou vide
    IF :NEW.motP IS NULL OR TRIM(:NEW.motP) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20302, PKG_MESSAGES.MSG_PASSWORD_REQUIRED);
    END IF;
END;
/

-- Trigger pour valider le format du numéro de téléphone
CREATE OR REPLACE TRIGGER trg_pers_tel
BEFORE INSERT OR UPDATE OF telpers ON Personnel
FOR EACH ROW
DECLARE
    v_tel VARCHAR2(20);
BEGIN
    IF :NEW.telpers IS NOT NULL THEN
        v_tel := TRIM(:NEW.telpers);
        
        -- Format tunisien: +216XXXXXXXX ou 00216XXXXXXXX (8 chiffres après le code pays)
        IF NOT REGEXP_LIKE(v_tel, '^\+216[0-9]{8}$') AND 
           NOT REGEXP_LIKE(v_tel, '^00216[0-9]{8}$') THEN
            RAISE_APPLICATION_ERROR(-20303, PKG_MESSAGES.MSG_PHONE_INVALID || 
                ' (Format: +216XXXXXXXX ou 00216XXXXXXXX)');
        END IF;
    END IF;
END;
/

-- =====================================================
-- TRIGGERS POUR LA TABLE ARTICLES
-- =====================================================

-- Trigger pour vérifier que le prix de vente > prix d'achat
CREATE OR REPLACE TRIGGER trg_art_prix
BEFORE INSERT OR UPDATE ON Articles
FOR EACH ROW
BEGIN
    IF :NEW.prixV <= :NEW.prixA THEN
        RAISE_APPLICATION_ERROR(-20304, PKG_MESSAGES.MSG_ART_PRICE_INVALID);
    END IF;
END;
/

-- Trigger pour vérifier qu'un article n'est pas ajouté plusieurs fois
CREATE OR REPLACE TRIGGER trg_art_doublon
BEFORE INSERT ON Articles
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM Articles
    WHERE UPPER(designation) = UPPER(:NEW.designation)
    AND supp = 'N';
    
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20305, PKG_MESSAGES.MSG_ART_ALREADY_EXISTS);
    END IF;
END;
/

-- =====================================================
-- TRIGGERS POUR LA TABLE CLIENTS
-- =====================================================

-- Trigger pour valider le format du numéro de téléphone
CREATE OR REPLACE TRIGGER trg_clt_tel
BEFORE INSERT OR UPDATE OF telclt ON Clients
FOR EACH ROW
DECLARE
    v_tel VARCHAR2(20);
BEGIN
    IF :NEW.telclt IS NOT NULL THEN
        v_tel := TRIM(:NEW.telclt);
        
        -- Format tunisien: +216XXXXXXXX ou 00216XXXXXXXX
        IF NOT REGEXP_LIKE(v_tel, '^\+216[0-9]{8}$') AND 
           NOT REGEXP_LIKE(v_tel, '^00216[0-9]{8}$') THEN
            RAISE_APPLICATION_ERROR(-20306, PKG_MESSAGES.MSG_PHONE_INVALID ||
                ' (Format: +216XXXXXXXX ou 00216XXXXXXXX)');
        END IF;
    END IF;
END;
/

-- Trigger pour vérifier qu'un client n'est pas ajouté plusieurs fois
CREATE OR REPLACE TRIGGER trg_clt_doublon
BEFORE INSERT ON Clients
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Vérifier la combinaison nom + prénom + adresse email
    SELECT COUNT(*)
    INTO v_count
    FROM Clients
    WHERE UPPER(nomclt) = UPPER(:NEW.nomclt)
    AND (
        (prenomclt IS NULL AND :NEW.prenomclt IS NULL) OR
        UPPER(prenomclt) = UPPER(:NEW.prenomclt)
    )
    AND (
        (adrmail IS NULL AND :NEW.adrmail IS NULL) OR
        UPPER(adrmail) = UPPER(:NEW.adrmail)
    );
    
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20307, PKG_MESSAGES.MSG_DUPLICATE_ENTRY ||
            ' : Client avec même nom/prénom/email existe déjà');
    END IF;
END;
/

-- =====================================================
-- TRIGGERS POUR LA TABLE COMMANDES
-- =====================================================

-- Trigger pour vérifier que la date de commande = date système
CREATE OR REPLACE TRIGGER trg_cde_date
BEFORE INSERT ON Commandes
FOR EACH ROW
BEGIN
    -- Forcer la date de la commande à être la date système
    :NEW.datecde := SYSDATE;
END;
/

-- Trigger pour initialiser l'état de la commande à 'EC'
CREATE OR REPLACE TRIGGER trg_cde_etat
BEFORE INSERT ON Commandes
FOR EACH ROW
BEGIN
    -- Si l'état n'est pas spécifié, le mettre à 'EC'
    IF :NEW.etatcde IS NULL THEN
        :NEW.etatcde := 'EC';
    END IF;
END;
/

-- =====================================================
-- TRIGGERS POUR LA TABLE LIVRAISONCOM
-- =====================================================

-- Trigger pour vérifier que la commande est prête (état = PR)
CREATE OR REPLACE TRIGGER trg_liv_etat_commande
BEFORE INSERT ON LivraisonCom
FOR EACH ROW
DECLARE
    v_etat VARCHAR2(2);
BEGIN
    SELECT etatcde INTO v_etat
    FROM Commandes
    WHERE nocde = :NEW.nocde;
    
    IF v_etat != 'PR' THEN
        RAISE_APPLICATION_ERROR(-20308, PKG_MESSAGES.MSG_LIV_CDE_NOT_READY);
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20309, PKG_MESSAGES.MSG_CDE_NOT_FOUND);
END;
/

-- Trigger pour vérifier la limite de 15 livraisons par jour et par ville
CREATE OR REPLACE TRIGGER trg_liv_limite
BEFORE INSERT OR UPDATE OF livreur, dateliv ON LivraisonCom
FOR EACH ROW
DECLARE
    v_count NUMBER;
    v_code_postal VARCHAR2(10);
    v_limite CONSTANT NUMBER := 15;
BEGIN
    -- Récupérer le code postal du client
    SELECT cl.code_postal INTO v_code_postal
    FROM Commandes c
    JOIN Clients cl ON c.noclt = cl.noclt
    WHERE c.nocde = :NEW.nocde;
    
    -- Compter les livraisons du livreur pour cette date et cette ville
    SELECT COUNT(*)
    INTO v_count
    FROM LivraisonCom lc
    JOIN Commandes c ON lc.nocde = c.nocde
    JOIN Clients cl ON c.noclt = cl.noclt
    WHERE lc.livreur = :NEW.livreur
    AND TRUNC(lc.dateliv) = TRUNC(:NEW.dateliv)
    AND cl.code_postal = v_code_postal
    AND lc.nocde != :NEW.nocde;
    
    IF v_count >= v_limite THEN
        RAISE_APPLICATION_ERROR(-20310, PKG_MESSAGES.MSG_LIV_LIVREUR_LIMIT);
    END IF;
END;
/

-- Trigger pour vérifier les restrictions horaires de modification
CREATE OR REPLACE TRIGGER trg_liv_horaire
BEFORE UPDATE OF dateliv, livreur ON LivraisonCom
FOR EACH ROW
DECLARE
    v_heure_actuelle NUMBER;
    v_date_liv_trunc DATE;
BEGIN
    v_heure_actuelle := TO_NUMBER(TO_CHAR(SYSDATE, 'HH24'));
    v_date_liv_trunc := TRUNC(:NEW.dateliv);
    
    -- Si la livraison est pour aujourd'hui
    IF v_date_liv_trunc = TRUNC(SYSDATE) THEN
        -- Pour les livraisons du matin : avant 9h
        -- Pour les livraisons de l'après-midi : avant 14h
        IF v_heure_actuelle >= 9 AND v_heure_actuelle < 14 THEN
            RAISE_APPLICATION_ERROR(-20311, PKG_MESSAGES.MSG_LIV_TIME_RESTRICTION);
        ELSIF v_heure_actuelle >= 14 THEN
            RAISE_APPLICATION_ERROR(-20312, PKG_MESSAGES.MSG_LIV_TIME_RESTRICTION);
        END IF;
    END IF;
END;
/

-- =====================================================
-- TRIGGER D'AUDIT POUR LES SUPPRESSIONS
-- =====================================================

-- Trigger pour logger les suppressions d'articles
CREATE OR REPLACE TRIGGER trg_audit_art_supp
AFTER UPDATE OF supp ON Articles
FOR EACH ROW
WHEN (NEW.supp = 'O' AND OLD.supp = 'N')
BEGIN
    DBMS_OUTPUT.PUT_LINE('Article ' || :OLD.refart || ' (' || :OLD.designation || 
        ') supprimé logiquement le ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
END;
/

-- Trigger pour mettre à jour automatiquement l'état de la commande lors de l'ajout d'une livraison
CREATE OR REPLACE TRIGGER trg_liv_maj_etat_cde
AFTER INSERT ON LivraisonCom
FOR EACH ROW
BEGIN
    UPDATE Commandes
    SET etatcde = 'LI'
    WHERE nocde = :NEW.nocde
    AND etatcde = 'PR';
END;
/