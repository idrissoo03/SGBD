const database = require('./config/database');

async function testConnection() {
    console.log('========================================');
    console.log('Test de connexion à la base de données');
    console.log('========================================\n');

    try {
        console.log('Initialisation du pool de connexions...');
        await database.initialize();

        console.log('\n✓ Connexion établie avec succès!\n');

        console.log('Exécution d\'une requête de test...');
        const result = await database.execute('SELECT COUNT(*) as count FROM Articles');
        console.log(`✓ Nombre d'articles dans la base: ${result.rows[0].COUNT}\n`);

        console.log('Test réussi! La base de données est correctement configurée.\n');

    } catch (err) {
        console.error('\n✗ Erreur de connexion:');
        console.error(err.message);
        console.error('\nVérifiez vos paramètres de connexion dans le fichier .env\n');
        process.exit(1);
    } finally {
        try {
            await database.close();
        } catch (err) {
            console.error('Erreur lors de la fermeture:', err);
        }
    }
}

testConnection();
