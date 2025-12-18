// Configuration de l'API
const API_URL = 'http://localhost:3000/api';

// Variables globales
let currentEditArticle = null;
let currentEditCommande = null;
let currentEditLivraison = null;
let commandesCache = [];
let livraisonsCache = [];
let articlesCache = [];

// ======================
// FONCTIONS UTILITAIRES
// ======================

function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 15px 25px;
    background: ${type === 'success' ? '#28a745' : '#dc3545'};
    color: white;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.3);
    z-index: 10000;
    animation: slideIn 0.3s ease;
    `;
    notification.textContent = message;
    document.body.appendChild(notification);

    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

async function apiRequest(endpoint, options = {}) {
    try {
        const response = await fetch(`${API_URL}${endpoint}`, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || 'Une erreur est survenue');
        }

        return data;
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

function formatDate(dateString) {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR');
}

function formatDateTime(dateString) {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleString('fr-FR');
}

// ======================
// GESTION DES ONGLETS
// ======================

function showMockup(evt, id) {
    const mockups = document.querySelectorAll('.mockup');
    mockups.forEach(m => m.classList.remove('active'));

    const buttons = document.querySelectorAll('.tab-button');
    buttons.forEach(b => b.classList.remove('active'));

    document.getElementById(id).classList.add('active');
    if (evt && evt.target) {
        evt.target.classList.add('active');
    }

    // Charger les données de l'onglet
    if (id === 'commandes') loadCommandes();
    else if (id === 'livraisons') loadLivraisons();
    else if (id === 'articles') loadArticles();
}

// ======================
// GESTION DES COMMANDES
// ======================

async function loadCommandes() {
    try {
        const commandes = await apiRequest('/commandes');
        commandesCache = commandes || [];
        displayCommandes(commandesCache);
    } catch (error) {
        showNotification('Erreur lors du chargement des commandes: ' + error.message, 'error');
    }
}

function displayCommandes(commandes = []) {
    const tbody = document.querySelector('#commandes table tbody');
    tbody.innerHTML = '';

    if (!commandes.length) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty-row">Aucune commande trouvée</td></tr>';
        return;
    }

    commandes.forEach(cmd => {
        const badgeClass = {
            'EC': 'badge-info',
            'PR': 'badge-warning',
            'LI': 'badge-info',
            'SO': 'badge-success',
            'AN': 'badge-danger'
        }[cmd.ETATCDE] || 'badge-info';

        const etatLabel = {
            'EC': 'EC - En Cours',
            'PR': 'PR - Prête',
            'LI': 'LI - En Livraison',
            'SO': 'SO - Sortie',
            'AN': 'AN - Annulée'
        }[cmd.ETATCDE] || cmd.ETATCDE;

        const row = `
    <tr>
        <td>#${cmd.NOCDE}</td>
        <td>${cmd.NOMCLT} ${cmd.PRENOMCLT || ''}</td>
        <td>${formatDate(cmd.DATECDE)}</td>
        <td><span class="badge ${badgeClass}">${etatLabel}</span></td>
        <td>-</td>
        <td>
            ${cmd.ETATCDE !== 'AN' && cmd.ETATCDE !== 'SO' ?
                `<button class="btn-primary" style="padding: 6px 12px; font-size: 14px;" onclick="modifierEtatCommande(${cmd.NOCDE}, '${cmd.ETATCDE}')">✏️ Modifier</button>
                                <button class="btn-danger" style="padding: 6px 12px; font-size: 14px;" onclick="annulerCommande(${cmd.NOCDE})">❌ Annuler</button>`
                : `<button class="btn-secondary" style="padding: 6px 12px; font-size: 14px;" onclick="showCommandeDetails(${cmd.NOCDE})">👁️ Détails</button>`
            }
        </td>
    </tr>
    `;
        tbody.innerHTML += row;
    });
}

function filterCommandes(term) {
    const value = (term || '').toLowerCase();
    const filtered = commandesCache.filter(cmd => {
        const nom = `${cmd.NOMCLT || ''} ${cmd.PRENOMCLT || ''}`.toLowerCase();
        const date = formatDate(cmd.DATECDE).toLowerCase();
        return `${cmd.NOCDE}`.includes(value) || nom.includes(value) || date.includes(value);
    });
    displayCommandes(filtered);
}

async function ajouterCommande() {
    const nocltSelect = document.getElementById('commande-client');
    const noclt = nocltSelect ? nocltSelect.value : '';

    if (!noclt) {
        showNotification('Veuillez sélectionner un client', 'error');
        return;
    }

    try {
        const result = await apiRequest('/commandes', {
            method: 'POST',
            body: JSON.stringify({ noclt: parseInt(noclt) })
        });

        showNotification(result.message || 'Commande ajoutée avec succès');
        loadCommandes();
        if (nocltSelect) nocltSelect.value = '';
    } catch (error) {
        showNotification('Erreur: ' + error.message, 'error');
    }
}

async function modifierEtatCommande(nocde, etatActuel) {
    const transitions = {
        'EC': ['PR', 'AN'],
        'PR': ['LI', 'AN'],
        'LI': ['SO']
    };

    const etatsDisponibles = transitions[etatActuel] || [];
    if (etatsDisponibles.length === 0) {
        showNotification('Aucune transition disponible', 'error');
        return;
    }

    const nouvelEtat = prompt(`Nouvel état pour la commande #${nocde}\nÉtats disponibles: ${etatsDisponibles.join(', ')}`);

    if (nouvelEtat && etatsDisponibles.includes(nouvelEtat.toUpperCase())) {
        try {
            await apiRequest(`/commandes/${nocde}/etat`, {
                method: 'PUT',
                body: JSON.stringify({ nouvelEtat: nouvelEtat.toUpperCase() })
            });

            showNotification('État de la commande modifié avec succès');
            loadCommandes();
        } catch (error) {
            showNotification('Erreur: ' + error.message, 'error');
        }
    }
}

