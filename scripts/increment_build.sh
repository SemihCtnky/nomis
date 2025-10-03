#!/bin/bash

# Otomatik Build Number Artırma Script'i
# Her Archive işleminde build number'ı otomatik artırır

# Sadece Archive konfigürasyonunda çalışsın
if [ "$CONFIGURATION" = "Release" ]; then
    echo "🔢 Build number artırılıyor..."
    
    # agvtool ile build number'ı artır
    xcrun agvtool next-version -all
    
    # Yeni build number'ı göster
    NEW_BUILD=$(xcrun agvtool what-version -terse)
    echo "✅ Yeni build number: $NEW_BUILD"
else
    echo "ℹ️ Debug mode - Build number artırılmadı"
fi

