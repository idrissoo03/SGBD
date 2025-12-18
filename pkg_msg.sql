-- =====================================================
-- PACKAGE DES MESSAGES
-- =====================================================

CREATE OR REPLACE PACKAGE PKG_MESSAGES AS
    -- Messages généraux
    MSG_OPERATION_SUCCESS CONSTANT VARCHAR2(100) := 'Opération effectuée avec succès';
    MSG_OPERATION_FAILED CONSTANT VARCHAR2(100) := 'Échec de l''opération';
    MSG_RECORD_NOT_FOUND CONSTANT VARCHAR2(100) := 'Enregistrement introuvable';
    MSG_INVALID_DATA CONSTANT VARCHAR2(100) := 'Données invalides';
    
    -- Messages Commandes
    MSG_CDE_ADDED CONSTANT VARCHAR2(100) := 'Commande ajoutée avec succès';
    MSG_CDE_UPDATED CONSTANT VARCHAR2(100) := 'Commande modifiée avec succès';
    MSG_CDE_CANCELLED CONSTANT VARCHAR2(100) := 'Commande annulée avec succès';
    MSG_CDE_NOT_FOUND CONSTANT VARCHAR2(100) := 'Commande introuvable';
    MSG_CDE_INVALID_STATE CONSTANT VARCHAR2(150) := 'Transition d''état invalide pour cette commande';
    MSG_CDE_CLIENT_NOT_FOUND CONSTANT VARCHAR2(100) := 'Client introuvable';
    MSG_CDE_ALREADY_CANCELLED CONSTANT VARCHAR2(100) := 'Commande déjà annulée';
    MSG_CDE_ALREADY_DELIVERED CONSTANT VARCHAR2(100) := 'Commande déjà livrée, annulation impossible';
    
    -- Messages Livraisons
    MSG_LIV_ADDED CONSTANT VARCHAR2(100) := 'Livraison ajoutée avec succès';
    MSG_LIV_UPDATED CONSTANT VARCHAR2(100) := 'Livraison modifiée avec succès';
    MSG_LIV_CANCELLED CONSTANT VARCHAR2(100) := 'Livraison annulée avec succès';
    MSG_LIV_NOT_FOUND CONSTANT VARCHAR2(100) := 'Livraison introuvable';
    MSG_LIV_CDE_NOT_READY CONSTANT VARCHAR2(150) := 'Commande non prête pour la livraison (état doit être PR)';
    MSG_LIV_LIVREUR_LIMIT CONSTANT VARCHAR2(150) := 'Le livreur a atteint la limite de 15 livraisons par jour pour cette ville';
    MSG_LIV_LIVREUR_NOT_FOUND CONSTANT VARCHAR2(100) := 'Livreur introuvable';
    MSG_LIV_TIME_RESTRICTION CONSTANT VARCHAR2(200) := 'Modification impossible : doit être avant 9h pour livraisons du matin ou avant 14h pour l''après-midi';
    MSG_LIV_INVALID_DATE CONSTANT VARCHAR2(150) := 'Date de livraison invalide';
    
    -- Messages Articles
    MSG_ART_ADDED CONSTANT VARCHAR2(100) := 'Article ajouté avec succès';
    MSG_ART_UPDATED CONSTANT VARCHAR2(100) := 'Article modifié avec succès';
    MSG_ART_DELETED_LOGIC CONSTANT VARCHAR2(150) := 'Article supprimé logiquement (utilisé dans des commandes)';
    MSG_ART_DELETED_PHYSIC CONSTANT VARCHAR2(100) := 'Article supprimé physiquement avec succès';
    MSG_ART_NOT_FOUND CONSTANT VARCHAR2(100) := 'Article introuvable';
    MSG_ART_ALREADY_EXISTS CONSTANT VARCHAR2(150) := 'Article existe déjà (même désignation)';
    MSG_ART_PRICE_INVALID CONSTANT VARCHAR2(150) := 'Prix de vente doit être supérieur au prix d''achat';
    MSG_ART_IN_USE CONSTANT VARCHAR2(150) := 'Article utilisé dans des commandes, suppression logique effectuée';
    
    -- Messages Validations
    MSG_PHONE_INVALID CONSTANT VARCHAR2(100) := 'Format du numéro de téléphone invalide';
    MSG_LOGIN_REQUIRED CONSTANT VARCHAR2(100) := 'Login obligatoire';
    MSG_PASSWORD_REQUIRED CONSTANT VARCHAR2(100) := 'Mot de passe obligatoire';
    MSG_DUPLICATE_ENTRY CONSTANT VARCHAR2(100) := 'Enregistrement en double détecté';
    
    -- Procédure pour afficher les messages
    PROCEDURE AFFICHER_MESSAGE(p_message VARCHAR2);
    
END PKG_MESSAGES;
/

CREATE OR REPLACE PACKAGE BODY PKG_MESSAGES AS
    PROCEDURE AFFICHER_MESSAGE(p_message VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(p_message);
    END AFFICHER_MESSAGE;
END PKG_MESSAGES;
/