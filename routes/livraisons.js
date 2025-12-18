const express = require('express');
const router = express.Router();
const oracledb = require('oracledb');
const database = require('../config/database');

// GET - Récupérer toutes les livraisons
router.get('/', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT lc.nocde, c.noclt, cl.nomclt, cl.prenomclt, cl.code_postal,
                    lc.dateliv, lc.livreur, p.nompers, p.prenompers, lc.modepay, lc.etaliv
             FROM LivraisonCom lc
             JOIN Commandes c ON lc.nocde = c.nocde
             JOIN Clients cl ON c.noclt = cl.noclt
             JOIN Personnel p ON lc.livreur = p.idpers
             ORDER BY lc.dateliv DESC`
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /livraisons:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Récupérer une livraison par numéro de commande
router.get('/:nocde', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT lc.nocde, lc.dateliv, lc.livreur, p.nompers, p.prenompers,
                    lc.modepay, lc.etaliv, cl.code_postal
             FROM LivraisonCom lc
             JOIN Personnel p ON lc.livreur = p.idpers
             JOIN Commandes c ON lc.nocde = c.nocde
             JOIN Clients cl ON c.noclt = cl.noclt
             WHERE lc.nocde = :nocde`,
            [req.params.nocde]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Livraison non trouvée' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Erreur GET /livraisons/:nocde:', err);
        res.status(500).json({ error: err.message });
    }
});

// POST - Ajouter une livraison
router.post('/', async (req, res) => {
    const { nocde, dateliv, livreur, modepay } = req.body;

    try {
        // Convertir la date en format Oracle
        const dateLivraison = new Date(dateliv);

        await database.callProcedure(
            'PKG_LIVRAISONS.AJOUTER_LIVRAISON(:nocde, :dateliv, :livreur, :modepay)',
            {
                nocde: nocde,
                dateliv: dateLivraison,
                livreur: livreur,
                modepay: modepay
            }
        );

        res.status(201).json({ message: 'Livraison ajoutée avec succès' });
    } catch (err) {
        console.error('Erreur POST /livraisons:', err);
        res.status(400).json({ error: err.message });
    }
});

// PUT - Modifier une livraison
router.put('/:nocde', async (req, res) => {
    const { nouvelleDate, nouveauLivreur } = req.body;

    try {
        let dateParam = null;
        if (nouvelleDate) {
            dateParam = new Date(nouvelleDate);
        }

        await database.callProcedure(
            'PKG_LIVRAISONS.MODIFIER_LIVRAISON(:nocde, :nouvelle_date, :nouveau_livreur)',
            {
                nocde: req.params.nocde,
                nouvelle_date: dateParam,
                nouveau_livreur: nouveauLivreur || null
            }
        );

        res.json({ message: 'Livraison modifiée avec succès' });
    } catch (err) {
        console.error('Erreur PUT /livraisons/:nocde:', err);
        res.status(400).json({ error: err.message });
    }
});

// DELETE - Annuler une livraison
router.delete('/:nocde', async (req, res) => {
    try {
        await database.callProcedure(
            'PKG_LIVRAISONS.SUPPRIMER_LIVRAISON(:nocde)',
            { nocde: req.params.nocde }
        );

        res.json({ message: 'Livraison annulée avec succès' });
    } catch (err) {
        console.error('Erreur DELETE /livraisons/:nocde:', err);
        res.status(400).json({ error: err.message });
    }
});

// GET - Rechercher les livraisons d'un livreur
router.get('/livreur/:livreur', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT lc.nocde, lc.dateliv, lc.etaliv, cl.code_postal
             FROM LivraisonCom lc
             JOIN Commandes c ON lc.nocde = c.nocde
             JOIN Clients cl ON c.noclt = cl.noclt
             WHERE lc.livreur = :livreur
             ORDER BY lc.dateliv DESC`,
            [req.params.livreur]
        );

        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /livraisons/livreur/:livreur:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Rechercher les livraisons par ville
router.get('/ville/:ville', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT lc.nocde, lc.dateliv, lc.livreur, p.nompers, lc.etaliv
             FROM LivraisonCom lc
             JOIN Personnel p ON lc.livreur = p.idpers
             JOIN Commandes c ON lc.nocde = c.nocde
             JOIN Clients cl ON c.noclt = cl.noclt
             WHERE cl.code_postal = :ville
             ORDER BY lc.dateliv DESC`,
            [req.params.ville]
        );

        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /livraisons/ville/:ville:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Rechercher les livraisons par date
router.get('/date/:date', async (req, res) => {
    try {
        const dateStr = req.params.date;

        // Validate format YYYY-MM-DD
        if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
            return res.status(400).json({ error: "Invalid date format. Use YYYY-MM-DD" });
        }

        // Convert to JS Date safely
        const pDate = new Date(dateStr + "T00:00:00");

        // Execute query using bind object and date range (avoids TRUNC)
        const result = await database.execute(
            `SELECT cl.nomclt,cl.prenomclt,lc.nocde, lc.livreur, p.nompers, cl.code_postal, lc.etaliv,lc.modepay,lc.dateliv
             FROM LivraisonCom lc
             JOIN Personnel p ON lc.livreur = p.idpers
             JOIN Commandes c ON lc.nocde = c.nocde
             JOIN Clients cl ON c.noclt = cl.noclt
             WHERE lc.dateliv >= :p_date
               AND lc.dateliv < :p_date + 1
             ORDER BY lc.nocde`,
            { p_date: pDate },


        );
        console.log(result.rows);
        res.json(result.rows);
 

    } catch (err) {
        console.error('Erreur GET /livraisons/date/:date:', err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