async function annulerCommande(nocde) {
    if (!confirm(`Êtes-vous sûr de vouloir annuler la commande #${nocde} ?`)) return;

    try {
        await apiRequest(`/commandes/${nocde}`, { method: 'DELETE' });
        showNotification('Commande annulée avec succès');
        loadCommandes();
    } catch (error) {
        showNotification('Erreur: ' + error.message, 'error');
    }
}

async function showCommandeDetails(nocde) {
    try {
        const commande = await apiRequest(`/commandes/${nocde}`);
        const modal = document.getElementById('commande-details-modal');
        const title = document.getElementById('commande-details-title');
        const content = document.getElementById('commande-details-content');
        const modifyBtn = document.getElementById('commande-details-modify');

        title.textContent = `Détails de la Commande #${nocde}`;

        const etatLabel = {
            'EC': 'EC - En Cours',
            'PR': 'PR - Prête',
            'LI': 'LI - En Livraison',
            'SO': 'SO - Sortie',
            'AN': 'AN - Annulée'
        }[commande.ETATCDE] || commande.ETATCDE;

        content.innerHTML = `
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                <div>
                    <p style="margin: 0; font-weight: 600; color: #667eea;">Numéro Commande</p>
                    <p style="margin: 8px 0 15px; font-size: 16px;">#${commande.NOCDE}</p>
                </div>
                <div>
                    <p style="margin: 0; font-weight: 600; color: #667eea;">État</p>
                    <p style="margin: 8px 0 15px; font-size: 16px;">${etatLabel}</p>
                </div>
                <div>
                    <p style="margin: 0; font-weight: 600; color: #667eea;">Client</p>
                    <p style="margin: 8px 0 15px; font-size: 16px;">${commande.NOMCLT} ${commande.PRENOMCLT || ''}</p>
                </div>
                <div>
                    <p style="margin: 0; font-weight: 600; color: #667eea;">Date Commande</p>
                    <p style="margin: 8px 0 15px; font-size: 16px;">${formatDate(commande.DATECDE)}</p>
                </div>
            </div>
        `;

        // Only show modify button if commande is not cancelled or delivered
        if (commande.ETATCDE !== 'AN' && commande.ETATCDE !== 'SO') {
            modifyBtn.style.display = 'block';
            modifyBtn.onclick = () => {
                closeCommandeDetailsModal();
                modifierEtatCommande(commande.NOCDE, commande.ETATCDE);
            };
        } else {
            modifyBtn.style.display = 'none';
        }

        modal.style.display = 'flex';
    } catch (error) {
        showNotification('Erreur lors du chargement des détails: ' + error.message, 'error');
    }
}

