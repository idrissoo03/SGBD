const express = require('express');
const router = express.Router();
const oracledb = require('oracledb');
const database = require('../config/database');

// GET - Récupérer tous les articles
router.get('/', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT refart, designation, prixA, prixV, codetva, categorie, qtestk, supp 
             FROM Articles 
             WHERE supp = 'N' 
             ORDER BY refart DESC`
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /articles:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Récupérer un article par référence
router.get('/:refart', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT refart, designation, prixA, prixV, codetva, categorie, qtestk, supp 
             FROM Articles 
             WHERE refart = :refart`,
            [req.params.refart]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Article non trouvé' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Erreur GET /articles/:refart:', err);
        res.status(500).json({ error: err.message });
    }
});

// POST - Ajouter un article
router.post('/', async (req, res) => {
    const { designation, prixA, prixV, codetva, categorie, qtestk } = req.body;

    try {
        const result = await database.callProcedure(
            'PKG_ARTICLES.AJOUTER_ARTICLE(:designation, :prixA, :prixV, :codetva, :categorie, :qtestk, :refart)',
            {
                designation: designation,
                prixA: prixA,
                prixV: prixV,
                codetva: codetva,
                categorie: categorie,
                qtestk: qtestk,
                refart: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
            }
        );

        res.status(201).json({
            message: 'Article ajouté avec succès',
            refart: result.outBinds.refart
        });
    } catch (err) {
        console.error('Erreur POST /articles:', err);
        res.status(400).json({ error: err.message });
    }
});

// PUT - Modifier un article
router.put('/:refart', async (req, res) => {
    const { designation, prixA, prixV, codetva, categorie } = req.body;
    const refart = req.params.refart;

    try {
        await database.callProcedure(
            'PKG_ARTICLES.MODIFIER_ARTICLE(:refart, :designation, :prixA, :prixV, :codetva, :categorie)',
            {
                refart: refart,
                designation: designation || null,
                prixA: prixA || null,
                prixV: prixV || null,
                codetva: codetva || null,
                categorie: categorie || null
            }
        );

        res.json({ message: 'Article modifié avec succès' });
    } catch (err) {
        console.error('Erreur PUT /articles/:refart:', err);
        res.status(400).json({ error: err.message });
    }
});

// DELETE - Supprimer un article
router.delete('/:refart', async (req, res) => {
    try {
        await database.callProcedure(
            'PKG_ARTICLES.SUPPRIMER_ARTICLE(:refart)',
            { refart: req.params.refart }
        );

        res.json({ message: 'Article supprimé avec succès' });
    } catch (err) {
        console.error('Erreur DELETE /articles/:refart:', err);
        res.status(400).json({ error: err.message });
    }
});

// GET - Rechercher par désignation
router.get('/search/designation/:designation', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT refart, designation, prixV, categorie, qtestk
             FROM Articles
             WHERE UPPER(designation) LIKE UPPER(:designation)
             AND supp = 'N'
             ORDER BY designation`,
            ['%' + req.params.designation + '%']
        );

        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /articles/search/designation:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Rechercher par catégorie
router.get('/search/categorie/:categorie', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT refart, designation, prixV, qtestk
             FROM Articles
             WHERE UPPER(categorie) = UPPER(:categorie)
             AND supp = 'N'
             ORDER BY designation`,
            [req.params.categorie]
        );

        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /articles/search/categorie:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET - Récupérer toutes les catégories
router.get('/meta/categories', async (req, res) => {
    try {
        const result = await database.execute(
            `SELECT DISTINCT categorie 
             FROM Articles 
             WHERE supp = 'N' 
             ORDER BY categorie`
        );

        res.json(result.rows);
    } catch (err) {
        console.error('Erreur GET /articles/meta/categories:', err);
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
