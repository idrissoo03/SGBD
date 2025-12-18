# Backend Setup Guide - Système de Gestion des Livraisons

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir installé :

- **Node.js** (version 14 ou supérieure) - [Télécharger](https://nodejs.org/)
- **Oracle Database** (avec les packages PL/SQL déjà créés)
- **Oracle Instant Client** (pour la connexion Node.js)

## 🚀 Installation

### 1. Installer Node.js

Si Node.js n'est pas installé :

1. Téléchargez depuis https://nodejs.org/
2. Installez la version LTS recommandée
3. Vérifiez l'installation :
   ```powershell
   node --version
   npm --version
   ```

### 2. Installer Oracle Instant Client

Pour Windows :

1. Téléchargez Oracle Instant Client Basic depuis :
   https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html

2. Extrayez le fichier ZIP dans un dossier (exemple : `C:\oracle\instantclient_19_20`)

3. Ajoutez le dossier à la variable d'environnement PATH :
   - Panneau de configuration → Système → Paramètres système avancés
   - Variables d'environnement
   - Dans "Variables système", trouvez "Path" et cliquez sur "Modifier"
   - Ajoutez le chemin vers Instant Client (ex: `C:\oracle\instantclient_19_20`)

### 3. Installer les dépendances du projet

Ouvrez PowerShell dans le dossier du projet et exécutez :

```powershell
npm install
```

Cette commande installera toutes les dépendances nécessaires :
- express (serveur web)
- oracledb (connexion Oracle)
- cors (gestion des requêtes cross-origin)
- dotenv (gestion des variables d'environnement)

## ⚙️ Configuration

### Configurer la connexion à la base de données

1. Ouvrez le fichier `.env` dans un éditeur de texte

2. Modifiez les valeurs avec vos informations de connexion :

```env
# Server Configuration
PORT=3000

# Oracle Database Configuration
DB_USER=votre_utilisateur_oracle
DB_PASSWORD=votre_mot_de_passe
DB_CONNECT_STRING=localhost:1521/XEPDB1

# Connection Pool Configuration
DB_POOL_MIN=2
DB_POOL_MAX=10
DB_POOL_INCREMENT=2
```

#### Format du DB_CONNECT_STRING :

- **Format complet** : `hostname:port/service_name`
- **Exemples** :
  - Oracle XE local : `localhost:1521/XEPDB1`
  - Oracle local avec SID : `localhost:1521/ORCL`
  - Serveur distant : `192.168.1.100:1521/PROD`

### Trouver votre Service Name ou SID

Connectez-vous à SQL*Plus et exécutez :

```sql
-- Pour le service name
SELECT sys_context('USERENV', 'SERVICE_NAME') FROM dual;

-- Pour le SID
SELECT sys_context('USERENV', 'INSTANCE_NAME') FROM dual;
```

## 🧪 Tester la connexion

Avant de démarrer le serveur, testez la connexion à la base de données :

```powershell
npm run test-connection
```

Vous devriez voir :
```
========================================
Test de connexion à la base de données
========================================

Initialisation du pool de connexions...

✓ Connexion établie avec succès!

Exécution d'une requête de test...
✓ Nombre d'articles dans la base: X

Test réussi! La base de données est correctement configurée.
```

## 🎯 Démarrage du serveur

Une fois la connexion testée avec succès :

```powershell
npm start
```

Vous devriez voir :
```
========================================
🚀 Serveur démarré avec succès !
📍 URL: http://localhost:3000
🗄️  Base de données: Connectée
========================================
```

## 🌐 Utilisation

### Accéder à l'interface web

Ouvrez votre navigateur et allez sur :
```
http://localhost:3000
```

L'interface de gestion affichera trois onglets :
- 📦 Gestion Commandes
- 🚛 Gestion Livraisons
- 📱 Gestion Articles

### API Endpoints disponibles

#### Articles
- `GET /api/articles` - Tous les articles
- `GET /api/articles/:refart` - Article spécifique
- `POST /api/articles` - Ajouter un article
- `PUT /api/articles/:refart` - Modifier un article
- `DELETE /api/articles/:refart` - Supprimer un article

#### Commandes
- `GET /api/commandes` - Toutes les commandes
- `GET /api/commandes/:nocde` - Commande spécifique
- `POST /api/commandes` - Ajouter une commande
- `PUT /api/commandes/:nocde/etat` - Modifier l'état
- `DELETE /api/commandes/:nocde` - Annuler une commande

#### Livraisons
- `GET /api/livraisons` - Toutes les livraisons
- `GET /api/livraisons/:nocde` - Livraison spécifique
- `POST /api/livraisons` - Ajouter une livraison
- `PUT /api/livraisons/:nocde` - Modifier une livraison
- `DELETE /api/livraisons/:nocde` - Annuler une livraison

#### Clients & Personnel
- `GET /api/clients` - Tous les clients
- `GET /api/personnel/livreurs` - Tous les livreurs

## 🔧 Dépannage

### Erreur "Cannot find module 'oracledb'"

**Solution** : Réinstallez le module oracledb
```powershell
npm install oracledb
```

### Erreur "DPI-1047: Cannot locate a 64-bit Oracle Client library"

**Solution** : Oracle Instant Client n'est pas correctement configuré
1. Vérifiez que vous avez téléchargé la version 64-bit
2. Vérifiez que le chemin est dans la variable PATH
3. Redémarrez PowerShell après avoir modifié PATH

### Erreur "ORA-12541: TNS:no listener"

**Solution** : Le serveur Oracle n'est pas démarré ou l'adresse est incorrecte
1. Vérifiez que Oracle Database est en cours d'exécution
2. Vérifiez le DB_CONNECT_STRING dans .env
3. Testez avec SQL*Plus pour confirmer la connexion

### Erreur "ORA-01017: invalid username/password"

**Solution** : Identifiants incorrects
1. Vérifiez DB_USER et DB_PASSWORD dans .env
2. Testez la connexion avec SQL*Plus

### Le serveur démarre mais l'interface est vide

**Solution** : Les packages PL/SQL ne sont peut-être pas créés
1. Exécutez dans l'ordre :
   - `creation_table.sql`
   - `insertion_donne.sql`
   - `pkg_msg.sql`
   - `pkg_gest_articles.sql`
   - `pkg_gest_commandes.sql`
   - `pkg_gest_livraisaion.sql`
   - `all_triggers.sql`

### Port 3000 déjà utilisé

**Solution** : Changez le port dans .env
```env
PORT=8080
```

Puis accédez à `http://localhost:8080`

## 📚 Structure du projet

```
ProjetSGBD2/
│
├── config/
│   └── database.js          # Configuration de la connexion Oracle
│
├── routes/
│   ├── articles.js          # Routes API pour articles
│   ├── commandes.js         # Routes API pour commandes
│   ├── livraisons.js        # Routes API pour livraisons
│   ├── clients.js           # Routes API pour clients
│   └── personnel.js         # Routes API pour personnel
│
├── .env                     # Variables d'environnement (NE PAS COMMITER!)
├── .env.example             # Template des variables
├── .gitignore               # Fichiers à ignorer par Git
├── server.js                # Point d'entrée du serveur
├── interface.html           # Interface web
├── package.json             # Dépendances Node.js
└── test-connection.js       # Script de test de connexion
```

## 🎓 Développement

Pour le développement avec rechargement automatique :

```powershell
npm install -g nodemon
npm run dev
```

## 📝 Notes importantes

1. **Sécurité** : Ne commitez jamais le fichier `.env` sur Git
2. **Production** : Utilisez des variables d'environnement sécurisées en production
3. **Performance** : Le pool de connexions est configuré pour 2-10 connexions
4. **Triggers** : Les triggers Oracle gèrent automatiquement certaines validations

## ✅ Checklist de vérification

- [ ] Node.js installé et fonctionnel
- [ ] Oracle Instant Client installé et dans PATH
- [ ] Fichier .env configuré avec les bonnes informations
- [ ] `npm install` exécuté sans erreurs
- [ ] `npm run test-connection` réussit
- [ ] Packages PL/SQL créés dans Oracle
- [ ] Données de test insérées
- [ ] `npm start` démarre le serveur
- [ ] `http://localhost:3000` accessible
- [ ] Les trois onglets chargent des données

## 🆘 Support

En cas de problème :

1. Vérifiez les logs du serveur dans la console
2. Consultez la console du navigateur (F12) pour les erreurs JavaScript
3. Vérifiez les logs Oracle avec SQL*Plus
4. Assurez-vous que tous les packages PL/SQL sont compilés sans erreurs

---

**Projet réalisé dans le cadre du cours SGBD 2025-2026**