function closeCommandeDetailsModal() {
    const modal = document.getElementById('commande-details-modal');
    if (modal) {
        modal.style.display = 'none';
    }
}

// Close modal when clicking outside
document.addEventListener('DOMContentLoaded', () => {
    const modal = document.getElementById('commande-details-modal');
    if (modal) {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                closeCommandeDetailsModal();
            }
        });
    }
});


// ======================
// GESTION DES LIVRAISONS
// ======================

async function loadLivraisons() {
    try {
        const livraisons = await apiRequest('/livraisons');
        livraisonsCache = livraisons || [];
        displayLivraisons(livraisonsCache);
        await loadCommandesPrete();
        await loadLivreurs();
    } catch (error) {
        showNotification('Erreur lors du chargement des livraisons: ' + error.message, 'error');
    }
}

function displayLivraisons(livraisons = []) {
    const tbody = document.querySelector('#livraisons table tbody');
    tbody.innerHTML = '';

    if (!livraisons.length) {
        tbody.innerHTML = '<tr><td colspan="8" class="empty-row">Aucune livraison trouvée</td></tr>';
        return;
    }

    livraisons.forEach(liv => {
        const badgeClass = {
            'EP': 'badge-warning',
            'EL': 'badge-info',
            'LV': 'badge-success'
        }[liv.ETALIV] || 'badge-info';

        const etatLabel = {
            'EP': 'EP - En Préparation',
            'EL': 'EL - En Livraison',
            'LV': 'LV - Livrée'
        }[liv.ETALIV] || liv.ETALIV;

        const row = `
    <tr>
        <td>#${liv.NOCDE}</td>
        <td>${liv.NOMCLT} ${liv.PRENOMCLT || ''}</td>
        <td>${liv.CODE_POSTAL}</td>
        <td>${formatDateTime(liv.DATELIV)}</td>
        <td>${liv.NOMPERS} ${liv.PRENOMPERS || ''}</td>
        <td>${liv.MODEPAY}</td>
        <td><span class="badge ${badgeClass}">${etatLabel}</span></td>
        <td>
            ${liv.ETALIV !== 'LV' ?
                `<button class="btn-primary" style="padding: 6px 12px; font-size: 14px;" onclick="modifierLivraison(${liv.NOCDE})">✏️ Modifier</button>
                                <button class="btn-danger" style="padding: 6px 12px; font-size: 14px;" onclick="annulerLivraison(${liv.NOCDE})">❌ Annuler</button>`
                : `<button class="btn-secondary" style="padding: 6px 12px; font-size: 14px;" onclick="showLivraisonDetails(${liv.NOCDE})">👁️ Détails</button>`
            }
        </td>
    </tr>
    `;
        tbody.innerHTML += row;
    });
}

function filterLivraisons(term) {
    const value = (term || '').toLowerCase();
    const filtered = livraisonsCache.filter(liv => {
        const nom = `${liv.NOMCLT || ''} ${liv.PRENOMCLT || ''}`.toLowerCase();
        const livreur = `${liv.NOMPERS || ''} ${liv.PRENOMPERS || ''}`.toLowerCase();
        const ville = `${liv.CODE_POSTAL || ''}`.toLowerCase();
        return `${liv.NOCDE}`.includes(value) || nom.includes(value) || livreur.includes(value) || ville.includes(value);
    });
    displayLivraisons(filtered);
}

