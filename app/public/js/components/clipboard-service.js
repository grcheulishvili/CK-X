/**
 * Clipboard Service
 * Handles clipboard-related functionality
 */

/**
 * Copy text to remote desktop clipboard via facilitator API
 * @param {string} content - Text content to copy
 * @private
 */
async function copyToRemoteClipboard(content) {
    try {
        // Fire and forget API call
        fetch('/facilitator/api/v1/remote-desktop/clipboard', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ content })
        });
    } catch (error) {
        console.error('Failed to copy to remote clipboard:', error);
        // Don't throw error as this is a non-critical operation
    }
}

/**
 * Setup click-to-copy functionality for inline code elements
 * Uses event delegation to handle all inline-code elements
 */
function setupInlineCodeCopy() {
    document.addEventListener('click', function(event) {
        if (event.target && event.target.matches('.inline-code')) {
            const codeText = event.target.textContent;

            // Copy to remote desktop clipboard
            copyToRemoteClipboard(codeText);
            
            // Copy to local clipboard
            navigator.clipboard.writeText(codeText).catch(err => {
                console.error('Could not copy text to clipboard:', err);
            });

        }
    });
}

/**
 * Send arbitrary text to the lab desktop's clipboard.
 * Used by the host-to-guest paste panel so snippets copied from the docs in your
 * own browser can be pasted inside the VM, without needing a browser in the VM.
 * @param {string} content
 * @returns {Promise<boolean>} true when the facilitator accepted the content
 */
async function sendToRemoteClipboard(content) {
    const res = await fetch('/facilitator/api/v1/remote-desktop/clipboard', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content })
    });
    if (!res.ok) throw new Error('facilitator returned ' + res.status);
    return true;
}

/**
 * Wire up the paste panel: textarea + send button.
 * Ctrl/Cmd+Enter inside the textarea also sends.
 */
function setupHostToGuestPaste() {
    const box = document.getElementById('clipboardText');
    const btn = document.getElementById('clipboardSendBtn');
    const status = document.getElementById('clipboardStatus');
    if (!box || !btn) return;

    const t = (key, fallback) => (window.i18n && window.i18n.t) ? window.i18n.t(key) : fallback;

    async function send() {
        const text = box.value;
        if (!text) return;
        btn.disabled = true;
        try {
            await sendToRemoteClipboard(text);
            if (status) status.textContent = t('clip.sent', 'Sent. Paste inside the VM with Ctrl+Shift+V.');
        } catch (err) {
            console.error('clipboard send failed:', err);
            if (status) status.textContent = t('clip.failed', 'Could not reach the lab desktop.');
        } finally {
            btn.disabled = false;
        }
    }

    btn.addEventListener('click', send);
    box.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') { e.preventDefault(); send(); }
    });
}

export {
    setupInlineCodeCopy,
    sendToRemoteClipboard,
    setupHostToGuestPaste
}; 