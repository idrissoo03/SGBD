-- =====================================================
-- PACKAGE GESTION DES ARTICLES
-- =====================================================

CREATE OR REPLACE PACKAGE PKG_ARTICLES AS
    -- Procédures publiques
    PROCEDURE AJOUTER_ARTICLE(
        p_designation IN VARCHAR2,
        p_prixA IN NUMBER,
        p_prixV IN NUMBER,
        p_codetva IN NUMBER,
        p_categorie IN VARCHAR2,
        p_qtestk IN NUMBER,
        p_refart OUT NUMBER
    );
    
    PROCEDURE MODIFIER_ARTICLE(
        p_refart IN NUMBER,
        p_designation IN VARCHAR2 DEFAULT NULL,
        p_prixA IN NUMBER DEFAULT NULL,
        p_prixV IN NUMBER DEFAULT NULL,
        p_codetva IN NUMBER DEFAULT NULL,
        p_categorie IN VARCHAR2 DEFAULT NULL
    );
    
    PROCEDURE SUPPRIMER_ARTICLE(
        p_refart IN NUMBER
    );
    
    PROCEDURE CHERCHER_PAR_CODE(
        p_refart IN NUMBER
    );
    
    PROCEDURE CHERCHER_PAR_DESIGNATION(
        p_designation IN VARCHAR2
    );
    
    PROCEDURE CHERCHER_PAR_CATEGORIE(
        p_categorie IN VARCHAR2
    );
    
    -- Fonction pour vérifier si l'article existe déjà
    FUNCTION ARTICLE_EXISTE(
        p_designation IN VARCHAR2,
        p_refart_exclure IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN;
    
    -- Fonction pour vérifier si l'article est utilisé dans des commandes
    FUNCTION ARTICLE_UTILISE(
        p_refart IN NUMBER
    ) RETURN BOOLEAN;
    
END PKG_ARTICLES;
/

CREATE OR REPLACE PACKAGE BODY PKG_ARTICLES AS

    -- Fonction pour vérifier si un article existe déjà (même désignation)
    FUNCTION ARTICLE_EXISTE(
        p_designation IN VARCHAR2,
        p_refart_exclure IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM Articles
        WHERE UPPER(designation) = UPPER(p_designation)
        AND supp = 'N'
        AND (p_refart_exclure IS NULL OR refart != p_refart_exclure);
        
        RETURN v_count > 0;
    END ARTICLE_EXISTE;

    -- Fonction pour vérifier si un article est utilisé dans des commandes
    FUNCTION ARTICLE_UTILISE(
        p_refart IN NUMBER
    ) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM LigCdes
        WHERE refart = p_refart;
        
        RETURN v_count > 0;
    END ARTICLE_UTILISE;

    -- Procédure pour ajouter un article
    PROCEDURE AJOUTER_ARTICLE(
        p_designation IN VARCHAR2,
        p_prixA IN NUMBER,
        p_prixV IN NUMBER,
        p_codetva IN NUMBER,
        p_categorie IN VARCHAR2,
        p_qtestk IN NUMBER,
        p_refart OUT NUMBER
    ) IS
    BEGIN
        -- Vérifier si le prix de vente est supérieur au prix d'achat
        IF p_prixV <= p_prixA THEN
            RAISE_APPLICATION_ERROR(-20201, PKG_MESSAGES.MSG_ART_PRICE_INVALID);
        END IF;
        
        -- Vérifier si l'article existe déjà
        IF ARTICLE_EXISTE(p_designation) THEN
            RAISE_APPLICATION_ERROR(-20202, PKG_MESSAGES.MSG_ART_ALREADY_EXISTS);
        END IF;
        
        -- Générer la référence
        p_refart := seq_refart.NEXTVAL;
        
        -- Insérer l'article
        INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
        VALUES (p_refart, p_designation, p_prixA, p_prixV, p_codetva, p_categorie, p_qtestk, 'N');
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_ART_ADDED || ' - Référence : ' || p_refart);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE BETWEEN -20202 AND -20201 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20203, PKG_MESSAGES.MSG_OPERATION_FAILED || ' : ' || SQLERRM);
            END IF;
    END AJOUTER_ARTICLE;

    -- Procédure pour modifier un article
    PROCEDURE MODIFIER_ARTICLE(
        p_refart IN NUMBER,
        p_designation IN VARCHAR2 DEFAULT NULL,
        p_prixA IN NUMBER DEFAULT NULL,
        p_prixV IN NUMBER DEFAULT NULL,
        p_codetva IN NUMBER DEFAULT NULL,
        p_categorie IN VARCHAR2 DEFAULT NULL
    ) IS
        v_count NUMBER;
        v_designation_actuelle VARCHAR2(100);
        v_prixA_actuel NUMBER;
        v_prixV_actuel NUMBER;
        v_codetva_actuel NUMBER;
        v_categorie_actuelle VARCHAR2(50);
        v_nouvelle_designation VARCHAR2(100);
        v_nouveau_prixA NUMBER;
        v_nouveau_prixV NUMBER;
        v_nouveau_codetva NUMBER;
        v_nouvelle_categorie VARCHAR2(50);
    BEGIN
        -- Vérifier si l'article existe
        SELECT COUNT(*), MAX(designation), MAX(prixA), MAX(prixV), MAX(codetva), MAX(categorie)
        INTO v_count, v_designation_actuelle, v_prixA_actuel, v_prixV_actuel, v_codetva_actuel, v_categorie_actuelle
        FROM Articles
        WHERE refart = p_refart AND supp = 'N';
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20204, PKG_MESSAGES.MSG_ART_NOT_FOUND);
        END IF;
        
        -- Déterminer les nouvelles valeurs
        v_nouvelle_designation := NVL(p_designation, v_designation_actuelle);
        v_nouveau_prixA := NVL(p_prixA, v_prixA_actuel);
        v_nouveau_prixV := NVL(p_prixV, v_prixV_actuel);
        v_nouveau_codetva := NVL(p_codetva, v_codetva_actuel);
        v_nouvelle_categorie := NVL(p_categorie, v_categorie_actuelle);
        
        -- Vérifier si le nouveau prix de vente est supérieur au nouveau prix d'achat
        IF v_nouveau_prixV <= v_nouveau_prixA THEN
            RAISE_APPLICATION_ERROR(-20205, PKG_MESSAGES.MSG_ART_PRICE_INVALID);
        END IF;
        
        -- Si la désignation change, vérifier qu'elle n'existe pas déjà
        IF p_designation IS NOT NULL AND UPPER(p_designation) != UPPER(v_designation_actuelle) THEN
            IF ARTICLE_EXISTE(p_designation, p_refart) THEN
                RAISE_APPLICATION_ERROR(-20206, PKG_MESSAGES.MSG_ART_ALREADY_EXISTS);
            END IF;
        END IF;
        
        -- Mettre à jour l'article
        UPDATE Articles
        SET designation = v_nouvelle_designation,
            prixA = v_nouveau_prixA,
            prixV = v_nouveau_prixV,
            codetva = v_nouveau_codetva,
            categorie = v_nouvelle_categorie
        WHERE refart = p_refart;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_ART_UPDATED);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE BETWEEN -20206 AND -20204 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20207, PKG_MESSAGES.MSG_OPERATION_FAILED || ' : ' || SQLERRM);
            END IF;
    END MODIFIER_ARTICLE;

    -- Procédure pour supprimer un article (logique ou physique)
    PROCEDURE SUPPRIMER_ARTICLE(
        p_refart IN NUMBER
    ) IS
        v_count NUMBER;
        v_est_utilise BOOLEAN;
    BEGIN
        -- Vérifier si l'article existe
        SELECT COUNT(*)
        INTO v_count
        FROM Articles
        WHERE refart = p_refart AND supp = 'N';
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20208, PKG_MESSAGES.MSG_ART_NOT_FOUND);
        END IF;
        
        -- Vérifier si l'article est utilisé dans des commandes
        v_est_utilise := ARTICLE_UTILISE(p_refart);
        
        IF v_est_utilise THEN
            -- Suppression logique
            UPDATE Articles
            SET supp = 'O'
            WHERE refart = p_refart;
            
            COMMIT;
            DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_ART_DELETED_LOGIC);
        ELSE
            -- Suppression physique
            DELETE FROM Articles
            WHERE refart = p_refart;
            
            COMMIT;
            DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_ART_DELETED_PHYSIC);
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE = -20208 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20209, PKG_MESSAGES.MSG_OPERATION_FAILED || ' : ' || SQLERRM);
            END IF;
    END SUPPRIMER_ARTICLE;

    -- Procédure pour chercher un article par code
    PROCEDURE CHERCHER_PAR_CODE(
        p_refart IN NUMBER
    ) IS
        CURSOR c_article IS
            SELECT refart, designation, prixA, prixV, codetva, categorie, qtestk, supp
            FROM Articles
            WHERE refart = p_refart;
        
        v_article c_article%ROWTYPE;
    BEGIN
        OPEN c_article;
        FETCH c_article INTO v_article;
        
        IF c_article%NOTFOUND THEN
            DBMS_OUTPUT.PUT_LINE(PKG_MESSAGES.MSG_ART_NOT_FOUND);
        ELSE
            DBMS_OUTPUT.PUT_LINE('===== DÉTAILS DE L''ARTICLE =====');
            DBMS_OUTPUT.PUT_LINE('Référence : ' || v_article.refart);
            DBMS_OUTPUT.PUT_LINE('Désignation : ' || v_article.designation);
            DBMS_OUTPUT.PUT_LINE('Prix achat : ' || v_article.prixA || ' DT');
            DBMS_OUTPUT.PUT_LINE('Prix vente : ' || v_article.prixV || ' DT');
            DBMS_OUTPUT.PUT_LINE('TVA : ' || v_article.codetva || '%');
            DBMS_OUTPUT.PUT_LINE('Catégorie : ' || v_article.categorie);
            DBMS_OUTPUT.PUT_LINE('Stock : ' || v_article.qtestk);
            DBMS_OUTPUT.PUT_LINE('Supprimé : ' || CASE v_article.supp WHEN 'O' THEN 'Oui' ELSE 'Non' END);
        END IF;
        
        CLOSE c_article;
    END CHERCHER_PAR_CODE;

    -- Procédure pour chercher des articles par désignation
    PROCEDURE CHERCHER_PAR_DESIGNATION(
        p_designation IN VARCHAR2
    ) IS
        CURSOR c_articles IS
            SELECT refart, designation, prixV, categorie, qtestk
            FROM Articles
            WHERE UPPER(designation) LIKE '%' || UPPER(p_designation) || '%'
            AND supp = 'N'
            ORDER BY designation;
        
        v_count NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('===== ARTICLES CONTENANT "' || p_designation || '" =====');
        
        FOR rec IN c_articles LOOP
            v_count := v_count + 1;
            DBMS_OUTPUT.PUT_LINE('Réf: ' || rec.refart || 
                ' - ' || rec.designation ||
                ' - Prix: ' || rec.prixV || ' DT' ||
                ' - Cat: ' || rec.categorie ||
                ' - Stock: ' || rec.qtestk);
        END LOOP;
        
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Aucun article trouvé');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Total : ' || v_count || ' article(s)');
        END IF;
    END CHERCHER_PAR_DESIGNATION;

    -- Procédure pour chercher des articles par catégorie
    PROCEDURE CHERCHER_PAR_CATEGORIE(
        p_categorie IN VARCHAR2
    ) IS
        CURSOR c_articles IS
            SELECT refart, designation, prixV, qtestk
            FROM Articles
            WHERE UPPER(categorie) = UPPER(p_categorie)
            AND supp = 'N'
            ORDER BY designation;
        
        v_count NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('===== ARTICLES DE LA CATÉGORIE "' || p_categorie || '" =====');
        
        FOR rec IN c_articles LOOP
            v_count := v_count + 1;
            DBMS_OUTPUT.PUT_LINE('Réf: ' || rec.refart ||
                ' - ' || rec.designation ||
                ' - Prix: ' || rec.prixV || ' DT' ||
                ' - Stock: ' || rec.qtestk);
        END LOOP;
        
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Aucun article trouvé');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Total : ' || v_count || ' article(s)');
        END IF;
    END CHERCHER_PAR_CATEGORIE;

END PKG_ARTICLES;
/