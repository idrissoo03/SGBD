const express = require('express');
const cors = require('cors');
const path = require('path');
const oracledb = require('oracledb');
require('dotenv').config();

oracledb.initOracleClient({
    libDir: "C:/Users/USER/Desktop/oracle/instantclient_11_2"
});
const database = require('./config/database');

// Import routes
const articlesRoutes = require('./routes/articles');
const commandesRoutes = require('./routes/commandes');
const livraisonsRoutes = require('./routes/livraisons');
const clientsRoutes = require('./routes/clients');
const personnelRoutes = require('./routes/personnel');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir les fichiers statiques
app.use(express.static(__dirname));

// Routes API
app.use('/api/articles', articlesRoutes);
app.use('/api/commandes', commandesRoutes);
app.use('/api/livraisons', livraisonsRoutes);
app.use('/api/clients', clientsRoutes);
app.use('/api/personnel', personnelRoutes);

// Route pour servir l'interface
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'interface.html'));
});

// Route de test
app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', message: 'Server is running' });
});

// Gestion des erreurs
app.use((err, req, res, next) => {
    console.error('Erreur:', err);
    res.status(500).json({
        error: 'Une erreur est survenue',
        message: err.message
    });
});

// Initialiser la base de données et démarrer le serveur
async function startup() {
    try {
        console.log('Initialisation de la base de données...');
        await database.initialize();

        app.listen(PORT, () => {
            console.log(`\n========================================`);
            console.log(`🚀 Serveur démarré avec succès !`);
            console.log(`📍 URL: http://localhost:${PORT}`);
            console.log(`🗄️  Base de données: Connectée`);
            console.log(`========================================\n`);
        });
    } catch (err) {
        console.error('Erreur lors du démarrage:', err);
        process.exit(1);
    }
}

// Gestion de l'arrêt propre
process.on('SIGINT', async () => {
    console.log('\nArrêt du serveur...');
    try {
        await database.close();
        process.exit(0);
    } catch (err) {
        console.error('Erreur lors de l\'arrêt:', err);
        process.exit(1);
    }
});

startup();
