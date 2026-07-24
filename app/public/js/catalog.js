/**
 * Lab catalog for the landing page.
 *
 * Renders every available lab as a selectable row, grouped by certification.
 * Selecting a lab reuses the existing start flow in index.js (which performs the
 * active-exam check and the POST) by pre-filling the confirm dialog - so this file
 * adds presentation only, and changes no exam logic.
 */
(function () {
    'use strict';

    const CATEGORY_ORDER = ['CKA', 'CKAD', 'CKS', 'Other'];
    const t = function (key, vars) {
        return (window.i18n && window.i18n.t) ? window.i18n.t(key, vars) : key;
    };

    let labs = [];
    let activeCategory = 'All';
    let pendingLab = null;

    const catalogEl = document.getElementById('catalog');
    const filtersEl = document.getElementById('categoryFilters');
    const statLineEl = document.getElementById('statLine');
    const startExamBtn = document.getElementById('startExamBtn');
    const modalEl = document.getElementById('examSelectionModal');

    function esc(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function categoryKey(category) {
        return CATEGORY_ORDER.includes(category) ? category : 'Other';
    }

    function sortLabs(list) {
        return list.slice().sort(function (a, b) {
            const nameA = (localised(a, 'name') || a.id || '').toLowerCase();
            const nameB = (localised(b, 'name') || b.id || '').toLowerCase();
            return nameA.localeCompare(nameB);
        });
    }

    function renderStats() {
        const tasks = labs.reduce(function (sum, lab) {
            return sum + (Number(lab.questionCount) || 0);
        }, 0);
        const certs = CATEGORY_ORDER.filter(function (c) {
            return labs.some(function (lab) { return categoryKey(lab.category) === c; });
        });
        statLineEl.textContent =
            t('stats.summary', { labs: labs.length, tasks: tasks }) +
            (certs.length ? '  (' + certs.join(', ') + ')' : '');
            ' graded tasks - ' + certs.join(' ') + '</span>';
    }

    function renderFilters() {
        const present = CATEGORY_ORDER.filter(function (c) {
            return labs.some(function (lab) { return categoryKey(lab.category) === c; });
        });
        const all = ['All'].concat(present);
        filtersEl.innerHTML = all.map(function (cat) {
            const count = cat === 'All'
                ? labs.length
                : labs.filter(function (l) { return categoryKey(l.category) === cat; }).length;
            const on = cat === activeCategory ? ' is-active' : '';
            const label = cat === 'All' ? t('filter.all') : t('category.' + cat);
            return '<button type="button" role="tab" class="chip' + on + '" ' +
                'data-category="' + esc(cat) + '" aria-selected="' + (cat === activeCategory) + '">' +
                esc(label) + '<span class="chip-count">' + count + '</span></button>';
        }).join('');
    }

    function localised(lab, field) {
        const lang = (window.i18n && window.i18n.lang) ? window.i18n.lang() : 'en';
        if (lang !== 'en' && lab[field + '_' + lang]) return lab[field + '_' + lang];
        return lab[field] || '';
    }

    function labRow(lab) {
        const cat = categoryKey(lab.category);
        const tasks = Number(lab.questionCount) || 0;
        const mins = Number(lab.examDurationInMinutes) || 0;
        const level = lab.difficulty || 'Medium';
        return '' +
            '<button type="button" class="lab" data-lab-id="' + esc(lab.id) + '" ' +
                'data-lab-category="' + esc(cat) + '">' +
                '<span class="lab-body">' +
                    '<span class="lab-head">' +
                        '<span class="lab-name">' + esc(localised(lab, 'name') || lab.id) + '</span>' +
                        '<span class="tag">' + esc(t('category.' + cat)) + '</span>' +
                    '</span>' +
                    '<span class="lab-desc">' + esc(localised(lab, 'description')) + '</span>' +
                '</span>' +
                '<span class="lab-meta">' +
                    '<span><b>' + tasks + '</b> ' + esc(t('lab.tasks')) + '</span>' +
                    '<span><b>' + mins + '</b> ' + esc(t('lab.minutes')) + '</span>' +
                    '<span>' + esc(t('level.' + String(level).toLowerCase())) + '</span>' +
                '</span>' +
            '</button>';
    }

    function renderCatalog() {
        if (!labs.length) {
            catalogEl.innerHTML = '<div class="catalog-empty">' + esc(t('catalog.empty')) + '</div>';
            return;
        }
        const groups = CATEGORY_ORDER.filter(function (cat) {
            if (activeCategory !== 'All' && cat !== activeCategory) return false;
            return labs.some(function (lab) { return categoryKey(lab.category) === cat; });
        });

        catalogEl.innerHTML = groups.map(function (cat) {
            const rows = sortLabs(labs.filter(function (l) { return categoryKey(l.category) === cat; }));
            return '<section class="group">' +
                '<header class="group-head">' +
                    '<h2 class="group-title">' + esc(t('category.' + cat)) + '</h2>' +
                    '<p class="group-blurb">' + esc(t('group.' + cat)) + '</p>' +
                    '<span class="group-count">' + rows.length + ' ' +
                        esc(rows.length === 1 ? t('lab.one') : t('lab.many')) + '</span>' +
                '</header>' +
                '<div class="group-rows">' + rows.map(labRow).join('') + '</div>' +
            '</section>';
        }).join('');
    }

    function selectLab(id, category) {
        pendingLab = { id: id, category: category };
        // Hand off to index.js: it checks for an active exam, then opens the dialog.
        startExamBtn.click();
    }

    // When the dialog opens, pre-fill it with the lab chosen from the catalog.
    if (modalEl) {
        modalEl.addEventListener('shown.bs.modal', function () {
            if (!pendingLab) return;
            const catSelect = document.getElementById('examCategory');
            const nameSelect = document.getElementById('examName');
            if (!catSelect || !nameSelect) { pendingLab = null; return; }

            catSelect.value = pendingLab.category;
            catSelect.dispatchEvent(new Event('change'));

            const wanted = pendingLab.id;
            pendingLab = null;
            // Populating the lab list is synchronous, but defer once so any
            // change handler in index.js has finished before we set the value.
            setTimeout(function () {
                nameSelect.value = wanted;
                nameSelect.dispatchEvent(new Event('change'));
            }, 0);
        });
    }

    filtersEl.addEventListener('click', function (event) {
        const chip = event.target.closest('.chip');
        if (!chip) return;
        activeCategory = chip.dataset.category;
        renderFilters();
        renderCatalog();
    });

    catalogEl.addEventListener('click', function (event) {
        const row = event.target.closest('.lab');
        if (!row) return;
        selectLab(row.dataset.labId, row.dataset.labCategory);
    });

    document.addEventListener('ckx:langchange', function () {
        if (!labs.length) return;
        renderStats();
        renderFilters();
        renderCatalog();
    });

    fetch('/facilitator/api/v1/assements/')
        .then(function (res) {
            if (!res.ok) throw new Error('status ' + res.status);
            return res.json();
        })
        .then(function (data) {
            labs = Array.isArray(data) ? data : (data && data.labs) || [];
            renderStats();
            renderFilters();
            renderCatalog();
        })
        .catch(function (err) {
            console.error('Could not load labs:', err);
            statLineEl.textContent = t('stats.unavailable');
            catalogEl.innerHTML = '<div class="catalog-empty">' + esc(t('catalog.error')) + '</div>';
        });
})();
