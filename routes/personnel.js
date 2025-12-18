const express = require('express');
const router = express.Router();
const database = require('../config/database');

// GET - Récupérer tout le personnel
router.get('/', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT p.idpers, p.nompers, p.prenompers, p.adrpers, p.villepers, 
                    p.telpers, p.d_embauche, po.libelle as poste
             FROM Personnel p
             LEFT JOIN Poste po ON p.codeposte = po.codeposte
             ORDER BY p.nompers, p.prenompers`
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /personnel:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Récupérer uniquement les livreurs
router.get('/livreurs', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT p.idpers, p.nompers, p.prenompers
             FROM Personnel p
             JOIN Poste po ON p.codeposte = po.codeposte
             WHERE UPPER(po.libelle) LIKE '%LIVREUR%'
             ORDER BY p.nompers, p.prenompers`
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /personnel/livreurs:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Récupérer un membre du personnel par ID
router.get('/:idpers', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT p.idpers, p.nompers, p.prenompers, p.adrpers, p.villepers,
                    p.telpers, p.d_embauche, po.libelle as poste
             FROM Personnel p
             LEFT JOIN Poste po ON p.codeposte = po.codeposte
             WHERE p.idpers = :idpers`,
            [req.params.idpers]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Personnel non trouvé' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Erreur GET /personnel/:idpers:', err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
