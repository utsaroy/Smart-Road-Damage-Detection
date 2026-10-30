<?php
/**
 * Common Header for Road Authority Portal - SorokSurokkha
 * Professional Civic & Municipal Light Design
 */
require_once __DIR__ . '/../config/database.php';
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
    
    <!-- Google Fonts: Plus Jakarta Sans & JetBrains Mono -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    
    <!-- Leaflet GIS Map CSS -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
    
    <!-- Lucide Icons -->
    <script src="https://unpkg.com/lucide@latest"></script>

    <!-- Supabase Cloud Client SDK -->
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>

    <!-- Custom CSS -->
    <link rel="stylesheet" href="assets/css/style.css?v=<?= time() ?>">
</head>
<body class="bg-slate-50 text-slate-800 min-h-screen flex flex-col font-sans antialiased">

    <!-- Top Administrative Header -->
    <header class="sticky top-0 z-50 bg-white border-b border-slate-200/90 shadow-xs">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-20">
                
                <!-- Logo & Civic Title -->
                <div class="flex items-center gap-3.5">
                    <img src="assets/images/logo.png" alt="SorokSurokkha Logo" class="w-13 h-13 sm:w-14 sm:h-14 object-contain">
                    <div class="flex flex-col">
                        <div class="flex items-center gap-2">
                            <span class="text-xl font-extrabold text-slate-900 tracking-tight">SorokSurokkha</span>
                            <span class="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-md bg-sky-50 text-sky-700 border border-sky-200">
                                Road Authority
                            </span>
                        </div>
                        <span class="text-[11px] text-slate-500 font-medium hidden sm:block">Hazard Monitoring & Pothole Repair Management</span>
                    </div>
                </div>

                <!-- Right Utility Bar -->
                <div class="flex items-center gap-3">
                    <div class="hidden md:flex items-center gap-2 px-3 py-1 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200 text-xs font-semibold">
                        <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                        <span>Live Sync Active</span>
                    </div>

                    <a href="index.php" class="px-3.5 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 bg-slate-900 hover:bg-slate-800 text-white transition shadow-sm">
                        <i data-lucide="layout-dashboard" class="w-3.5 h-3.5"></i>
                        <span>Dashboard</span>
                    </a>
                </div>

            </div>
        </div>
    </header>