async function loadCommandesPrete() {
    try {
        const commandes = await apiRequest('/commandes/etat/prete');
        const select = document.getElementById('livraison-commande');
        if (select) {
            select.innerHTML = '<option value="">Sélectionner une commande prête...</option>';
            commandes.forEach(cmd => {
                select.innerHTML += `<option value="${cmd.NOCDE}">#${cmd.NOCDE} - ${cmd.NOMCLT} ${cmd.PRENOMCLT || ''} (PR)</option>`;
            });
        }
    } catch (error) {
        console.error('Erreur chargement commandes:', error);
    }
}

async function loadLivreurs() {
    try {
        const livreurs = await apiRequest('/personnel/livreurs');
        const select = document.getElementById('livraison-livreur');
        if (select) {
            select.innerHTML = '<option value="">Sélectionner un livreur...</option>';
            livreurs.forEach(liv => {
                select.innerHTML += `<option value="${liv.IDPERS}">${liv.NOMPERS} ${liv.PRENOMPERS || ''}</option>`;
            });
        }
    } catch (error) {
        console.error('Erreur chargement livreurs:', error);
    }
}

async function ajouterLivraison() {
    const nocde = document.getElementById('livraison-commande')?.value;
    const livreur = document.getElementById('livraison-livreur')?.value;
    const dateliv = document.getElementById('livraison-date')?.value;
    const modepay = document.getElementById('livraison-modepay')?.value;

    if (!nocde || nocde === 'Sélectionner une commande prête...') {
        showNotification('Veuillez sélectionner une commande', 'error');
        return;
    }
    if (!livreur || livreur === 'Sélectionner un livreur...') {
        showNotification('Veuillez sélectionner un livreur', 'error');
        return;
    }
    if (!dateliv || !modepay) {
        showNotification('Veuillez remplir tous les champs', 'error');
        return;
    }

    try {
        await apiRequest('/livraisons', {
            method: 'POST',
            body: JSON.stringify({
                nocde: parseInt(nocde, 10),
                dateliv: dateliv,
                livreur: parseInt(livreur, 10),
                modepay: modepay
            })
        });

        showNotification('Livraison ajoutée avec succès');
        loadLivraisons();
        resetLivraisonForm();
    } catch (error) {
        showNotification('Erreur: ' + error.message, 'error');
    }
}

async function modifierLivraison(nocde) {
    const nouvelleDate = prompt('Nouvelle date et heure (format: YYYY-MM-DDTHH:MM):');
    if (!nouvelleDate) return;

    try {
        await apiRequest(`/livraisons/${nocde}`, {
            method: 'PUT',
            body: JSON.stringify({ nouvelleDate: nouvelleDate })
        });

        showNotification('Livraison modifiée avec succès');
        loadLivraisons();
    } catch (error) {
        showNotification('Erreur: ' + error.message, 'error');
    }
}

async function annulerLivraison(nocde) {
    if (!confirm(`Êtes-vous sûr de vouloir annuler la livraison de la commande #${nocde} ?`)) return;

    try {
        await apiRequest(`/livraisons/${nocde}`, { method: 'DELETE' });
        showNotification('Livraison annulée avec succès');
        loadLivraisons();
        loadCommandes();
    } catch (error) {
        showNotification('Erreur: ' + error.message, 'error');
    }
}

