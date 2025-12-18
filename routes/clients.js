const express = require('express');
const router = express.Router();
const database = require('../config/database');

// GET - Récupérer tous les clients
router.get('/', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail
             FROM Clients
             ORDER BY nomclt, prenomclt`
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /clients:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Récupérer un client par numéro
router.get('/:noclt', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT noclt, nomclt, prenomclt, adrclt, code_postal, telclt, adrmail
             FROM Clients
             WHERE noclt = :noclt`,
            [req.params.noclt]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Client non trouvé' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Erreur GET /clients/:noclt:', err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
