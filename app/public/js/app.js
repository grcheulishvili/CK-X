document.addEventListener('DOMContentLoaded', function() {
    const vncFrame = document.getElementById('vnc-frame');
    const connectBtn = document.getElementById('connect-btn');
    const fullscreenBtn = document.getElementById('fullscreen-btn');
    
    connectBtn.addEventListener('click', function() {
        // Connect to the VNC server through the service
        // Same reasoning as remote-desktop-service.js: the proxy root serves
        // noVNC's vnc_lite.html, which ignores sizing parameters. Use the full UI.
        vncFrame.src = `/vnc-proxy/vnc.html?autoconnect=true&resize=remote&reconnect=true`;
    });
    
    fullscreenBtn.addEventListener('click', function() {
        if (vncFrame.requestFullscreen) {
            vncFrame.requestFullscreen();
        } else if (vncFrame.webkitRequestFullscreen) {
            vncFrame.webkitRequestFullscreen();
        } else if (vncFrame.msRequestFullscreen) {
            vncFrame.msRequestFullscreen();
        }
    });
}); 