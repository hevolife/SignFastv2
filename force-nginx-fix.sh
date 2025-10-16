#!/bin/bash

echo "🔧 CORRECTION FORCÉE NGINX MIME TYPES"
echo "======================================"
echo ""

# 1. Backup
echo "💾 Backup de la configuration..."
sudo cp /etc/nginx/sites-available/signfast /etc/nginx/sites-available/signfast.backup.$(date +%Y%m%d_%H%M%S)

# 2. Créer la nouvelle configuration DIRECTEMENT
echo "📝 Création de la nouvelle configuration..."
sudo tee /etc/nginx/sites-available/signfast > /dev/null <<'EOF'
server {
    listen 80;
    server_name signfast.pro www.signfast.pro;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name signfast.pro www.signfast.pro;

    ssl_certificate /etc/letsencrypt/live/signfast.pro/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/signfast.pro/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /var/www/SignFastv2/dist;
    index index.html;

    # CSP
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com data:; img-src 'self' data: https: blob:; connect-src 'self' https://signfast.hevolife.fr https://*.supabase.co wss://signfast.hevolife.fr; worker-src 'self' blob:; frame-src 'self'; object-src 'none'; base-uri 'self';" always;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # 🔥 CRITIQUE : Fichiers .mjs AVANT les autres assets
    location ~* \.mjs$ {
        add_header Content-Type "text/javascript" always;
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header X-Content-Type-Options "nosniff" always;
        try_files $uri =404;
    }

    # Fichiers PWA manquants
    location = /manifest.json {
        return 204;
        add_header Content-Type application/json;
        access_log off;
    }

    location = /sw.js {
        return 204;
        add_header Content-Type application/javascript;
        access_log off;
    }

    location = /favicon.ico {
        return 204;
        access_log off;
        log_not_found off;
    }

    location = /icon-192.png {
        return 204;
        access_log off;
        log_not_found off;
    }

    location = /icon-512.png {
        return 204;
        access_log off;
        log_not_found off;
    }

    # Assets statiques
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    access_log /var/log/nginx/signfast_access.log;
    error_log /var/log/nginx/signfast_error.log;
}
EOF

# 3. Vérifier la syntaxe
echo ""
echo "🧪 Test de la configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valide"
    
    # 4. RESTART complet (pas reload)
    echo ""
    echo "🔄 RESTART complet de Nginx..."
    sudo systemctl restart nginx
    
    # 5. Vérifier le statut
    echo ""
    echo "⚙️ Vérification du statut..."
    sudo systemctl status nginx --no-pager | head -10
    
    # 6. Attendre 2 secondes
    sleep 2
    
    # 7. Tester le MIME type
    echo ""
    echo "🌐 Test du MIME type..."
    curl -I https://signfast.pro/assets/pdf.worker.min-yatZIOMy.mjs 2>&1 | grep -i "content-type"
    
    echo ""
    echo "✅ CORRECTION APPLIQUÉE"
    echo ""
    echo "🎯 ACTIONS SUIVANTES :"
    echo "1. Ouvrez https://signfast.pro/templates"
    echo "2. Videz le cache : Ctrl+Shift+R"
    echo "3. Vérifiez la console (F12)"
else
    echo "❌ Erreur dans la configuration"
    echo "Restauration du backup..."
    sudo cp /etc/nginx/sites-available/signfast.backup.* /etc/nginx/sites-available/signfast
    sudo systemctl reload nginx
    exit 1
fi
