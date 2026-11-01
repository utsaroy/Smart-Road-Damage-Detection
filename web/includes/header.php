<?php
/**
 * Common Header for Road Authority Portal - SorokSurokkha
 * Professional Civic & Municipal Light Design
 */
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/auth.php';
$authUser = Auth::user();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars(APP_NAME) ?> - Road Authority Portal</title>
    <link rel="icon" type="image/png" href="assets/images/logo.png">
    
    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: {
                            50: '#f0f9ff',
                            100: '#e0f2fe',
                            500: '#0284c7',
                            600: '#0369a1',
                            700: '#075985',
                            900: '#0c4a6e',
                        }
                    }
                }
            }
        }
    </script>
    
    <!-- Google Fonts: Plus Jakarta Sans, Hind Siliguri (Bengali) & JetBrains Mono -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Hind+Siliguri:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    
    <!-- Leaflet GIS Map CSS -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
    
    <!-- Lucide Icons -->
    <script src="https://unpkg.com/lucide@latest"></script>

    <!-- Supabase Cloud Client SDK -->
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>

    <!-- Custom CSS -->
    <link rel="stylesheet" href="assets/css/style.css?v=<?= time() ?>">

    <!-- Bilingual i18n Translation Engine -->
    <script src="assets/js/i18n.js?v=<?= time() ?>"></script>
</head>
<body class="bg-slate-50 text-slate-800 min-h-screen flex flex-col font-sans antialiased">

    <!-- Top Administrative Header (Enlarged & Prominent) -->
    <header class="sticky top-0 z-[1050] bg-white/95 backdrop-blur-md border-b border-slate-200/90 shadow-sm">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between min-h-[96px] py-3.5 sm:py-4">
                
                <!-- Logo & Civic Title (Enlarged) -->
                <div class="flex items-center gap-4 sm:gap-5">
                    <img src="assets/images/logo.png" alt="SorokSurokkha Logo" class="w-16 h-16 sm:w-20 sm:h-20 object-contain drop-shadow-xs">
                    <div class="flex flex-col">
                        <div class="flex items-center gap-2.5 sm:gap-3 flex-wrap">
                            <span class="text-2xl sm:text-3xl lg:text-4xl font-black text-slate-900 tracking-tight" data-i18n="app_title">SorokSurokkha</span>
                            <span class="text-xs sm:text-sm font-extrabold uppercase tracking-wider px-2.5 sm:px-3 py-1 rounded-lg bg-sky-50 text-sky-700 border border-sky-200 shadow-2xs" data-i18n="authority_badge">
                                Road Authority
                            </span>
                        </div>
                        <span class="text-xs sm:text-sm text-slate-500 font-semibold hidden sm:block mt-0.5" data-i18n="app_subtitle">Hazard Monitoring & Pothole Repair Management</span>
                    </div>
                </div>

                <!-- Right Utility Bar (Enlarged) -->
                <div class="flex items-center gap-3 sm:gap-4 flex-wrap justify-end">
                    <!-- Segment of language changing (বাংলা / English) -->
                    <div class="flex items-center bg-slate-100 p-1 rounded-xl border border-slate-200 select-none shadow-xs" role="group" aria-label="Language Selector">
                        <button type="button" id="lang-btn-bn" onclick="setAppLanguage('bn')" 
                                class="px-3 sm:px-4 py-2 rounded-lg transition-all duration-150 flex items-center gap-1.5 font-bold text-xs sm:text-sm text-slate-600 hover:text-slate-900 cursor-pointer">
                            <span>বাংলা</span>
                        </button>
                        <button type="button" id="lang-btn-en" onclick="setAppLanguage('en')" 
                                class="px-3 sm:px-4 py-2 rounded-lg transition-all duration-150 flex items-center gap-1.5 font-bold text-xs sm:text-sm text-slate-600 hover:text-slate-900 cursor-pointer">
                            <span>English</span>
                        </button>
                    </div>



                    <?php if ($authUser): ?>
                        <!-- User Profile Info & Logout -->
                        <div class="flex items-center gap-2">
                            <div class="hidden md:flex flex-col text-right">
                                <span class="text-xs font-bold text-slate-800 leading-tight"><?= htmlspecialchars($authUser['name']) ?></span>
                                <span class="text-[10px] text-slate-400 font-semibold uppercase tracking-wider"><?= htmlspecialchars($authUser['role']) ?></span>
                            </div>
                            <button type="button" onclick="handleAuthorityLogout()" title="Sign Out"
                                    class="p-2 sm:px-3 sm:py-2 rounded-xl text-xs sm:text-sm font-bold flex items-center gap-1 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 transition cursor-pointer">
                                <i data-lucide="log-out" class="w-4 h-4"></i>
                                <span class="hidden sm:inline" data-i18n="nav_logout">Logout</span>
                            </button>
                        </div>
                    <?php else: ?>
                        <a href="login.php" class="px-3.5 sm:px-4 py-2 sm:py-2.5 rounded-xl text-xs sm:text-sm font-bold flex items-center gap-1.5 bg-sky-600 hover:bg-sky-500 text-white transition shadow-sm cursor-pointer">
                            <i data-lucide="log-in" class="w-4 h-4"></i>
                            <span data-i18n="nav_login">Sign In</span>
                        </a>
                    <?php endif; ?>
                </div>

            </div>
        </div>
    </header>
