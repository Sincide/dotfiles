/**
 * GPTDiag WebSocket Utilities
 * Additional WebSocket functionality and helpers
 */

// WebSocket connection utilities
class WebSocketUtils {
    static getProtocol() {
        return window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    }
    
    static getUrl(endpoint) {
        const protocol = this.getProtocol();
        return `${protocol}//${window.location.host}${endpoint}`;
    }
    
    static formatMessage(type, data = {}) {
        return JSON.stringify({ type, ...data });
    }
    
    static parseMessage(messageEvent) {
        try {
            return JSON.parse(messageEvent.data);
        } catch (error) {
            console.error('Failed to parse WebSocket message:', error);
            return null;
        }
    }
}

// Export utilities
window.WebSocketUtils = WebSocketUtils; 