async function showLivraisonDetails(nocde) {
    try {
        const livraison = await apiRequest(`/livraisons/${nocde}`);
        const modal = document.getElementById('livraison-details-modal');
        const title = document.getElementById('livraison-details-title');
        const content = document.getElementById('livraison-details-content');
        const modifyBtn = document.getElementById('livraison-details-modify');

        title.textContent = `Détails de la Livraison #${nocde}`;

        const etatLabel = {
            'EP': 'EP - En Préparation',
            'EL': 'EL - En Livraison',
            'LV': 'LV - Livrée'
        }[livraison.ETALIV] || livraison.ETALIV;

        content.innerHTML = `
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                <div>
                    <p style="margin: 0; font-weight: 600; color: #667eea;">N° Commande</p>
                    <p style="margin: 8px 0 15px; font-size: 16px;">#${livraison.NOCDE}</p>
                </div>
                <div>
                    <p style="margin: 0; font-weight: 600; color: #667eea;">État</p>
                    <p style="margin: 8px 0 15px; font-size: 16px;">${etatLabel}</p>
                </div>
                <div>
                    <p style="margin: 0; font-weight: 600; color: #667eea;">Client</p>
                    <p style="margin: 8px 0 15px; font-size: 16px;">${livraison.NOMCLT} ${livraison.PRENOMCLT || ''}</p>
                </div>
                <div>
                    <p style="margin: 0; font-weight: 600; color: #667eea;">Livreur</p>
                    <p style="margin: 8px 0 15px; font-size: 16px;">${livraison.NOMPERS} ${livraison.PRENOMPERS || ''}</p>
                </div>
                <div>
                    <p style="margin: 0; font-weight: 600; color: #667eea;">Ville</p>
                    <p style="margin: 8px 0 15px; font-size: 16px;">${livraison.CODE_POSTAL}</p>
                </div>
                <div>
                    <p style="margin: 0; font-weight: 600; color: #667eea;">Mode de Paiement</p>
                    <p style="margin: 8px 0 15px; font-size: 16px;">${livraison.MODEPAY}</p>
                </div>
                <div style="grid-column: 1 / -1;">
                    <p style="margin: 0; font-weight: 600; color: #667eea;">Date et Heure de Livraison</p>
                    <p style="margin: 8px 0 15px; font-size: 16px;">${formatDateTime(livraison.DATELIV)}</p>
                </div>
            </div>
        `;

        // Only show modify button if livraison is not completed
        if (livraison.ETALIV !== 'LV') {
            modifyBtn.style.display = 'block';
            modifyBtn.onclick = () => {
                closeCommandeDetailsModal();
                modifierLivraison(livraison.NOCDE);
            };
        } else {
            modifyBtn.style.display = 'none';
        }

        modal.style.display = 'flex';
    } catch (error) {
        showNotification('Erreur lors du chargement des détails: ' + error.message, 'error');
    }
}

function closeLivraisonDetailsModal() {
    const modal = document.getElementById('livraison-details-modal');
    if (modal) {
        modal.style.display = 'none';
    }
}

// Close modal when clicking outside
document.addEventListener('DOMContentLoaded', () => {
    const modal = document.getElementById('livraison-details-modal');
    if (modal) {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                closeLivraisonDetailsModal();
            }
        });
    }
});


function resetLivraisonForm() {
    const commande = document.getElementById('livraison-commande');
    const livreur = document.getElementById('livraison-livreur');
    const date = document.getElementById('livraison-date');
    const modepay = document.getElementById('livraison-modepay');
    if (commande) commande.value = '';
    if (livreur) livreur.value = '';
    if (date) date.value = '';
    if (modepay) modepay.value = 'Espèces';
}

// ======================
// GESTION DES ARTICLES
// ======================

async function loadArticles() {
    try {
        const articles = await apiRequest('/articles');
        articlesCache = articles || [];
        displayArticles(articlesCache);
        await loadCategories();
    } catch (error) {
        showNotification('Erreur lors du chargement des articles: ' + error.message, 'error');
    }
}

