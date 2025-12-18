-- =====================================================
-- SCRIPT D'INSERTION DES DONNÉES
-- =====================================================

-- Insertion dans la table Poste
INSERT INTO Poste VALUES (seq_codeposte.NEXTVAL, 'Administrateur', 1.00);
INSERT INTO Poste VALUES (seq_codeposte.NEXTVAL, 'Magasinier', 0.85);
INSERT INTO Poste VALUES (seq_codeposte.NEXTVAL, 'Chef Livreur', 0.90);
INSERT INTO Poste VALUES (seq_codeposte.NEXTVAL, 'Livreur', 0.75);
INSERT INTO Poste VALUES (seq_codeposte.NEXTVAL, 'Comptable', 0.88);

-- Insertion dans la table Personnel
INSERT INTO Personnel (idpers, nompers, prenompers, adrpers, villepers, telpers, d_embauche, login, motP, codeposte)
VALUES (seq_idpers.NEXTVAL, 'Ben Ahmed', 'Mohamed', '15 Rue de la Liberté', 'Tunis', '+21612345678', TO_DATE('2020-01-15', 'YYYY-MM-DD'), 'admin1', 'Admin@123', 1);

INSERT INTO Personnel (idpers, nompers, prenompers, adrpers, villepers, telpers, d_embauche, login, motP, codeposte)
VALUES (seq_idpers.NEXTVAL, 'Trabelsi', 'Fatma', '25 Avenue Habib Bourguiba', 'Sfax', '+21698765432', TO_DATE('2021-03-20', 'YYYY-MM-DD'), 'magasinier1', 'Mag@2021', 2);

INSERT INTO Personnel (idpers, nompers, prenompers, adrpers, villepers, telpers, d_embauche, login, motP, codeposte)
VALUES (seq_idpers.NEXTVAL, 'Mansour', 'Ali', '30 Rue de Carthage', 'Tunis', '+21623456789', TO_DATE('2019-06-10', 'YYYY-MM-DD'), 'cheflivreur1', 'Chef@2019', 3);

INSERT INTO Personnel (idpers, nompers, prenompers, adrpers, villepers, telpers, d_embauche, login, motP, codeposte)
VALUES (seq_idpers.NEXTVAL, 'Gharbi', 'Sami', '40 Avenue de la République', 'Ariana', '+21634567890', TO_DATE('2022-02-15', 'YYYY-MM-DD'), 'livreur1', 'Liv@2022', 4);

INSERT INTO Personnel (idpers, nompers, prenompers, adrpers, villepers, telpers, d_embauche, login, motP, codeposte)
VALUES (seq_idpers.NEXTVAL, 'Khemiri', 'Ines', '50 Rue de Paris', 'Ben Arous', '+21645678901', TO_DATE('2021-09-01', 'YYYY-MM-DD'), 'livreur2', 'Liv@2021', 4);

INSERT INTO Personnel (idpers, nompers, prenompers, adrpers, villepers, telpers, d_embauche, login, motP, codeposte)
VALUES (seq_idpers.NEXTVAL, 'Sassi', 'Karim', '60 Avenue Jugurtha', 'Manouba', '+21656789012', TO_DATE('2022-05-20', 'YYYY-MM-DD'), 'livreur3', 'Liv@2022b', 4);

INSERT INTO Personnel (idpers, nompers, prenompers, adrpers, villepers, telpers, d_embauche, login, motP, codeposte)
VALUES (seq_idpers.NEXTVAL, 'Bouazizi', 'Nadia', '70 Rue de Sousse', 'Tunis', '+21667890123', TO_DATE('2020-11-10', 'YYYY-MM-DD'), 'comptable1', 'Comp@2020', 5);

INSERT INTO Personnel (idpers, nompers, prenompers, adrpers, villepers, telpers, d_embauche, login, motP, codeposte)
VALUES (seq_idpers.NEXTVAL, 'Maalej', 'Yassine', '80 Avenue de Carthage', 'La Marsa', '+21678901234', TO_DATE('2023-01-15', 'YYYY-MM-DD'), 'livreur4', 'Liv@2023', 4);

INSERT INTO Personnel (idpers, nompers, prenompers, adrpers, villepers, telpers, d_embauche, login, motP, codeposte)
VALUES (seq_idpers.NEXTVAL, 'Jebali', 'Rim', '90 Rue de Bizerte', 'Tunis', '+21689012345', TO_DATE('2021-07-01', 'YYYY-MM-DD'), 'magasinier2', 'Mag@2021b', 2);

INSERT INTO Personnel (idpers, nompers, prenompers, adrpers, villepers, telpers, d_embauche, login, motP, codeposte)
VALUES (seq_idpers.NEXTVAL, 'Hamdi', 'Mehdi', '100 Avenue Farhat Hached', 'Sfax', '+21690123456', TO_DATE('2022-08-20', 'YYYY-MM-DD'), 'livreur5', 'Liv@2022c', 4);

