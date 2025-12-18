-- =====================================================
-- SCRIPT DE CRÉATION DE LA BASE DE DONNÉES
-- Système de Gestion de Livraison des Commandes
-- =====================================================

-- Suppression des tables si elles existent
DROP TABLE LivraisonCom CASCADE CONSTRAINTS;
DROP TABLE LigCdes CASCADE CONSTRAINTS;
DROP TABLE Commandes CASCADE CONSTRAINTS;
DROP TABLE Articles CASCADE CONSTRAINTS;
DROP TABLE Clients CASCADE CONSTRAINTS;
DROP TABLE Personnel CASCADE CONSTRAINTS;
DROP TABLE Poste CASCADE CONSTRAINTS;
DROP TABLE HCommandesAnnulees CASCADE CONSTRAINTS;

-- Suppression des séquences
DROP SEQUENCE seq_refart;
DROP SEQUENCE seq_noclt;
DROP SEQUENCE seq_nocde;
DROP SEQUENCE seq_idpers;
DROP SEQUENCE seq_codeposte;

-- =====================================================
-- CRÉATION DES SÉQUENCES
-- =====================================================

CREATE SEQUENCE seq_refart START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_noclt START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_nocde START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_idpers START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_codeposte START WITH 1 INCREMENT BY 1;

-- =====================================================
-- CRÉATION DES TABLES
-- =====================================================

-- Table Poste
CREATE TABLE Poste (
    codeposte NUMBER PRIMARY KEY,
    libelle VARCHAR2(50) NOT NULL,
    indice NUMBER(3,2)
);

-- Table Personnel
CREATE TABLE Personnel (
    idpers NUMBER PRIMARY KEY,
    nompers VARCHAR2(50) NOT NULL,
    prenompers VARCHAR2(50) NOT NULL,
    adrpers VARCHAR2(100),
    villepers VARCHAR2(50),
    telpers VARCHAR2(20),
    d_embauche DATE DEFAULT SYSDATE,
    login VARCHAR2(30) NOT NULL UNIQUE,
    motP VARCHAR2(50) NOT NULL,
    codeposte NUMBER,
    CONSTRAINT fk_pers_poste FOREIGN KEY (codeposte) REFERENCES Poste(codeposte)
);

-- Table Articles (avec attribut supp pour suppression logique)
CREATE TABLE Articles (
    refart NUMBER PRIMARY KEY,
    designation VARCHAR2(100) NOT NULL,
    prixA NUMBER(10,2) NOT NULL,
    prixV NUMBER(10,2) NOT NULL,
    codetva NUMBER(4,2) DEFAULT 19,
    categorie VARCHAR2(50),
    qtestk NUMBER DEFAULT 0,
    supp CHAR(1) DEFAULT 'N' CHECK (supp IN ('O', 'N')),
    CONSTRAINT chk_prix CHECK (prixV > prixA)
);

-- Table Clients
CREATE TABLE Clients (
    noclt NUMBER PRIMARY KEY,
    nomclt VARCHAR2(100) NOT NULL,
    prenomclt VARCHAR2(50),
    adrclt VARCHAR2(150),
    code_postal VARCHAR2(10),
    telclt VARCHAR2(20),
    adrmail VARCHAR2(100)
);

-- Table Commandes
CREATE TABLE Commandes (
    nocde NUMBER PRIMARY KEY,
    noclt NUMBER NOT NULL,
    datecde DATE DEFAULT SYSDATE,
    etatcde VARCHAR2(2) DEFAULT 'EC' CHECK (etatcde IN ('EC', 'PR', 'LI', 'SO', 'AN', 'AL')),
    CONSTRAINT fk_cde_clt FOREIGN KEY (noclt) REFERENCES Clients(noclt)
);

-- Table LigCdes
CREATE TABLE LigCdes (
    nocde NUMBER,
    refart NUMBER,
    qtecde NUMBER NOT NULL,
    CONSTRAINT pk_ligcdes PRIMARY KEY (nocde, refart),
    CONSTRAINT fk_ligcde_cde FOREIGN KEY (nocde) REFERENCES Commandes(nocde) ON DELETE CASCADE,
    CONSTRAINT fk_ligcde_art FOREIGN KEY (refart) REFERENCES Articles(refart)
);

-- Table LivraisonCom
CREATE TABLE LivraisonCom (
    nocde NUMBER PRIMARY KEY,
    dateliv DATE NOT NULL,
    livreur NUMBER NOT NULL,
    modepay VARCHAR2(20),
    etaliv VARCHAR2(2) DEFAULT 'EP' CHECK (etaliv IN ('EP', 'EL', 'LV')),
    CONSTRAINT fk_liv_cde FOREIGN KEY (nocde) REFERENCES Commandes(nocde),
    CONSTRAINT fk_liv_pers FOREIGN KEY (livreur) REFERENCES Personnel(idpers)
);

-- Table Historique des commandes annulées
CREATE TABLE HCommandesAnnulees (
    nocde NUMBER PRIMARY KEY,
    noclt NUMBER,
    datecde DATE,
    dateannulation DATE DEFAULT SYSDATE,
    avantliv CHAR(1) DEFAULT 'O' CHECK (avantliv IN ('O', 'N')),
    CONSTRAINT fk_hcde_clt FOREIGN KEY (noclt) REFERENCES Clients(noclt)
);

-- =====================================================
-- CRÉATION DES INDEX
-- =====================================================

-- Index sur les clés étrangères pour améliorer les jointures
CREATE INDEX idx_pers_poste ON Personnel(codeposte);
CREATE INDEX idx_cde_clt ON Commandes(noclt);
CREATE INDEX idx_cde_date ON Commandes(datecde);
CREATE INDEX idx_cde_etat ON Commandes(etatcde);
CREATE INDEX idx_ligcde_art ON LigCdes(refart);
CREATE INDEX idx_liv_livreur ON LivraisonCom(livreur);
CREATE INDEX idx_liv_date ON LivraisonCom(dateliv);
CREATE INDEX idx_art_designation ON Articles(designation);
CREATE INDEX idx_art_categorie ON Articles(categorie);
CREATE INDEX idx_clt_nom ON Clients(nomclt);
CREATE INDEX idx_clt_codepostal ON Clients(code_postal);

-- Index composé pour optimiser les recherches fréquentes
CREATE INDEX idx_liv_livreur_date ON LivraisonCom(livreur, dateliv);

COMMIT;