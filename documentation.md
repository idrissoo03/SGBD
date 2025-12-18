# Projet SGBD - Système de Gestion de Livraison des Commandes

## 📋 Table des matières

1. [Introduction](#introduction)
2. [Architecture de la base de données](#architecture)
3. [Règles d'intégrité implémentées](#regles)
4. [Packages développés](#packages)
5. [Triggers](#triggers)
6. [Sécurité et privilèges](#securite)
7. [Guide d'utilisation](#utilisation)
8. [Tests](#tests)

---

## 1. Introduction {#introduction}

Ce projet implémente un système complet de gestion de livraison de commandes avec Oracle PL/SQL. Il couvre trois cas d'utilisation principaux :

- ✅ **Gestion des Commandes** (Obligatoire)
- ✅ **Gestion des Livraisons** (Obligatoire)
- ✅ **Gestion des Articles** (Choix personnel)

### Technologies utilisées
- Oracle Database (PL/SQL)
- Packages PL/SQL
- Triggers
- Séquences
- Vues
- Index

---

## 2. Architecture de la base de données {#architecture}

### Schéma relationnel

```
Articles(refart, designation, prixA, prixV, codetva, categorie, qtestk, supp)
Clients(noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail)
Commandes(nocde, #noclt, datecde, etatcde)
LigCdes(#nocde, #refart, qtecde)
LivraisonCom(#nocde, dateliv, #livreur, modepay, etaliv)
Personnel(idpers, nompers, prenompers, adrpers, villepers, telpers, d_embauche, login, motP, #codeposte)
Poste(codeposte, libelle, indice)
HCommandesAnnulees(nocde, noclt, datecde, dateannulation, avantliv)
```

### États des commandes

| Code | Signification |
|------|---------------|
| EC | En Cours |
| PR | Prête |
| LI | En Livraison |
| SO | Sortie/Livrée |
| AN | Annulée |
| AL | Annulée par Livreur |

### Transitions d'état autorisées

```
EC → PR → LI → SO
EC → AN
PR → AN
PR → AL
```

### Séquences créées

- `seq_refart` : Pour les références d'articles
- `seq_noclt` : Pour les numéros de clients
- `seq_nocde` : Pour les numéros de commandes
- `seq_idpers` : Pour les identifiants du personnel
- `seq_codeposte` : Pour les codes de postes

### Index créés

```sql
-- Index sur clés étrangères
CREATE INDEX idx_pers_poste ON Personnel(codeposte);
CREATE INDEX idx_cde_clt ON Commandes(noclt);
CREATE INDEX idx_ligcde_art ON LigCdes(refart);
CREATE INDEX idx_liv_livreur ON LivraisonCom(livreur);

-- Index sur colonnes fréquemment recherchées
CREATE INDEX idx_cde_date ON Commandes(datecde);
CREATE INDEX idx_cde_etat ON Commandes(etatcde);
CREATE INDEX idx_liv_date ON LivraisonCom(dateliv);
CREATE INDEX idx_art_designation ON Articles(designation);
CREATE INDEX idx_art_categorie ON Articles(categorie);
CREATE INDEX idx_clt_nom ON Clients(nomclt);
CREATE INDEX idx_clt_codepostal ON Clients(code_postal);

-- Index composé pour optimisation
CREATE INDEX idx_liv_livreur_date ON LivraisonCom(livreur, dateliv);
```

---

## 3. Règles d'intégrité implémentées {#regles}

### Table Personnel

✓ **Login et mot de passe obligatoires** (Trigger `trg_pers_login_motP`)
- Validation que le login n'est ni NULL ni vide
- Validation que le mot de passe n'est ni NULL ni vide

✓ **Format du téléphone** (Trigger `trg_pers_tel`)
- Format tunisien : `+216XXXXXXXX` ou `00216XXXXXXXX`
- Validation par expression régulière

### Table Articles

✓ **Prix de vente > prix d'achat** (Trigger `trg_art_prix`)
- Vérifié lors de l'insertion et de la mise à jour

✓ **Pas de doublon** (Trigger `trg_art_doublon`)
- Un article ne peut être ajouté qu'une seule fois (même désignation)
- Ignore les articles supprimés logiquement

✓ **Suppression logique/physique**
- Suppression logique si l'article est utilisé dans des commandes
- Suppression physique sinon
- Géré dans le package `PKG_ARTICLES`

### Table Clients

✓ **Format du téléphone** (Trigger `trg_clt_tel`)
- Même validation que pour le personnel

✓ **Pas de doublon** (Trigger `trg_clt_doublon`)
- Vérification sur nom + prénom + email

### Table Commandes

✓ **Date = date système** (Trigger `trg_cde_date`)
- Force la date de commande à SYSDATE lors de l'insertion

✓ **État initial = 'EC'** (Trigger `trg_cde_etat`)
- Initialise automatiquement l'état à 'EC'

✓ **Transitions d'état contrôlées**
- Fonction `VERIFIER_TRANSITION_ETAT` dans `PKG_COMMANDES`

### Table LivraisonCom

✓ **Commande doit être prête** (Trigger `trg_liv_etat_commande`)
- Vérifie que l'état de la commande est 'PR'

✓ **Limite de 15 livraisons/jour/ville** (Trigger `trg_liv_limite`)
- Un livreur ne peut avoir plus de 15 livraisons par jour pour une même ville

✓ **Restrictions horaires** (Trigger `trg_liv_horaire`)
- Modifications avant 9h pour livraisons du matin
- Modifications avant 14h pour livraisons de l'après-midi

---

## 4. Packages développés {#packages}

### PKG_MESSAGES

Package centralisant tous les messages de l'application.

**Avantages :**
- Maintenance simplifiée
- Cohérence des messages
- Facilite la traduction

**Structure :**
```sql
PKG_MESSAGES
├── Messages généraux
├── Messages Commandes
├── Messages Livraisons
├── Messages Articles
└── Messages Validations
```

### PKG_COMMANDES

Gestion complète des commandes.

**Procédures :**

1. **AJOUTER_COMMANDE**(p_noclt, p_nocde OUT)
   - Crée une nouvelle commande
   - État initial : 'EC'
   - Date : SYSDATE

2. **MODIFIER_ETAT_COMMANDE**(p_nocde, p_nouvel_etat)
   - Modifie l'état d'une commande
   - Vérifie la transition d'état

3. **ANNULER_COMMANDE**(p_nocde)
   - Annulation logique (état → 'AN')
   - Enregistrement dans HCommandesAnnulees

4. **CHERCHER_PAR_NUMERO**(p_nocde)
5. **CHERCHER_PAR_CLIENT**(p_noclt)
6. **CHERCHER_PAR_DATE**(p_date)

**Fonction :**
- **VERIFIER_TRANSITION_ETAT**(p_etat_actuel, p_nouvel_etat) → BOOLEAN

### PKG_LIVRAISONS

Gestion complète des livraisons.

**Procédures :**

1. **AJOUTER_LIVRAISON**(p_nocde, p_dateliv, p_livreur, p_modepay)
   - Ajoute une nouvelle livraison
   - Vérifie toutes les contraintes
   - Met à jour l'état de la commande

2. **MODIFIER_LIVRAISON**(p_nocde, p_nouvelle_date, p_nouveau_livreur)
   - Modifie date et/ou livreur
   - Vérifie les restrictions horaires

3. **SUPPRIMER_LIVRAISON**(p_nocde)
   - Annule une livraison
   - Met à jour la commande (état → 'AN')

4. **CHERCHER_PAR_COMMANDE**(p_nocde)
5. **CHERCHER_PAR_LIVREUR**(p_livreur)
6. **CHERCHER_PAR_VILLE**(p_code_postal)
7. **CHERCHER_PAR_DATE**(p_date)

**Fonctions :**
- **VERIFIER_LIMITE_LIVREUR** → BOOLEAN
- **VERIFIER_RESTRICTION_HORAIRE** → BOOLEAN

### PKG_ARTICLES

Gestion complète des articles.

**Procédures :**

1. **AJOUTER_ARTICLE**(designation, prixA, prixV, codetva, categorie, qtestk, refart OUT)
   - Ajoute un nouvel article
   - Vérifie les doublons
   - Valide les prix

2. **MODIFIER_ARTICLE**(refart, designation, prixA, prixV, codetva, categorie)
   - Modifie les attributs autorisés
   - Paramètres optionnels (NULL = pas de modification)

3. **SUPPRIMER_ARTICLE**(refart)
   - Suppression logique si utilisé
   - Suppression physique sinon

4. **CHERCHER_PAR_CODE**(refart)
5. **CHERCHER_PAR_DESIGNATION**(designation)
6. **CHERCHER_PAR_CATEGORIE**(categorie)

**Fonctions :**
- **ARTICLE_EXISTE** → BOOLEAN
- **ARTICLE_UTILISE** → BOOLEAN

---

## 5. Triggers {#triggers}

### Triggers de validation

| Trigger | Table | Fonction |
|---------|-------|----------|
| trg_pers_login_motP | Personnel | Valide login et mot de passe |
| trg_pers_tel | Personnel | Valide format téléphone |
| trg_art_prix | Articles | Vérifie prixV > prixA |
| trg_art_doublon | Articles | Empêche les doublons |
| trg_clt_tel | Clients | Valide format téléphone |
| trg_clt_doublon | Clients | Empêche les doublons |
| trg_cde_date | Commandes | Force date = SYSDATE |
| trg_cde_etat | Commandes | Initialise état = 'EC' |
| trg_liv_etat_commande | LivraisonCom | Vérifie état = 'PR' |
| trg_liv_limite | LivraisonCom | Limite 15 livraisons |
| trg_liv_horaire | LivraisonCom | Restrictions horaires |

### Triggers d'audit

- **trg_audit_art_supp** : Enregistre les suppressions logiques d'articles

### Triggers automatiques

- **trg_liv_maj_etat_cde** : Met à jour l'état de la commande à 'LI' lors de l'ajout d'une livraison

---

## 6. Sécurité et privilèges {#securite}

### Vues créées

**Pour les clients :**
- `V_CLIENT_COMMANDES` : Leurs commandes
- `V_CLIENT_LIGNES_COMMANDES` : Détails des commandes
- `V_CLIENT_LIVRAISONS` : Suivi des livraisons
- `V_CATALOGUE_ARTICLES` : Catalogue produits

**Pour le personnel :**
- `V_STATS_COMMANDES` : Statistiques
- `V_LIVRAISONS_JOUR` : Livraisons du jour
- `V_ARTICLES_RUPTURE` : Articles en rupture
- `V_CHARGE_LIVREURS` : Charge de travail

### Rôles et privilèges

**Administrateur :**
- Tous les droits sur toutes les tables
- Exécution de tous les packages

**Magasinier :**
- Gestion des articles (SELECT, INSERT, UPDATE)
- Consultation des commandes
- Packages : PKG_ARTICLES, PKG_COMMANDES

**Chef Livreur :**
- Gestion des livraisons
- Consultation des données
- Packages : PKG_LIVRAISONS, PKG_COMMANDES

**Client :**
- Lecture seule via les vues
- Accès limité à ses propres données

---

## 7. Guide d'utilisation {#utilisation}

### Installation

1. Exécuter dans l'ordre :
```sql
-- 1. Création de la BD
@1_creation_bd.sql

-- 2. Insertion des données
@2_insertion_donnees.sql

-- 3. Package messages
@3_pkg_messages.sql

-- 4. Package commandes
@4_pkg_commandes.sql

-- 5. Package livraisons
@5_pkg_livraisons.sql

-- 6. Package articles
@6_pkg_articles.sql

-- 7. Triggers
@7_triggers.sql

-- 8. Vues et sécurité
@9_vues_securite.sql
```

### Exemples d'utilisation

**Ajouter une commande :**
```sql
DECLARE
    v_nocde NUMBER;
BEGIN
    PKG_COMMANDES.AJOUTER_COMMANDE(1, v_nocde);
    DBMS_OUTPUT.PUT_LINE('Commande créée : ' || v_nocde);
END;
/
```

**Modifier l'état d'une commande :**
```sql
BEGIN
    PKG_COMMANDES.MODIFIER_ETAT_COMMANDE(1, 'PR');
END;
/
```

**Ajouter une livraison :**
```sql
BEGIN
    PKG_LIVRAISONS.AJOUTER_LIVRAISON(
        p_nocde => 1,
        p_dateliv => SYSDATE + 1,
        p_livreur => 4,
        p_modepay => 'Espèces'
    );
END;
/
```

**Ajouter un article :**
```sql
DECLARE
    v_refart NUMBER;
BEGIN
    PKG_ARTICLES.AJOUTER_ARTICLE(
        p_designation => 'MacBook Pro 16"',
        p_prixA => 2000,
        p_prixV => 2800,
        p_codetva => 19,
        p_categorie => 'Ordinateur Portable',
        p_qtestk => 20,
        p_refart => v_refart
    );
END;
/
```

**Rechercher des articles :**
```sql
BEGIN
    PKG_ARTICLES.CHERCHER_PAR_CATEGORIE('Smartphone');
END;
/
```

---

## 8. Tests {#tests}

### Script de test complet

Le fichier `8_test_scripts.sql` contient 30 tests couvrant :

- ✅ Ajout, modification, suppression de commandes
- ✅ Gestion des transitions d'état
- ✅ Ajout, modification, annulation de livraisons
- ✅ Vérification des contraintes (limite livreur, horaires)
- ✅ Gestion complète des articles
- ✅ Validation des triggers
- ✅ Tests de cas d'erreur

### Exécution des tests

```sql
SET SERVEROUTPUT ON;
@8_test_scripts.sql
```

### Résultats attendus

Tous les tests devraient s'exécuter sans erreur, avec les messages appropriés affichés via DBMS_OUTPUT.

---

## 📊 Statistiques du projet

- **Tables créées :** 8
- **Séquences :** 5
- **Index :** 12
- **Packages :** 4 (avec 28 procédures/fonctions)
- **Triggers :** 12
- **Vues :** 8
- **Lignes de code PL/SQL :** ~2000+

---

## 📝 Notes importantes

1. **Performance :** Les index ont été créés sur toutes les colonnes fréquemment utilisées dans les recherches et jointures.

2. **Intégrité :** Toutes les règles d'intégrité sont implémentées via des triggers et des contraintes CHECK.

3. **Transactions :** Toutes les opérations utilisent COMMIT/ROLLBACK pour garantir la cohérence.

4. **Gestion des erreurs :** Utilisation de RAISE_APPLICATION_ERROR avec des codes d'erreur personnalisés.

5. **Messages :** Centralisation dans PKG_MESSAGES pour faciliter la maintenance.

---

## 🎯 Conformité au cahier des charges

✅ Implémentation de la base de données avec minimum 10 tuples par table
✅ Utilisation des séquences pour l'insertion
✅ Création d'index pour améliorer les performances
✅ Toutes les règles d'intégrité implémentées
✅ Cas d'utilisation obligatoires (Commandes, Livraisons)
✅ Cas d'utilisation choisi (Articles)
✅ Packages PL/SQL pour chaque cas d'utilisation
✅ Package des messages
✅ Triggers pour les alertes LMD/LDD
✅ Maquettes des interfaces
✅ Documentation complète

---

**Projet réalisé dans le cadre du cours SGBD 2025-2026**
**Option choisie : b - Gestion des articles**
