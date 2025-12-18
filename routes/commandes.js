const express = require('express');
const router = express.Router();
const oracledb = require('oracledb');
const database = require('../config/database');

// GET - Récupérer toutes les commandes
router.get('/', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT c.nocde, c.noclt, cl.nomclt, cl.prenomclt, c.datecde, c.etatcde
             FROM Commandes c
             JOIN Clients cl ON c.noclt = cl.noclt
             ORDER BY c.nocde DESC`
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /commandes:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Récupérer une commande par numéro
router.get('/:nocde', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT c.nocde, c.noclt, cl.nomclt, cl.prenomclt, c.datecde, c.etatcde
             FROM Commandes c
             JOIN Clients cl ON c.noclt = cl.noclt
             WHERE c.nocde = :nocde`,
            [req.params.nocde]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Commande non trouvée' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Erreur GET /commandes/:nocde:', err);
        res.status(500).json({ error: err.message });
    }
});

// POST - Ajouter une commande
router.post('/', async (req, res) => {
    const { noclt } = req.body;

    try {
        const result = await database.callProcedure(
            'PKG_COMMANDES.AJOUTER_COMMANDE(:noclt, :nocde)',
            {
                noclt: noclt,
                nocde: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
            }
        );

        res.status(201).json({
            message: 'Commande ajoutée avec succès',
            nocde: result.outBinds.nocde
        });
    } catch (err) {
        console.error('Erreur POST /commandes:', err);
        res.status(400).json({ error: err.message });
    }
});

// PUT - Modifier l'état d'une commande
router.put('/:nocde/etat', async (req, res) => {
    const { nouvelEtat } = req.body;

    try {
        await database.callProcedure(
            'PKG_COMMANDES.MODIFIER_ETAT_COMMANDE(:nocde, :nouvel_etat)',
            {
                nocde: req.params.nocde,
                nouvel_etat: nouvelEtat
            }
        );

        res.json({ message: 'État de la commande modifié avec succès' });
    } catch (err) {
        console.error('Erreur PUT /commandes/:nocde/etat:', err);
        res.status(400).json({ error: err.message });
    }
});

// DELETE - Annuler une commande
router.delete('/:nocde', async (req, res) => {
    try {
        await database.callProcedure(
            'PKG_COMMANDES.ANNULER_COMMANDE(:nocde)',
            { nocde: req.params.nocde }
        );

        res.json({ message: 'Commande annulée avec succès' });
    } catch (err) {
        console.error('Erreur DELETE /commandes/:nocde:', err);
        res.status(400).json({ error: err.message });
    }
});

// GET - Rechercher les commandes d'un client
router.get('/client/:noclt', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT c.nocde, c.datecde, c.etatcde
             FROM Commandes c
             WHERE c.noclt = :noclt
             ORDER BY c.datecde DESC`,
            [req.params.noclt]
        );

        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /commandes/client/:noclt:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Rechercher les commandes par date
router.get('/date/:date', async (req, res) => {
    try {
        const dateStr = req.params.date;

        // strict ISO format check
        if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
        return res.status(400).json({ error: "Invalid date format. Use YYYY-MM-DD" });
        }

        // build date safely (no timezone issues)
        const pDate = new Date(dateStr + "T00:00:00");

        const result = await database.execute(
        `SELECT c.nocde, c.noclt, cl.nomclt, cl.prenomclt, c.etatcde
        FROM Commandes c
        JOIN Clients cl ON c.noclt = cl.noclt
        WHERE c.datecde >= :p_date
            AND c.datecde < :p_date + 1
        ORDER BY c.nocde`,
        { p_date: pDate }
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /commandes/date/:date:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Récupérer les commandes prêtes pour livraison
router.get('/etat/prete', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT c.nocde, c.noclt, cl.nomclt, cl.prenomclt, c.datecde
             FROM Commandes c
             JOIN Clients cl ON c.noclt = cl.noclt
             WHERE c.etatcde = 'PR'
             ORDER BY c.nocde DESC`
        );

        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /commandes/etat/prete:', err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
