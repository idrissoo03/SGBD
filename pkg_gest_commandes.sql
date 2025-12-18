-- =====================================================
-- PACKAGE GESTION DES COMMANDES
-- =====================================================

CREATE OR REPLACE PACKAGE PKG_COMMANDES AS
    -- Procédures publiques
    PROCEDURE AJOUTER_COMMANDE(
        p_noclt IN NUMBER,
        p_nocde OUT NUMBER
    );
    
    PROCEDURE MODIFIER_ETAT_COMMANDE(
        p_nocde IN NUMBER,
        p_nouvel_etat IN VARCHAR2
    );
    
    PROCEDURE ANNULER_COMMANDE(
        p_nocde IN NUMBER
    );
    
    PROCEDURE CHERCHER_PAR_NUMERO(
        p_nocde IN NUMBER
    );
    
    PROCEDURE CHERCHER_PAR_CLIENT(
        p_noclt IN NUMBER
    );
    
    PROCEDURE CHERCHER_PAR_DATE(
        p_date IN DATE
    );
    
    -- Fonction pour vérifier la transition d'état
    FUNCTION VERIFIER_TRANSITION_ETAT(
        p_etat_actuel IN VARCHAR2,
        p_nouvel_etat IN VARCHAR2
    ) RETURN BOOLEAN;
    
END PKG_COMMANDES;
/