-- Insertion dans la table Articles
INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'Samsung Galaxy S23', 800.00, 1200.00, 19.00, 'Smartphone', 50, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'iPhone 15 Pro', 1000.00, 1500.00, 19.00, 'Smartphone', 30, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'Dell XPS 15', 1200.00, 1800.00, 19.00, 'Ordinateur Portable', 25, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'HP Pavilion Gaming', 700.00, 1100.00, 19.00, 'Ordinateur Portable', 40, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'Sony WH-1000XM5', 250.00, 400.00, 19.00, 'Audio', 60, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'AirPods Pro 2', 180.00, 280.00, 19.00, 'Audio', 80, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'Samsung 55" QLED TV', 600.00, 950.00, 19.00, 'Télévision', 20, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'PlayStation 5', 400.00, 600.00, 19.00, 'Console de Jeu', 35, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'iPad Air 2024', 500.00, 750.00, 19.00, 'Tablette', 45, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'Logitech MX Master 3', 70.00, 120.00, 19.00, 'Accessoire', 100, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'Canon EOS R6', 1800.00, 2500.00, 19.00, 'Appareil Photo', 15, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'Apple Watch Series 9', 300.00, 450.00, 19.00, 'Montre Connectée', 55, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'Samsung Galaxy Buds', 80.00, 140.00, 19.00, 'Audio', 90, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'Nintendo Switch OLED', 280.00, 400.00, 19.00, 'Console de Jeu', 40, 'N');

INSERT INTO Articles (refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
VALUES (seq_refart.NEXTVAL, 'Xiaomi Robot Vacuum', 200.00, 320.00, 19.00, 'Électroménager', 30, 'N');

-- Insertion dans la table Clients
INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Jendoubi', 'Ahmed', '12 Rue de la Médina', '1000', '+21620111222', 'ahmed.jendoubi@email.tn');

INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Kouki', 'Sarra', '25 Avenue Mohamed V', '2000', '+21621222333', 'sarra.kouki@email.tn');

INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Ben Salah', 'Hichem', '38 Rue de la Kasbah', '1002', '+21622333444', 'hichem.bensalah@email.tn');

INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Technologie Plus SARL', NULL, '50 Zone Industrielle', '2035', '+21623444555', 'contact@techplus.tn');

INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Ayari', 'Lamia', '15 Avenue Habib Thameur', '1008', '+21624555666', 'lamia.ayari@email.tn');

INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Informatique Services SA', NULL, '60 Rue de la Liberté', '1002', '+21625666777', 'info@infoservices.tn');

INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Mahjoub', 'Rania', '22 Avenue de France', '2000', '+21626777888', 'rania.mahjoub@email.tn');

INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Dridi', 'Fares', '77 Rue Ibn Khaldoun', '1003', '+21627888999', 'fares.dridi@email.tn');

INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Chaabane', 'Najla', '33 Avenue de Carthage', '2025', '+21628999000', 'najla.chaabane@email.tn');

INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Digital World SARL', NULL, '88 Zone Industrielle', '1082', '+21629000111', 'contact@digitalworld.tn');

INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Zaied', 'Malek', '44 Rue de Tunis', '2060', '+21630111222', 'malek.zaied@email.tn');

INSERT INTO Clients (noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
VALUES (seq_noclt.NEXTVAL, 'Hammouda', 'Yasmine', '55 Avenue Bourguiba', '1001', '+21631222333', 'yasmine.hammouda@email.tn');

-- Insertion dans la table Commandes
INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 1, SYSDATE-10, 'LI');

INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 2, SYSDATE-8, 'SO');

INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 3, SYSDATE-5, 'PR');

INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 4, SYSDATE-3, 'PR');

INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 5, SYSDATE-2, 'EC');

INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 1, SYSDATE-15, 'SO');

INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 6, SYSDATE-7, 'PR');

INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 7, SYSDATE-4, 'EC');

INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 8, SYSDATE-6, 'LI');

INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 9, SYSDATE-1, 'EC');

INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 10, SYSDATE-12, 'SO');

INSERT INTO Commandes (nocde, noclt, datecde, etatcde)
VALUES (seq_nocde.NEXTVAL, 11, SYSDATE-9, 'LI');

-- Insertion dans la table LigCdes
INSERT INTO LigCdes VALUES (1, 1, 2);
INSERT INTO LigCdes VALUES (1, 5, 1);
INSERT INTO LigCdes VALUES (2, 3, 1);
INSERT INTO LigCdes VALUES (2, 9, 1);
INSERT INTO LigCdes VALUES (3, 2, 1);
INSERT INTO LigCdes VALUES (4, 7, 1);
INSERT INTO LigCdes VALUES (4, 8, 1);
INSERT INTO LigCdes VALUES (5, 4, 2);
INSERT INTO LigCdes VALUES (6, 6, 3);
INSERT INTO LigCdes VALUES (7, 10, 5);
INSERT INTO LigCdes VALUES (8, 11, 1);
INSERT INTO LigCdes VALUES (9, 12, 2);
INSERT INTO LigCdes VALUES (10, 13, 1);
INSERT INTO LigCdes VALUES (11, 14, 1);
INSERT INTO LigCdes VALUES (12, 15, 1);

-- Insertion dans la table LivraisonCom
INSERT INTO LivraisonCom (nocde, dateliv, livreur, modepay, etaliv)
VALUES (1, SYSDATE-9, 4, 'Espèces', 'LV');

INSERT INTO LivraisonCom (nocde, dateliv, livreur, modepay, etaliv)
VALUES (2, SYSDATE-7, 5, 'Carte', 'LV');

INSERT INTO LivraisonCom (nocde, dateliv, livreur, modepay, etaliv)
VALUES (9, SYSDATE-5, 6, 'Espèces', 'LV');

INSERT INTO LivraisonCom (nocde, dateliv, livreur, modepay, etaliv)
VALUES (12, SYSDATE-8, 8, 'Carte', 'LV');

COMMIT;