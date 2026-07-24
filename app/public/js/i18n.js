/**
 * Interface language (EN / KA) and colour theme.
 *
 * Both choices persist in localStorage and are applied before first paint by the
 * inline bootstrap in index.html, so there is no flash of the wrong theme.
 * Georgian strings are a first pass and are meant to be edited in place here.
 */
(function (global) {
    'use strict';

    var DICT = {
        en: {
            'nav.results': 'Past results',
            'page.title': 'Kubernetes exam labs',
            'page.subtitle': 'Hands-on practice on a live cluster. Pick a lab to begin. The environment builds itself, grades every task, and shows you what you missed.',
            'stats.summary': '{labs} labs, {tasks} graded tasks',
            'stats.loading': 'Loading catalog',
            'stats.unavailable': 'Catalog unavailable',

            'filter.all': 'All',
            'category.CKA': 'CKA',
            'category.CKAD': 'CKAD',
            'category.CKS': 'CKS',
            'category.Other': 'Other',

            'group.CKA': 'Cluster administration, networking, storage, troubleshooting.',
            'group.CKAD': 'Application design, configuration, observability, deployment.',
            'group.CKS': 'Cluster hardening, supply chain, runtime security.',
            'group.Other': 'Supporting tooling used across the Kubernetes certifications.',

            'lab.tasks': 'tasks',
            'lab.minutes': 'min',
            'lab.one': 'lab',
            'lab.many': 'labs',

            'level.easy': 'Easy',
            'level.medium': 'Medium',
            'level.hard': 'Hard',

            'catalog.loading': 'Loading labs',
            'catalog.empty': 'No labs found. Check that the facilitator service is running, then reload.',
            'catalog.error': 'Could not reach the facilitator service. Make sure the stack is running (docker compose up -d), then reload this page.',

            'modal.title': 'Start lab',
            'modal.certification': 'Certification',
            'modal.lab': 'Lab',
            'modal.selectCert': 'Select certification',
            'modal.selectLab': 'Select a lab',
            'modal.describe': 'Select a lab to see its description.',
            'modal.certCKA': 'CKA - Certified Kubernetes Administrator',
            'modal.certCKAD': 'CKAD - Certified Kubernetes Application Developer',
            'modal.certCKS': 'CKS - Certified Kubernetes Security Specialist',
            'modal.certOther': 'Other - Docker and Helm',

            'btn.cancel': 'Cancel',
            'btn.start': 'Start lab',

            'loader.preparing': 'Preparing labs',
            'overlay.title': 'Building your lab environment',
            'overlay.init': 'Initializing',
            'overlay.note': 'Setup usually takes 3 to 5 minutes. You will be taken to the exam automatically when the cluster is ready.',

            'q.instance': 'Solve this question on instance:',
            'q.namespace': 'Namespace:',
            'q.concepts': 'Concepts:',

            'clip.title': 'Send text to the lab clipboard',
            'clip.hint': 'Paste a snippet copied from the Kubernetes docs, then use Ctrl+Shift+V in the lab terminal.',
            'clip.send': 'Send to VM',
            'clip.sent': 'Sent. Paste inside the VM with Ctrl+Shift+V.',
            'clip.failed': 'Could not reach the lab desktop.',

            'exam.activeTitle': 'Active Exam Detected',
            'exam.activeBody': 'You already have an active exam session:',
            'exam.activeOnlyOne': 'Only one active exam session can be present at a time.',
            'exam.unknown': 'Unknown Exam',
            'exam.continue': 'CONTINUE CURRENT SESSION',
            'exam.terminate': 'TERMINATE AND PROCEED',
            'exam.terminating': 'TERMINATING...',
            'exam.terminateRetry': 'Terminate and Proceed',
            'exam.terminateFailed': 'Failed to terminate the active exam. Please try again later.',
            'exam.start': 'START EXAM',
            'exam.loadingLabs': 'Loading labs...',
            'exam.noLabsCategory': 'No labs available for this category.',
            'exam.noLabSelected': 'No lab selected.',

            'pref.theme': 'Theme',
            'pref.language': 'Language',
            'pref.light': 'Light',
            'pref.dark': 'Dark'
        },

        ka: {
            'nav.results': 'წინა შედეგები',
            'page.title': 'Kubernetes-ის საგამოცდო ლაბორატორიები',
            'page.subtitle': 'პრაქტიკა ცოცხალ კლასტერზე. აირჩიეთ ლაბორატორია დასაწყებად. გარემო თავად აეწყობა, შეაფასებს თითოეულ დავალებას და გაჩვენებთ, რა გამოგრჩათ.',
            'stats.summary': '{labs} ლაბორატორია, {tasks} შესაფასებელი დავალება',
            'stats.loading': 'კატალოგი იტვირთება',
            'stats.unavailable': 'კატალოგი მიუწვდომელია',

            'filter.all': 'ყველა',
            'category.CKA': 'CKA',
            'category.CKAD': 'CKAD',
            'category.CKS': 'CKS',
            'category.Other': 'სხვა',

            'group.CKA': 'კლასტერის ადმინისტრირება, ქსელი, საცავი, ხარვეზების აღმოფხვრა.',
            'group.CKAD': 'აპლიკაციის დიზაინი, კონფიგურაცია, დაკვირვებადობა, განთავსება.',
            'group.CKS': 'უსაფრთხოების გაძლიერება, მიწოდების ჯაჭვი, გაშვების დროის დაცვა.',
            'group.Other': 'დამხმარე ხელსაწყოები Kubernetes-ის სერტიფიკაციებისთვის.',

            'lab.tasks': 'დავალება',
            'lab.minutes': 'წუთი',
            'lab.one': 'ლაბორატორია',
            'lab.many': 'ლაბორატორია',

            'level.easy': 'მარტივი',
            'level.medium': 'საშუალო',
            'level.hard': 'რთული',

            'catalog.loading': 'ლაბორატორიები იტვირთება',
            'catalog.empty': 'ლაბორატორიები ვერ მოიძებნა. შეამოწმეთ, მუშაობს თუ არა facilitator სერვისი, და გადატვირთეთ გვერდი.',
            'catalog.error': 'facilitator სერვისთან დაკავშირება ვერ მოხერხდა. დარწმუნდით, რომ გარემო გაშვებულია (docker compose up -d), და გადატვირთეთ გვერდი.',

            'modal.title': 'ლაბორატორიის დაწყება',
            'modal.certification': 'სერტიფიკაცია',
            'modal.lab': 'ლაბორატორია',
            'modal.selectCert': 'აირჩიეთ სერტიფიკაცია',
            'modal.selectLab': 'აირჩიეთ ლაბორატორია',
            'modal.describe': 'აღწერის სანახავად აირჩიეთ ლაბორატორია.',
            'modal.certCKA': 'CKA - Kubernetes-ის სერტიფიცირებული ადმინისტრატორი',
            'modal.certCKAD': 'CKAD - Kubernetes-ის სერტიფიცირებული აპლიკაციის დეველოპერი',
            'modal.certCKS': 'CKS - Kubernetes-ის უსაფრთხოების სერტიფიცირებული სპეციალისტი',
            'modal.certOther': 'სხვა - Docker და Helm',

            'btn.cancel': 'გაუქმება',
            'btn.start': 'დაწყება',

            'loader.preparing': 'ლაბორატორიები მზადდება',
            'overlay.title': 'მიმდინარეობს ლაბორატორიის გარემოს აგება',
            'overlay.init': 'ინიციალიზაცია',
            'overlay.note': 'მომზადებას ჩვეულებრივ სჭირდება 3-დან 5 წუთამდე. მზადყოფნისთანავე ავტომატურად გადახვალთ გამოცდაზე.',

            'q.instance': 'ეს დავალება შეასრულეთ ინსტანსზე:',
            'q.namespace': 'სახელების სივრცე (namespace):',
            'q.concepts': 'თემები:',

            'clip.title': 'ტექსტის გაგზავნა ლაბორატორიის ბუფერში',
            'clip.hint': 'ჩასვით Kubernetes-ის დოკუმენტაციიდან დაკოპირებული ფრაგმენტი, შემდეგ ლაბორატორიის ტერმინალში გამოიყენეთ Ctrl+Shift+V.',
            'clip.send': 'გაგზავნა',
            'clip.sent': 'გაიგზავნა. ჩასასმელად გამოიყენეთ Ctrl+Shift+V.',
            'clip.failed': 'ლაბორატორიის დესკტოპთან დაკავშირება ვერ მოხერხდა.',

            'exam.activeTitle': 'აღმოჩენილია აქტიური გამოცდა',
            'exam.activeBody': 'თქვენ უკვე გაქვთ აქტიური საგამოცდო სესია:',
            'exam.activeOnlyOne': 'ერთდროულად მხოლოდ ერთი აქტიური სესია შეიძლება არსებობდეს.',
            'exam.unknown': 'უცნობი გამოცდა',
            'exam.continue': 'მიმდინარე სესიის გაგრძელება',
            'exam.terminate': 'დასრულება და გაგრძელება',
            'exam.terminating': 'მიმდინარეობს დასრულება...',
            'exam.terminateRetry': 'დასრულება და გაგრძელება',
            'exam.terminateFailed': 'აქტიური გამოცდის დასრულება ვერ მოხერხდა. სცადეთ მოგვიანებით.',
            'exam.start': 'გამოცდის დაწყება',
            'exam.loadingLabs': 'ლაბორატორიები იტვირთება...',
            'exam.noLabsCategory': 'ამ კატეგორიაში ლაბორატორიები არ მოიძებნა.',
            'exam.noLabSelected': 'ლაბორატორია არ არის არჩეული.',

            'pref.theme': 'თემა',
            'pref.language': 'ენა',
            'pref.light': 'ნათელი',
            'pref.dark': 'მუქი'
        }
    };

    var LANG_KEY = 'ckx.lang';
    var THEME_KEY = 'ckx.theme';

    function currentLang() {
        try {
            var v = localStorage.getItem(LANG_KEY);
            if (v && DICT[v]) return v;
        } catch (e) { /* storage blocked */ }
        return 'en';
    }

    function currentTheme() {
        try {
            var v = localStorage.getItem(THEME_KEY);
            if (v === 'light' || v === 'dark') return v;
        } catch (e) { /* storage blocked */ }
        return (global.matchMedia && global.matchMedia('(prefers-color-scheme: light)').matches)
            ? 'light' : 'dark';
    }

    function t(key, vars) {
        var lang = currentLang();
        var s = (DICT[lang] && DICT[lang][key]) || (DICT.en[key] != null ? DICT.en[key] : key);
        if (vars) {
            Object.keys(vars).forEach(function (k) {
                s = s.split('{' + k + '}').join(vars[k]);
            });
        }
        return s;
    }

    function setLang(lang) {
        if (!DICT[lang]) return;
        try { localStorage.setItem(LANG_KEY, lang); } catch (e) { /* ignore */ }
        document.documentElement.setAttribute('lang', lang);
        apply();
        document.dispatchEvent(new CustomEvent('ckx:langchange', { detail: { lang: lang } }));
    }

    function setTheme(theme) {
        if (theme !== 'light' && theme !== 'dark') return;
        try { localStorage.setItem(THEME_KEY, theme); } catch (e) { /* ignore */ }
        document.documentElement.setAttribute('data-theme', theme);
        syncToggles();
    }

    function syncToggles() {
        var lang = currentLang(), theme = currentTheme();
        document.querySelectorAll('[data-set-lang]').forEach(function (el) {
            var on = el.getAttribute('data-set-lang') === lang;
            el.classList.toggle('is-active', on);
            el.setAttribute('aria-pressed', String(on));
        });
        document.querySelectorAll('[data-set-theme]').forEach(function (el) {
            var on = el.getAttribute('data-set-theme') === theme;
            el.classList.toggle('is-active', on);
            el.setAttribute('aria-pressed', String(on));
        });
    }

    /** Replace the text of every [data-i18n] node, and titles/placeholders. */
    function apply(root) {
        (root || document).querySelectorAll('[data-i18n]').forEach(function (el) {
            el.textContent = t(el.getAttribute('data-i18n'));
        });
        (root || document).querySelectorAll('[data-i18n-title]').forEach(function (el) {
            el.setAttribute('title', t(el.getAttribute('data-i18n-title')));
        });
        syncToggles();
    }

    global.i18n = {
        t: t,
        apply: apply,
        lang: currentLang,
        theme: currentTheme,
        setLang: setLang,
        setTheme: setTheme,
        languages: ['en', 'ka']
    };

    document.addEventListener('DOMContentLoaded', function () {
        document.documentElement.setAttribute('lang', currentLang());
        document.documentElement.setAttribute('data-theme', currentTheme());
        apply();

        document.addEventListener('click', function (e) {
            var langBtn = e.target.closest('[data-set-lang]');
            if (langBtn) { setLang(langBtn.getAttribute('data-set-lang')); return; }
            var themeBtn = e.target.closest('[data-set-theme]');
            if (themeBtn) { setTheme(themeBtn.getAttribute('data-set-theme')); }
        });
    });
})(window);