function displayArticles(articles = []) {
    const tbody = document.querySelector('#articles table tbody');
    tbody.innerHTML = '';

    if (!articles.length) {
        tbody.innerHTML = '<tr><td colspan="8" class="empty-row">Aucun article trouvé</td></tr>';
        return;
    }

    articles.forEach(art => {
        const stock = Number(art.QTESTK || 0);
        const stockBadge = stock > 20 ? 'badge-success' :
            stock > 0 ? 'badge-warning' : 'badge-danger';
        const prixA = Number(art.PRIXA || 0).toFixed(2);
        const prixV = Number(art.PRIXV || 0).toFixed(2);

        const row = `
    <tr>
        <td>#${art.REFART}</td>
        <td>${art.DESIGNATION}</td>
        <td>${art.CATEGORIE}</td>
        <td>${prixA} DT</td>
        <td>${prixV} DT</td>
        <td><span class="badge ${stockBadge}">${stock}</span></td>
        <td>${art.CODETVA}%</td>
        <td>
            <button class="btn-primary" style="padding: 6px 12px; font-size: 14px;" onclick="editArticle(${art.REFART})">✏️ Modifier</button>
            <button class="btn-danger" style="padding: 6px 12px; font-size: 14px;" onclick="supprimerArticle(${art.REFART})">🗑️ Supprimer</button>
        </td>
    </tr>
    `;
        tbody.innerHTML += row;
    });
}

function filterArticles() {
    const term = (document.getElementById('articles-search')?.value || '').toLowerCase();
    const category = document.getElementById('articles-filter-category')?.value || '';
    const stockFilter = document.getElementById('articles-filter-stock')?.value || '';

    const filtered = articlesCache.filter(art => {
        const designation = (art.DESIGNATION || '').toLowerCase();
        const cat = (art.CATEGORIE || '').toLowerCase();
        const code = `${art.REFART || ''}`.toLowerCase();
        const stock = Number(art.QTESTK || 0);

        const matchesSearch = designation.includes(term) || cat.includes(term) || code.includes(term);
        const matchesCategory = !category || cat === category.toLowerCase();
        const matchesStock = !stockFilter ||
            (stockFilter === 'high' && stock > 20) ||
            (stockFilter === 'medium' && stock > 0 && stock <= 20) ||
            (stockFilter === 'low' && stock === 0);

        return matchesSearch && matchesCategory && matchesStock;
    });

    displayArticles(filtered);
}

async function ajouterArticle() {
    const designation = document.getElementById('article-designation')?.value;
    const categorie = document.getElementById('article-categorie')?.value;
    const prixA = parseFloat(document.getElementById('article-prixa')?.value);
    const prixV = parseFloat(document.getElementById('article-prixv')?.value);
    const qtestk = parseInt(document.getElementById('article-qtestk')?.value);
    const codetva = parseFloat(document.getElementById('article-codetva')?.value);

    if (!designation || !categorie || isNaN(prixA) || isNaN(prixV) || isNaN(qtestk) || isNaN(codetva)) {
        showNotification('Veuillez remplir tous les champs avec des valeurs valides', 'error');
        return;
    }

    try {
        const result = await apiRequest('/articles', {
            method: 'POST',
            body: JSON.stringify({
                designation, categorie, prixA, prixV, qtestk, codetva
            })
        });

        showNotification(result.message || 'Article ajouté avec succès');
        loadArticles();
        resetArticleForm();
    } catch (error) {
        showNotification('Erreur: ' + error.message, 'error');
    }
}

async function editArticle(refart) {
    try {
        const article = await apiRequest(`/articles/${refart}`);
        
        // Populate form fields
        document.getElementById('article-designation').value = article.DESIGNATION || '';
        document.getElementById('article-categorie').value = article.CATEGORIE || '';
        document.getElementById('article-prixa').value = article.PRIXA || '';
        document.getElementById('article-prixv').value = article.PRIXV || '';
        document.getElementById('article-qtestk').value = article.QTESTK || '';
        document.getElementById('article-codetva').value = article.CODETVA || '';

        // Update UI state
        currentEditArticle = refart;
        const saveBtn = document.getElementById('article-save');
        const formTitle = document.getElementById('article-form-title');
        if (saveBtn) saveBtn.textContent = '💾 Mettre à jour';
        if (formTitle) formTitle.textContent = `✏️ Modifier l'Article #${refart}`;

        // Scroll to form
        document.getElementById('article-form-title')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
        
        showNotification('Article chargé pour modification', 'success');
    } catch (error) {
        showNotification('Erreur: ' + error.message, 'error');
    }
}

