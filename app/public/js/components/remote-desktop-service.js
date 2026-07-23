/**
 * Remote Desktop Service
 * Handles remote desktop connection and management
 */
import { getVncInfo } from './exam-api.js';


/**
 * Keep the remote desktop the same size as its panel.
 *
 * With resize=remote, noVNC negotiates the desktop size once when it connects and
 * then only re-negotiates on a window resize event *inside its own document*.
 * The iframe is laid out by flexbox, so its final height often arrives after that
 * first negotiation - leaving a canvas smaller than the panel, centred with black
 * margins. Re-dispatching a resize event into the iframe makes noVNC re-measure
 * and ask the server for the correct size.
 *
 * Same-origin (the page is served from /vnc-proxy/), so reaching into
 * contentWindow is allowed; it is still wrapped in try/catch for safety.
 */
function keepVncSizedToPanel(vncFrame) {
    if (!vncFrame || vncFrame.__ckxResizeBound) return;
    vncFrame.__ckxResizeBound = true;

    const nudge = () => {
        try {
            const win = vncFrame.contentWindow;
            if (win) win.dispatchEvent(new Event('resize'));
        } catch (err) {
            /* frame not ready yet - a later nudge will catch it */
        }
    };

    // After load the layout may still settle, so nudge a few times.
    vncFrame.addEventListener('load', () => {
        [300, 1000, 2500].forEach(delay => setTimeout(nudge, delay));
    });

    let timer = null;
    const debouncedNudge = () => {
        clearTimeout(timer);
        timer = setTimeout(nudge, 250);
    };

    // Browser window resize, and panel resize from dragging the splitter or
    // collapsing the question pane.
    window.addEventListener('resize', debouncedNudge);
    if (typeof ResizeObserver !== 'undefined') {
        try {
            new ResizeObserver(debouncedNudge)
                .observe(vncFrame.parentElement || vncFrame);
        } catch (err) {
            /* ResizeObserver unavailable - window resize still covers most cases */
        }
    }
}

// Connect to VNC
function connectToRemoteDesktop(vncFrame, statusCallback) {
    if (statusCallback) {
        statusCallback('Connecting to Remote Desktop...', 'info');
    }
    
    // Get VNC server info from API
    return getVncInfo()
        .then(data => {
            console.log('Remote Desktop info:', data);
            
            // Request vnc.html explicitly, NOT the proxy root.
            //
            // The root serves noVNC's index.html, which in the ConSol desktop image is
            // vnc_lite.html - a minimal page that only reads host/port/password/path and
            // silently ignores resize, quality, compression and reconnect. That is why
            // the desktop stayed at its native 1280x800, centred with black margins,
            // whatever sizing parameter was passed. vnc.html is the full UI and honours
            // them: resize=remote makes the server match its framebuffer to this panel,
            // so text renders 1:1 instead of being scaled.
            const vncUrl = `/vnc-proxy/vnc.html?autoconnect=true&resize=remote`
                + `&quality=6&compression=2&show_dot=true`
                + `&reconnect=true&reconnect_delay=2000`
                + `&password=${data.defaultPassword}`;
            
            // Set the iframe source to the VNC URL
            vncFrame.src = vncUrl;
            keepVncSizedToPanel(vncFrame);
            if (statusCallback) {
                statusCallback('Connected to Session', 'success');
            }
            return vncUrl;
        })
        .catch(error => {
            console.error('Error connecting to Remote Desktop:', error);
            if (statusCallback) {
                statusCallback('Failed to connect to Remote Desktop. Retrying...', 'error');
            }
            // Return a promise that will retry
            return new Promise(resolve => {
                setTimeout(() => {
                    resolve(connectToRemoteDesktop(vncFrame, statusCallback));
                }, 5000);
            });
        });
}

// Setup Remote Desktop frame event handlers
function setupRemoteDesktopFrameHandlers(vncFrame, statusCallback) {
    vncFrame.addEventListener('load', function() {
        if (vncFrame.src !== 'about:blank') {
            console.log('Remote Desktop frame loaded successfully');
            if (statusCallback) {
                statusCallback('Connected to Session', 'success');
            }
        }
    });
    
    vncFrame.addEventListener('error', function(e) {
        console.error('Error loading Remote Desktop frame:', e);
        if (statusCallback) {
            statusCallback('Error connecting to Remote Desktop. Retrying...', 'error');
        }
        // Try to reconnect after a delay
        setTimeout(() => connectToRemoteDesktop(vncFrame, statusCallback), 5000);
    });
}

export {
    connectToRemoteDesktop,
    setupRemoteDesktopFrameHandlers
}; 