-- =====================================================
-- PACKAGE GESTION DES LIVRAISONS
-- =====================================================

CREATE OR REPLACE PACKAGE PKG_LIVRAISONS AS
    -- Procédures publiques
    PROCEDURE AJOUTER_LIVRAISON(
        p_nocde IN NUMBER,
        p_dateliv IN DATE,
        p_livreur IN NUMBER,
        p_modepay IN VARCHAR2
    );
    
    PROCEDURE MODIFIER_LIVRAISON(
        p_nocde IN NUMBER,
        p_nouvelle_date IN DATE DEFAULT NULL,
        p_nouveau_livreur IN NUMBER DEFAULT NULL
    );
    
    PROCEDURE SUPPRIMER_LIVRAISON(
        p_nocde IN NUMBER
    );
    
    PROCEDURE CHERCHER_PAR_COMMANDE(
        p_nocde IN NUMBER
    );
    
    PROCEDURE CHERCHER_PAR_LIVREUR(
        p_livreur IN NUMBER
    );
    
    PROCEDURE CHERCHER_PAR_VILLE(
        p_code_postal IN VARCHAR2
    );
    
    PROCEDURE CHERCHER_PAR_DATE(
        p_date IN DATE
    );
    
    -- Fonction pour vérifier la limite du livreur
    FUNCTION VERIFIER_LIMITE_LIVREUR(
        p_livreur IN NUMBER,
        p_date IN DATE,
        p_code_postal IN VARCHAR2,
        p_nocde_exclure IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN;
    
    -- Fonction pour vérifier les restrictions horaires
    FUNCTION VERIFIER_RESTRICTION_HORAIRE(
        p_dateliv IN DATE
    ) RETURN BOOLEAN;
    
END PKG_LIVRAISONS;
/

CREATE OR REPLACE PACKAGE BODY PKG_LIVRAISONS AS

    -- Fonction pour vérifier la limite de 15 livraisons par jour et par ville
    FUNCTION VERIFIER_LIMITE_LIVREUR(
        p_livreur IN NUMBER,
        p_date IN DATE,
        p_code_postal IN VARCHAR2,
        p_nocde_exclure IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN IS
        v_count NUMBER;
        v_limite CONSTANT NUMBER := 15;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM LivraisonCom lc
        JOIN Commandes c ON lc.nocde = c.nocde
        JOIN Clients cl ON c.noclt = cl.noclt
        WHERE lc.livreur = p_livreur
        AND TRUNC(lc.dateliv) = TRUNC(p_date)
        AND cl.code_postal = p_code_postal
        AND (p_nocde_exclure IS NULL OR lc.nocde != p_nocde_exclure);
        
        RETURN v_count < v_limite;
    END VERIFIER_LIMITE_LIVREUR;

    -- Fonction pour vérifier les restrictions horaires de modification
    FUNCTION VERIFIER_RESTRICTION_HORAIRE(
        p_dateliv IN DATE
    ) RETURN BOOLEAN IS
        v_heure_actuelle NUMBER;
        v_date_liv_trunc DATE;
    BEGIN
        v_heure_actuelle := TO_NUMBER(TO_CHAR(SYSDATE, 'HH24'));
        v_date_liv_trunc := TRUNC(p_dateliv);
        
        -- Si la livraison est pour aujourd'hui
        IF v_date_liv_trunc = TRUNC(SYSDATE) THEN
            -- Pour les livraisons du matin : avant 9h
            -- Pour les livraisons de l'après-midi : avant 14h
            IF v_heure_actuelle >= 9 AND v_heure_actuelle < 14 THEN
                RETURN FALSE; -- Entre 9h et 14h, pas de modification
            ELSIF v_heure_actuelle >= 14 THEN
                RETURN FALSE; -- Après 14h, pas de modification pour aujourd'hui
            END IF;
        END IF;
        
        RETURN TRUE;
    END VERIFIER_RESTRICTION_HORAIRE;

    -- Procédure pour ajouter une livraison
    PROCEDURE AJOUTER_LIVRAISON(
        p_nocde IN NUMBER,
        p_dateliv IN DATE,
        p_livreur IN NUMBER,
        p_modepay IN VARCHAR2
    ) IS
        v_etat_cde VARCHAR2(2);
        v_code_postal VARCHAR2(10);
        v_count_livreur NUMBER;
        v_count_commande NUMBER;
    BEGIN
        -- Vérifier si la commande existe et récupérer son état
        SELECT COUNT(*), MAX(etatcde)
        INTO v_count_commande, v_etat_cde
        FROM Commandes
        WHERE nocde = p_nocde;
        
        IF v_count_commande = 0 THEN
            RAISE_APPLICATION_ERROR(-20101, PKG_MESSAGES.MSG_CDE_NOT_FOUND);
        END IF;
        
        -- Vérifier si la commande est prête (état = PR)
        IF v_etat_cde != 'PR' THEN
            RAISE_APPLICATION_ERROR(-20102, PKG_MESSAGES.MSG_LIV_CDE_NOT_READY);
        END IF;
        
        -- Vérifier si le livreur existe
        SELECT COUNT(*) INTO v_count_livreur
        FROM Personnel
        WHERE idpers = p_livreur;
        
        IF v_count_livreur = 0 THEN
            RAISE_APPLICATION_ERROR(-20103, PKG_MESSAGES.MSG_LIV_LIVREUR_NOT_FOUND);
        END IF;
        
        -- Récupérer le code postal du client
        SELECT cl.code_postal INTO v_code_postal
        FROM Commandes c
        JOIN Clients cl ON c.noclt = cl.noclt
        WHERE c.nocde = p_nocde;
        
        -- Vérifier la limite du livreur
        IF NOT VERIFIER_LIMITE_LIVREUR(p_livreur, p_dateliv, v_code_postal) THEN
            RAISE_APPLICATION_ERROR(-20104, PKG_MESSAGES.MSG_LIV_LIVREUR_LIMIT);
        END IF;
        
        -- Vérifier la date de livraison
        IF TRUNC(p_dateliv) < TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(-20105, PKG_MESSAGES.MSG_LIV_INVALID_DATE);
        END IF;
        
        -- Insérer la livraison
        INSERT INTO LivraisonCom (nocde, dateliv, livreur, modepay, etaliv)
        VALUES (p_nocde, p_dateliv, p_livreur, p_modepay, 'EP');
        
        -- Mettre à jour l'état de la commande à LI
        UPDATE Commandes
        SET etatcde = 'LI'
        WHERE nocde = p_nocde;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_LIV_ADDED);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE BETWEEN -20105 AND -20101 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20106, PKG_MESSAGES.MSG_OPERATION_FAILED || ' : ' || SQLERRM);
            END IF;
    END AJOUTER_LIVRAISON;

    -- Procédure pour modifier une livraison
    PROCEDURE MODIFIER_LIVRAISON(
        p_nocde IN NUMBER,
        p_nouvelle_date IN DATE DEFAULT NULL,
        p_nouveau_livreur IN NUMBER DEFAULT NULL
    ) IS
        v_count NUMBER;
        v_date_actuelle DATE;
        v_livreur_actuel NUMBER;
        v_code_postal VARCHAR2(10);
        v_nouvelle_date DATE;
        v_nouveau_livreur NUMBER;
    BEGIN
        -- Vérifier si la livraison existe
        SELECT COUNT(*), MAX(dateliv), MAX(livreur)
        INTO v_count, v_date_actuelle, v_livreur_actuel
        FROM LivraisonCom
        WHERE nocde = p_nocde;
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20107, PKG_MESSAGES.MSG_LIV_NOT_FOUND);
        END IF;
        
        -- Déterminer les nouvelles valeurs
        v_nouvelle_date := NVL(p_nouvelle_date, v_date_actuelle);
        v_nouveau_livreur := NVL(p_nouveau_livreur, v_livreur_actuel);
        
        -- Vérifier les restrictions horaires
        IF NOT VERIFIER_RESTRICTION_HORAIRE(v_nouvelle_date) THEN
            RAISE_APPLICATION_ERROR(-20108, PKG_MESSAGES.MSG_LIV_TIME_RESTRICTION);
        END IF;
        
        -- Récupérer le code postal
        SELECT cl.code_postal INTO v_code_postal
        FROM Commandes c
        JOIN Clients cl ON c.noclt = cl.noclt
        WHERE c.nocde = p_nocde;
        
        -- Vérifier la limite du livreur (en excluant cette commande)
        IF NOT VERIFIER_LIMITE_LIVREUR(v_nouveau_livreur, v_nouvelle_date, v_code_postal, p_nocde) THEN
            RAISE_APPLICATION_ERROR(-20109, PKG_MESSAGES.MSG_LIV_LIVREUR_LIMIT);
        END IF;
        
        -- Vérifier la date
        IF TRUNC(v_nouvelle_date) < TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(-20110, PKG_MESSAGES.MSG_LIV_INVALID_DATE);
        END IF;
        
        -- Mettre à jour la livraison
        UPDATE LivraisonCom
        SET dateliv = v_nouvelle_date,
            livreur = v_nouveau_livreur
        WHERE nocde = p_nocde;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_LIV_UPDATED);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE BETWEEN -20110 AND -20107 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20111, PKG_MESSAGES.MSG_OPERATION_FAILED || ' : ' || SQLERRM);
            END IF;
    END MODIFIER_LIVRAISON;

    -- Procédure pour supprimer une livraison (annulation)
    PROCEDURE SUPPRIMER_LIVRAISON(
        p_nocde IN NUMBER
    ) IS
        v_count NUMBER;
        v_noclt NUMBER;
        v_datecde DATE;
    BEGIN
        -- Vérifier si la livraison existe
        SELECT COUNT(*) INTO v_count
        FROM LivraisonCom
        WHERE nocde = p_nocde;
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20112, PKG_MESSAGES.MSG_LIV_NOT_FOUND);
        END IF;
        
        -- Récupérer les infos de la commande
        SELECT noclt, datecde INTO v_noclt, v_datecde
        FROM Commandes
        WHERE nocde = p_nocde;
        
        -- Supprimer la livraison
        DELETE FROM LivraisonCom WHERE nocde = p_nocde;
        
        -- Mettre à jour l'état de la commande à AN
        UPDATE Commandes
        SET etatcde = 'AN'
        WHERE nocde = p_nocde;
        
        -- Ajouter dans l'historique
        INSERT INTO HCommandesAnnulees (nocde, noclt, datecde, dateannulation, avantliv)
        VALUES (p_nocde, v_noclt, v_datecde, SYSDATE, 'O');
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_LIV_CANCELLED);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE = -20112 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20113, PKG_MESSAGES.MSG_OPERATION_FAILED || ' : ' || SQLERRM);
            END IF;
    END SUPPRIMER_LIVRAISON;

    -- Procédure pour chercher une livraison par commande
    PROCEDURE CHERCHER_PAR_COMMANDE(
        p_nocde IN NUMBER
    ) IS
        CURSOR c_livraison IS
            SELECT lc.nocde, lc.dateliv, lc.livreur, p.nompers, p.prenompers, 
                   lc.modepay, lc.etaliv, cl.code_postal
            FROM LivraisonCom lc
            JOIN Personnel p ON lc.livreur = p.idpers
            JOIN Commandes c ON lc.nocde = c.nocde
            JOIN Clients cl ON c.noclt = cl.noclt
            WHERE lc.nocde = p_nocde;
        
        v_livraison c_livraison%ROWTYPE;
    BEGIN
        OPEN c_livraison;
        FETCH c_livraison INTO v_livraison;
        
        IF c_livraison%NOTFOUND THEN
            DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_LIV_NOT_FOUND);
        ELSE
            DBMS_OUTPUT.PUT_LINE('===== DÉTAILS DE LA LIVRAISON =====');
            DBMS_OUTPUT.PUT_LINE('Commande : ' || v_livraison.nocde);
            DBMS_OUTPUT.PUT_LINE('Date livraison : ' || TO_CHAR(v_livraison.dateliv, 'DD/MM/YYYY HH24:MI'));
            DBMS_OUTPUT.PUT_LINE('Livreur : ' || v_livraison.nompers || ' ' || v_livraison.prenompers);
            DBMS_OUTPUT.PUT_LINE('Mode paiement : ' || v_livraison.modepay);
            DBMS_OUTPUT.PUT_LINE('État : ' || v_livraison.etaliv);
            DBMS_OUTPUT.PUT_LINE('Ville : ' || v_livraison.code_postal);
        END IF;
        
        CLOSE c_livraison;
    END CHERCHER_PAR_COMMANDE;

    -- Procédure pour chercher les livraisons d'un livreur
    PROCEDURE CHERCHER_PAR_LIVREUR(
        p_livreur IN NUMBER
    ) IS
        CURSOR c_livraisons IS
            SELECT lc.nocde, lc.dateliv, lc.etaliv, cl.code_postal
            FROM LivraisonCom lc
            JOIN Commandes c ON lc.nocde = c.nocde
            JOIN Clients cl ON c.noclt = cl.noclt
            WHERE lc.livreur = p_livreur
            ORDER BY lc.dateliv DESC;
        
        v_count NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('===== LIVRAISONS DU LIVREUR ' || p_livreur || ' =====');
        
        FOR rec IN c_livraisons LOOP
            v_count := v_count + 1;
            DBMS_OUTPUT.PUT_LINE('Commande ' || rec.nocde || 
                ' - Date : ' || TO_CHAR(rec.dateliv, 'DD/MM/YYYY') ||
                ' - Ville : ' || rec.code_postal ||
                ' - État : ' || rec.etaliv);
        END LOOP;
        
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Aucune livraison trouvée');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Total : ' || v_count || ' livraison(s)');
        END IF;
    END CHERCHER_PAR_LIVREUR;

    -- Procédure pour chercher les livraisons par ville
    PROCEDURE CHERCHER_PAR_VILLE(
        p_code_postal IN VARCHAR2
    ) IS
        CURSOR c_livraisons IS
            SELECT lc.nocde, lc.dateliv, lc.livreur, p.nompers, lc.etaliv
            FROM LivraisonCom lc
            JOIN Personnel p ON lc.livreur = p.idpers
            JOIN Commandes c ON lc.nocde = c.nocde
            JOIN Clients cl ON c.noclt = cl.noclt
            WHERE cl.code_postal = p_code_postal
            ORDER BY lc.dateliv DESC;
        
        v_count NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('===== LIVRAISONS POUR LA VILLE ' || p_code_postal || ' =====');
        
        FOR rec IN c_livraisons LOOP
            v_count := v_count + 1;
            DBMS_OUTPUT.PUT_LINE('Commande ' || rec.nocde ||
                ' - Date : ' || TO_CHAR(rec.dateliv, 'DD/MM/YYYY') ||
                ' - Livreur : ' || rec.nompers ||
                ' - État : ' || rec.etaliv);
        END LOOP;
        
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Aucune livraison trouvée');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Total : ' || v_count || ' livraison(s)');
        END IF;
    END CHERCHER_PAR_VILLE;

    -- Procédure pour chercher les livraisons par date
    PROCEDURE CHERCHER_PAR_DATE(
        p_date IN DATE
    ) IS
        CURSOR c_livraisons IS
            SELECT lc.nocde, lc.livreur, p.nompers, cl.code_postal, lc.etaliv
            FROM LivraisonCom lc
            JOIN Personnel p ON lc.livreur = p.idpers
            JOIN Commandes c ON lc.nocde = c.nocde
            JOIN Clients cl ON c.noclt = cl.noclt
            WHERE TRUNC(lc.dateliv) = TRUNC(p_date)
            ORDER BY lc.nocde;
        
        v_count NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('===== LIVRAISONS DU ' || TO_CHAR(p_date, 'DD/MM/YYYY') || ' =====');
        
        FOR rec IN c_livraisons LOOP
            v_count := v_count + 1;
            DBMS_OUTPUT.PUT_LINE('Commande ' || rec.nocde ||
                ' - Livreur : ' || rec.nompers ||
                ' - Ville : ' || rec.code_postal ||
                ' - État : ' || rec.etaliv);
        END LOOP;
        
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Aucune livraison trouvée');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Total : ' || v_count || ' livraison(s)');
        END IF;
    END CHERCHER_PAR_DATE;

END PKG_LIVRAISONS;
/