async function enregistrerArticle() {
    if (currentEditArticle) {
        await modifierArticle();
    } else {
        await ajouterArticle();
    }
}

async function modifierArticle() {
    const designation = document.getElementById('article-designation')?.value;
    const categorie = document.getElementById('article-categorie')?.value;
    const prixA = parseFloat(document.getElementById('article-prixa')?.value);
    const prixV = parseFloat(document.getElementById('article-prixv')?.value);
    const qtestk = parseInt(document.getElementById('article-qtestk')?.value);
    const codetva = parseFloat(document.getElementById('article-codetva')?.value);

    if (!designation || !categorie || isNaN(prixA) || isNaN(prixV) || isNaN(qtestk) || isNaN(codetva)) {
        showNotification('Veuillez remplir tous les champs avec des valeurs valides', 'error');
        return;
    }

    try {
        await apiRequest(`/articles/${currentEditArticle}`, {
            method: 'PUT',
            body: JSON.stringify({
                designation, categorie, prixA, prixV, qtestk, codetva
            })
        });

        showNotification('Article modifié avec succès');
        loadArticles();
        resetArticleForm();
    } catch (error) {
        showNotification('Erreur: ' + error.message, 'error');
    }
}

function resetArticleForm() {
    currentEditArticle = null;
    
    // Clear all form fields
    document.getElementById('article-designation').value = '';
    document.getElementById('article-categorie').selectedIndex = 0;
    document.getElementById('article-prixa').value = '';
    document.getElementById('article-prixv').value = '';
    document.getElementById('article-qtestk').value = '';
    document.getElementById('article-codetva').value = '19.00';

    // Reset UI
    const saveBtn = document.getElementById('article-save');
    const formTitle = document.getElementById('article-form-title');
    if (saveBtn) saveBtn.textContent = '💾 Enregistrer';
    if (formTitle) formTitle.textContent = '➕ Ajouter/Modifier un Article';
}

async function supprimerArticle(refart) {
    if (!confirm(`Êtes-vous sûr de vouloir supprimer l'article #${refart} ?`)) return;

    try {
        await apiRequest(`/articles/${refart}`, { method: 'DELETE' });
        showNotification('Article supprimé avec succès');
        loadArticles();
    } catch (error) {
        showNotification('Erreur: ' + error.message, 'error');
    }
}

async function loadCategories() {
    try {
        const categories = await apiRequest('/articles/meta/categories');
        const select = document.getElementById('articles-filter-category');
        if (select) {
            const current = select.value;
            select.innerHTML = '<option value="">Toutes catégories</option>';
            categories.forEach(cat => {
                select.innerHTML += `<option value="${cat.CATEGORIE}">${cat.CATEGORIE}</option>`;
            });
            select.value = current || '';
        }
    } catch (error) {
        console.error('Erreur chargement catégories:', error);
    }
}

// ======================
// CHARGEMENT INITIAL
// ======================

async function loadClients() {
    try {
        const clients = await apiRequest('/clients');
        const select = document.getElementById('commande-client');
        if (select) {
            select.innerHTML = '<option value="">Sélectionner un client...</option>';
            clients.forEach(clt => {
                select.innerHTML += `<option value="${clt.NOCLT}">${clt.NOMCLT} ${clt.PRENOMCLT || ''}</option>`;
            });
        }
    } catch (error) {
        console.error('Erreur chargement clients:', error);
    }
}

