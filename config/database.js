const oracledb = require('oracledb');
require('dotenv').config();

// Configuration du pool de connexions
const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectString: process.env.DB_CONNECT_STRING,
    poolMin: parseInt(process.env.DB_POOL_MIN) || 2,
    poolMax: parseInt(process.env.DB_POOL_MAX) || 10,
    poolIncrement: parseInt(process.env.DB_POOL_INCREMENT) || 2
};

// Initialiser le pool de connexions
async function initialize() {
    try {
        await oracledb.createPool(dbConfig);
        console.log('✓ Pool de connexions Oracle créé avec succès');
    } catch (err) {
        console.error('✗ Erreur lors de la création du pool de connexions:', err);
        throw err;
    }
}

// Fermer le pool de connexions
async function close() {
    try {
        await oracledb.getPool().close(10);
        console.log('✓ Pool de connexions Oracle fermé');
    } catch (err) {
        console.error('✗ Erreur lors de la fermeture du pool:', err);
        throw err;
    }
}

// Exécuter une requête
async function execute(sql, binds = [], options = {}) {
    let connection;

    // Options par défaut
    options.outFormat = oracledb.OUT_FORMAT_OBJECT;
    options.autoCommit = options.autoCommit !== undefined ? options.autoCommit : true;

    try {
        connection = await oracledb.getConnection();
        const result = await connection.execute(sql, binds, options);
        return result;
    } catch (err) {
        console.error('Erreur lors de l\'exécution de la requête:', err);
        throw err;
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error('Erreur lors de la fermeture de la connexion:', err);
            }
        }
    }
}

// Appeler une procédure stockée
async function callProcedure(procedureName, binds = {}) {
    let connection;

    try {
        connection = await oracledb.getConnection();
        const result = await connection.execute(
            `BEGIN ${procedureName}; END;`,
            binds,
            { autoCommit: true }
        );
        return result;
    } catch (err) {
        console.error(`Erreur lors de l'appel de ${procedureName}:`, err);
        throw err;
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error('Erreur lors de la fermeture de la connexion:', err);
            }
        }
    }
}

module.exports = {
    initialize,
    close,
    execute,
    callProcedure
};
