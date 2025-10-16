#!/bin/bash

echo "🔧 CORRECTION NGINX MIME TYPES - PRODUCTION"
echo "==========================================="
echo ""

# 1. Backup de la config actuelle
echo "💾 Backup configuration actuelle..."
sudo cp /etc/nginx/sites-available/signfast.pro /etc/nginx/sites-available/signfast.pro.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup créé"
echo ""

# 2. Créer la nouvelle configuration avec MIME types corrects
echo "📝 Création nouvelle configuration..."
sudo tee /etc/nginx/sites-available/signfast.pro > /dev/null << 'EOF'
# Configuration Nginx CORRIGÉE - SignFast Production

server {
    listen 80;
    server_name signfast.pro www.signfast.pro;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name signfast.pro www.signfast.pro;

    # Certificats SSL
    ssl_certificate /etc/letsencrypt/live/signfast.pro/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/signfast.pro/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /var/www/SignFastv2/dist;
    index index.html;

    # 🔥 CRITIQUE : MIME types explicites
    types {
        text/html                             html htm shtml;
        text/css                              css;
        text/javascript                       js mjs;
        application/javascript                js mjs;
        application/json                      json;
        image/gif                             gif;
        image/jpeg                            jpeg jpg;
        image/png                             png;
        image/svg+xml                         svg svgz;
        image/webp                            webp;
        font/woff                             woff;
        font/woff2                            woff2;
        application/pdf                       pdf;
    }

    # 🔥 CRITIQUE : Modules JavaScript (.mjs) - PRIORITÉ ABSOLUE
    location ~* \.mjs$ {
        add_header Content-Type "text/javascript" always;
        add_header Cache-Control "public, max-age=31536000, immutable" always;
        add_header Access-Control-Allow-Origin "*" always;
        try_files $uri =404;
    }

    # CSP avec Supabase
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com data:; img-src 'self' data: https: blob:; connect-src 'self' https://signfast.hevolife.fr https://*.supabase.co wss://signfast.hevolife.fr; worker-src 'self' blob:; frame-src 'self'; object-src 'none'; base-uri 'self';" always;

    # Headers de sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Fichiers PWA manquants
    location = /manifest.json {
        return 204;
        add_header Content-Type application/json;
        access_log off;
    }

    location = /sw.js {
        return 204;
        add_header Content-Type application/javascript;
        add_header Service-Worker-Allowed "/";
        access_log off;
    }

    location = /favicon.ico {
        return 204;
        access_log off;
        log_not_found off;
    }

    # Assets statiques avec cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Logs
    access_log /var/log/nginx/signfast_access.log;
    error_log /var/log/nginx/signfast_error.log;
}
EOF

echo "✅ Configuration créée"
echo ""

# 3. Tester la configuration
echo "🧪 Test configuration Nginx..."
if sudo nginx -t; then
    echo "✅ Configuration valide"
    echo ""
    
    # 4. Recharger Nginx
    echo "🔄 Rechargement Nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx rechargé"
    echo ""
    
    # 5. Vérifier le statut
    echo "✅ Statut Nginx :"
    sudo systemctl status nginx --no-pager | head -5
    echo ""
    
    # 6. Tester le MIME type
    echo "🌐 Test MIME type .mjs :"
    WORKER_FILE=$(find /var/www/SignFastv2/dist/assets -name "*pdf.worker*.mjs" -type f | head -1)
    if [ -n "$WORKER_FILE" ]; then
        WORKER_NAME=$(basename "$WORKER_FILE")
        echo "Test : https://signfast.pro/assets/$WORKER_NAME"
        sleep 2
        curl -I "https://signfast.pro/assets/$WORKER_NAME" 2>&1 | grep -E "(HTTP|Content-Type)"
    fi
    echo ""
    
    echo "✅ CORRECTION TERMINÉE"
    echo ""
    echo "📝 ACTIONS SUIVANTES :"
    echo "1. Vider le cache navigateur (Ctrl+Shift+Delete)"
    echo "2. Faire un hard refresh (Ctrl+Shift+R)"
    echo "3. Tester le chargement PDF"
    echo "4. Si erreur persiste, envoyer les logs console"
    
else
    echo "❌ Configuration invalide !"
    echo "Restauration du backup..."
    sudo cp /etc/nginx/sites-available/signfast.pro.backup.* /etc/nginx/sites-available/signfast.pro
    sudo systemctl reload nginx
    echo "⚠️ Configuration restaurée"
fi