CREATE OR REPLACE PACKAGE BODY PKG_COMMANDES AS

    -- Fonction pour vérifier la validité de la transition d'état
    FUNCTION VERIFIER_TRANSITION_ETAT(
        p_etat_actuel IN VARCHAR2,
        p_nouvel_etat IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        -- Transitions valides :
        -- EC->PR, EC->AN
        -- PR->LI, PR->AN, PR->AL
        -- LI->SO
        
        IF p_etat_actuel = 'EC' AND p_nouvel_etat IN ('PR', 'AN') THEN
            RETURN TRUE;
        ELSIF p_etat_actuel = 'PR' AND p_nouvel_etat IN ('LI', 'AN', 'AL') THEN
            RETURN TRUE;
        ELSIF p_etat_actuel = 'LI' AND p_nouvel_etat = 'SO' THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END VERIFIER_TRANSITION_ETAT;

    -- Procédure pour ajouter une commande
    PROCEDURE AJOUTER_COMMANDE(
        p_noclt IN NUMBER,
        p_nocde OUT NUMBER
    ) IS
        v_count NUMBER;
    BEGIN
        -- Vérifier si le client existe
        SELECT COUNT(*) INTO v_count
        FROM Clients
        WHERE noclt = p_noclt;
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, PKG_MESSAGES.MSG_CDE_CLIENT_NOT_FOUND);
        END IF;
        
        -- Générer le numéro de commande
        p_nocde := seq_nocde.NEXTVAL;
        
        -- Insérer la commande (date = SYSDATE, etat = 'EC' par défaut)
        INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
        VALUES (p_nocde, p_noclt, SYSDATE, 'EC');
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_CDE_ADDED || ' - Numéro : ' || p_nocde);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, PKG_MESSAGES.MSG_OPERATION_FAILED || ' : ' || SQLERRM);
    END AJOUTER_COMMANDE;

    -- Procédure pour modifier l'état d'une commande
    PROCEDURE MODIFIER_ETAT_COMMANDE(
        p_nocde IN NUMBER,
        p_nouvel_etat IN VARCHAR2
    ) IS
        v_etat_actuel VARCHAR2(2);
        v_count NUMBER;
    BEGIN
        -- Vérifier si la commande existe
        SELECT COUNT(*), MAX(etatcde) 
        INTO v_count, v_etat_actuel
        FROM Commandes
        WHERE nocde = p_nocde;
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, PKG_MESSAGES.MSG_CDE_NOT_FOUND);
        END IF;
        
        -- Vérifier si la transition est valide
        IF NOT VERIFIER_TRANSITION_ETAT(v_etat_actuel, p_nouvel_etat) THEN
            RAISE_APPLICATION_ERROR(-20004, PKG_MESSAGES.MSG_CDE_INVALID_STATE || 
                ' (de ' || v_etat_actuel || ' à ' || p_nouvel_etat || ')');
        END IF;
        
        -- Mettre à jour l'état
        UPDATE Commandes
        SET etatcde = p_nouvel_etat
        WHERE nocde = p_nocde;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_CDE_UPDATED || 
            ' - État : ' || v_etat_actuel || ' -> ' || p_nouvel_etat);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE = -20003 OR SQLCODE = -20004 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20005, PKG_MESSAGES.MSG_OPERATION_FAILED || ' : ' || SQLERRM);
            END IF;
    END MODIFIER_ETAT_COMMANDE;

    -- Procédure pour annuler une commande (suppression logique)
    PROCEDURE ANNULER_COMMANDE(
        p_nocde IN NUMBER
    ) IS
        v_count NUMBER;
        v_etat VARCHAR2(2);
        v_noclt NUMBER;
        v_datecde DATE;
    BEGIN
        -- Récupérer les informations de la commande
        SELECT COUNT(*), MAX(etatcde), MAX(noclt), MAX(datecde)
        INTO v_count, v_etat, v_noclt, v_datecde
        FROM Commandes
        WHERE nocde = p_nocde;
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20006, PKG_MESSAGES.MSG_CDE_NOT_FOUND);
        END IF;
        
        -- Vérifier si la commande n'est pas déjà annulée
        IF v_etat = 'AN' THEN
            RAISE_APPLICATION_ERROR(-20007, PKG_MESSAGES.MSG_CDE_ALREADY_CANCELLED);
        END IF;
        
        -- Vérifier si la commande n'est pas déjà livrée
        IF v_etat IN ('LI', 'SO') THEN
            RAISE_APPLICATION_ERROR(-20008, PKG_MESSAGES.MSG_CDE_ALREADY_DELIVERED);
        END IF;
        
        -- Mettre à jour l'état de la commande à 'AN'
        UPDATE Commandes
        SET etatcde = 'AN'
        WHERE nocde = p_nocde;
        
        -- Ajouter dans l'historique des commandes annulées
        INSERT INTO HCommandesAnnulees (nocde, noclt, datecde, dateannulation, avantliv)
        VALUES (p_nocde, v_noclt, v_datecde, SYSDATE, 'O');
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_CDE_CANCELLED);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE BETWEEN -20008 AND -20006 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20009, PKG_MESSAGES.MSG_OPERATION_FAILED || ' : ' || SQLERRM);
            END IF;
    END ANNULER_COMMANDE;

    -- Procédure pour chercher une commande par numéro
    PROCEDURE CHERCHER_PAR_NUMERO(
        p_nocde IN NUMBER
    ) IS
        CURSOR c_commande IS
            SELECT c.nocde, c.noclt, cl.nomclt, cl.prenomclt, c.datecde, c.etatcde
            FROM Commandes c
            JOIN Clients cl ON c.noclt = cl.noclt
            WHERE c.nocde = p_nocde;
        
        v_commande c_commande%ROWTYPE;
    BEGIN
        OPEN c_commande;
        FETCH c_commande INTO v_commande;
        
        IF c_commande%NOTFOUND THEN
            DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_CDE_NOT_FOUND);
        ELSE
            DBMS_OUTPUT.PUT_LINE('===== DÉTAILS DE LA COMMANDE =====');
            DBMS_OUTPUT.PUT_LINE('Numéro commande : ' || v_commande.nocde);
            DBMS_OUTPUT.PUT_LINE('Client : ' || v_commande.nomclt || ' ' || NVL(v_commande.prenomclt, ''));
            DBMS_OUTPUT.PUT_LINE('Date : ' || TO_CHAR(v_commande.datecde, 'DD/MM/YYYY'));
            DBMS_OUTPUT.PUT_LINE('État : ' || v_commande.etatcde);
        END IF;
        
        CLOSE c_commande;
    END CHERCHER_PAR_NUMERO;

    -- Procédure pour chercher les commandes d'un client
    PROCEDURE CHERCHER_PAR_CLIENT(
        p_noclt IN NUMBER
    ) IS
        CURSOR c_commandes IS
            SELECT c.nocde, c.datecde, c.etatcde
            FROM Commandes c
            WHERE c.noclt = p_noclt
            ORDER BY c.datecde DESC;
        
        v_count NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('===== COMMANDES DU CLIENT ' || p_noclt || ' =====');
        
        FOR rec IN c_commandes LOOP
            v_count := v_count + 1;
            DBMS_OUTPUT.PUT_LINE('Commande ' || rec.nocde || 
                ' - Date : ' || TO_CHAR(rec.datecde, 'DD/MM/YYYY') || 
                ' - État : ' || rec.etatcde);
        END LOOP;
        
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Aucune commande trouvée pour ce client');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Total : ' || v_count || ' commande(s)');
        END IF;
    END CHERCHER_PAR_CLIENT;

    -- Procédure pour chercher les commandes par date
    PROCEDURE CHERCHER_PAR_DATE(
        p_date IN DATE
    ) IS
        CURSOR c_commandes IS
            SELECT c.nocde, c.noclt, cl.nomclt, cl.prenomclt, c.etatcde
            FROM Commandes c
            JOIN Clients cl ON c.noclt = cl.noclt
            WHERE TRUNC(c.datecde) = TRUNC(p_date)
            ORDER BY c.nocde;
        
        v_count NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('===== COMMANDES DU ' || TO_CHAR(p_date, 'DD/MM/YYYY') || ' =====');
        
        FOR rec IN c_commandes LOOP
            v_count := v_count + 1;
            DBMS_OUTPUT.PUT_LINE('Commande ' || rec.nocde || 
                ' - Client : ' || rec.nomclt || ' ' || NVL(rec.prenomclt, '') ||
                ' - État : ' || rec.etatcde);
        END LOOP;
        
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Aucune commande trouvée pour cette date');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Total : ' || v_count || ' commande(s)');
        END IF;
    END CHERCHER_PAR_DATE;

END PKG_COMMANDES;
/