// Attacher les gestionnaires d'événements aux boutons
document.addEventListener('DOMContentLoaded', () => {
    // Commandes
    document.getElementById('commande-save')?.addEventListener('click', ajouterCommande);
    document.getElementById('commande-reset')?.addEventListener('click', () => {
        const select = document.getElementById('commande-client');
        if (select) select.value = '';
    });
    document.getElementById('commandes-search-btn')?.addEventListener('click', () => filterCommandes(document.getElementById('commandes-search')?.value));
    document.getElementById('commandes-search')?.addEventListener('input', (e) => filterCommandes(e.target.value));
    document.getElementById('commandes-date-btn')?.addEventListener('click', async () => {
        const dateInput = document.getElementById('commandes-date');
        const date = dateInput?.value;
        if (!date) {
            showNotification('Veuillez sélectionner une date', 'error');
            return;
        }
        try {
            const data = await apiRequest(`/commandes/date/${date}`);
            displayCommandes(data);
        } catch (err) {
            showNotification('Erreur lors de la recherche par date: ' + err.message, 'error');
        }
    });
    document.getElementById('commandes-add-btn')?.addEventListener('click', () => {
        document.getElementById('commande-client')?.scrollIntoView({ behavior: 'smooth' });
        document.getElementById('commande-client')?.focus();
    });

    // Livraisons
    document.getElementById('livraison-save')?.addEventListener('click', ajouterLivraison);
    document.getElementById('livraison-reset')?.addEventListener('click', resetLivraisonForm);
    document.getElementById('livraisons-search-btn')?.addEventListener('click', () => filterLivraisons(document.getElementById('livraisons-search')?.value));
    document.getElementById('livraisons-search')?.addEventListener('input', (e) => filterLivraisons(e.target.value));
    document.getElementById('livraisons-date-btn')?.addEventListener('click', async () => {
        const dateInput = document.getElementById('livraisons-date');
        const date = dateInput?.value;
        if (!date) {
            showNotification('Veuillez sélectionner une date de livraison', 'error');
            return;
        }
        try {
            const data = await apiRequest(`/livraisons/date/${date}`);
            displayLivraisons(data);
        } catch (err) {
            showNotification('Erreur lors de la recherche par date: ' + err.message, 'error');
        }
    });
    document.getElementById('livraisons-add-btn')?.addEventListener('click', () => {
        document.getElementById('livraison-commande')?.scrollIntoView({ behavior: 'smooth' });
    });

    // Articles
    document.getElementById('articles-search-btn')?.addEventListener('click', filterArticles);
    document.getElementById('articles-search')?.addEventListener('input', filterArticles);
    document.getElementById('articles-filter-category')?.addEventListener('change', filterArticles);
    document.getElementById('articles-filter-stock')?.addEventListener('change', filterArticles);
    document.getElementById('articles-add-btn')?.addEventListener('click', () => {
        resetArticleForm();
        document.getElementById('article-form-title')?.scrollIntoView({ behavior: 'smooth' });
    });

    document.getElementById('article-save')?.addEventListener('click', enregistrerArticle);
    document.getElementById('article-reset')?.addEventListener('click', resetArticleForm);
});

// Charger les données au démarrage
window.addEventListener('DOMContentLoaded', async () => {
    console.log('Chargement de l\'application...');
    await loadClients();
    // Charger la maquette par défaut (commandes)
    const defaultTabButton = document.querySelector('.tab-button.active');
    if (defaultTabButton) {
        const mockupId = defaultTabButton.getAttribute('onclick').match(/'([^']+)'/)[1];
        document.getElementById(mockupId).classList.add('active');
        if (mockupId === 'commandes') await loadCommandes();
        else if (mockupId === 'livraisons') await loadLivraisons();
        else if (mockupId === 'articles') await loadArticles();
    } else {
        // Fallback if no active button is set initially
        document.getElementById('commandes').classList.add('active');
        await loadCommandes();
    }
});

// Ajouter les styles pour l'animation
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {transform: translateX(400px); opacity: 0; }
    to {transform: translateX(0); opacity: 1; }
            }
    @keyframes slideOut {
        from {transform: translateX(0); opacity: 1; }
    to {transform: translateX(400px); opacity: 0; }
            }
    `;
document.head.appendChild(style);
