<?php
/**
 * Construction Crew Web Dashboard - SorokSurokkha
 * Specialized portal for field engineers and road repair crews
 * Upazilla-specific task tracking, status updates, live GIS map, and crew collaboration
 */

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/geo_helper.php';

// Auth check: Must be logged in
if (!Auth::check()) {
    header("Location: login.php");
    exit;
}

$currentUser = Auth::user();
$crewName = $currentUser['name'] ?? 'Field Engineer';
$crewRole = $currentUser['role'] ?? 'crew';
$crewUpazilla = $currentUser['upazilla'] ?? 'Khan Jahan Ali';
$crewDistrict = $currentUser['district'] ?? 'Khulna';
$crewDivision = $currentUser['division'] ?? 'Khulna';
$crewTeam = $currentUser['team_name'] ?? 'Highway Repair Unit';
$crewId = $currentUser['id'] ?? 'USR-CREW-001';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SorokSurokkha - Construction Crew Dashboard (<?= htmlspecialchars($crewUpazilla) ?>)</title>
    <link rel="icon" type="image/png" href="assets/images/logo.png">

    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        crew: {
                            50: '#fffbeb',
                            100: '#fef3c7',
                            500: '#f59e0b',
                            600: '#d97706',
                            700: '#b45309',
                            800: '#92400e',
                            900: '#78350f',
                        }
                    }
                }
            }
        }
    </script>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Hind+Siliguri:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">

    <!-- Leaflet GIS Map CSS -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>

    <!-- Lucide Icons -->
    <script src="https://unpkg.com/lucide@latest"></script>

    <!-- Supabase Real-time Cloud Client SDK -->
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>

    <!-- App Styles -->
    <link rel="stylesheet" href="assets/css/style.css?v=<?= time() ?>">

    <!-- Bilingual Translation Engine -->
    <script src="assets/js/i18n.js?v=<?= time() ?>"></script>
</head>
<body class="bg-slate-50 text-slate-800 min-h-screen flex flex-col font-sans antialiased">

    <!-- Top Administrative & Crew Header -->
    <header class="sticky top-0 z-[1050] bg-white/95 backdrop-blur-md border-b border-slate-200/90 shadow-sm">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between min-h-[96px] py-3.5 sm:py-4">
                
                <!-- Logo & Crew Brand -->
                <div class="flex items-center gap-4 sm:gap-5">
                    <img src="assets/images/logo.png" alt="SorokSurokkha Logo" class="w-14 h-14 sm:w-16 sm:h-16 object-contain drop-shadow-xs">
                    <div class="flex flex-col">
                        <div class="flex items-center gap-2.5 sm:gap-3 flex-wrap">
                            <span class="text-xl sm:text-2xl lg:text-3xl font-black text-slate-900 tracking-tight" data-i18n="app_title">SorokSurokkha</span>
                            
                            <!-- Crew Badge -->
                            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs sm:text-sm font-extrabold uppercase tracking-wider bg-amber-50 text-amber-800 border border-amber-300 shadow-2xs">
                                <i data-lucide="hard-hat" class="w-4 h-4 text-amber-600"></i>
                                <span id="badge-crew-title">Construction Crew</span>
                            </span>


                        </div>
                        <span class="text-xs sm:text-sm text-slate-500 font-semibold hidden sm:block mt-0.5">
                            <span class="text-slate-800 font-bold"><?= htmlspecialchars($crewName) ?></span> &bull; <?= htmlspecialchars($crewTeam) ?>
                        </span>
                    </div>
                </div>

                <!-- Right Utility Bar -->
                <div class="flex items-center gap-3 sm:gap-4 flex-wrap justify-end">
                    <!-- Segment of language changing (বাংলা / English) -->
                    <div class="flex items-center bg-slate-100 p-1 rounded-xl border border-slate-200 select-none shadow-xs" role="group">
                        <button type="button" id="lang-btn-bn" onclick="setAppLanguage('bn')" 
                                class="px-3.5 py-2 rounded-lg transition-all duration-150 flex items-center gap-1 font-bold text-xs sm:text-sm text-slate-600 hover:text-slate-900 cursor-pointer">
                            <span>বাংলা</span>
                        </button>
                        <button type="button" id="lang-btn-en" onclick="setAppLanguage('en')" 
                                class="px-3.5 py-2 rounded-lg transition-all duration-150 flex items-center gap-1 font-bold text-xs sm:text-sm text-slate-600 hover:text-slate-900 cursor-pointer">
                            <span>English</span>
                        </button>
                    </div>



                    <!-- Logout Button -->
                    <button type="button" onclick="handleLogout()" title="Sign Out"
                            class="p-2 sm:px-3 sm:py-2 rounded-xl text-xs sm:text-sm font-bold flex items-center gap-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 transition cursor-pointer">
                        <i data-lucide="log-out" class="w-4 h-4"></i>
                        <span class="hidden sm:inline" id="nav-logout-text">Logout</span>
                    </button>
                </div>

            </div>
        </div>
    </header>

    <!-- Main Content Area -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 flex-1 w-full space-y-6">

        <!-- SCOPE SELECTOR & CREW BAR -->
        <div class="bg-white rounded-2xl p-4 sm:p-5 border border-slate-200/90 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
            
            <!-- Left: Scope Segment Selector (My Upazilla vs All Bangladesh) -->
            <div class="flex items-center gap-2 flex-wrap">
                <span class="text-xs font-bold uppercase tracking-wider text-slate-400 mr-1" id="lbl-scope">Record Scope:</span>
                
                <div class="inline-flex bg-slate-100 p-1 rounded-xl border border-slate-200 shadow-2xs">
                    <button type="button" id="btn-scope-upazilla" onclick="setCrewScope('upazilla')"
                            class="px-3.5 py-2 rounded-lg text-xs sm:text-sm font-bold flex items-center gap-1.5 transition cursor-pointer bg-amber-500 text-white shadow-xs">
                        <i data-lucide="map-pin" class="w-4 h-4"></i>
                        <span><span id="txt-my-upazilla-lbl">My Upazilla:</span> <strong id="scope-upazilla-name"><?= htmlspecialchars($crewUpazilla) ?></strong></span>
                        <span id="badge-scope-upazilla-count" class="ml-1 px-1.5 py-0.5 rounded-full text-[10px] font-bold bg-white/25 text-white">0</span>
                    </button>
                    <button type="button" id="btn-scope-national" onclick="setCrewScope('national')"
                            class="px-3.5 py-2 rounded-lg text-xs sm:text-sm font-bold flex items-center gap-1.5 transition cursor-pointer text-slate-600 hover:text-slate-900">
                        <i data-lucide="globe" class="w-4 h-4"></i>
                        <span id="txt-all-bd-lbl">All Bangladesh</span>
                        <span id="badge-scope-national-count" class="ml-1 px-1.5 py-0.5 rounded-full text-[10px] font-bold bg-slate-200 text-slate-700">0</span>
                    </button>
                </div>
            </div>

            <!-- Right: Assigned Filter & Search -->
            <div class="flex items-center gap-3 flex-wrap">
                <div class="inline-flex bg-slate-100 p-1 rounded-xl border border-slate-200 text-xs font-bold">
                    <button type="button" id="btn-filter-assigned-all" onclick="setAssignmentFilter('all')"
                            class="px-3 py-1.5 rounded-lg transition cursor-pointer bg-white text-slate-900 shadow-2xs">
                        <span id="txt-filter-all">🔍 All Upazilla Hazards</span>
                    </button>
                    <button type="button" id="btn-filter-assigned-me" onclick="setAssignmentFilter('me')"
                            class="px-3 py-1.5 rounded-lg transition cursor-pointer text-slate-500 hover:text-slate-800">
                        <span id="txt-filter-me">📋 Assigned to Me</span>
                    </button>
                </div>


            </div>
        </div>

        <!-- Dynamic Scope Notice Banner -->
        <div id="crew-scope-notice" class="hidden px-4 py-3 rounded-2xl bg-amber-50/90 border border-amber-200 text-xs text-amber-900 font-medium flex items-center gap-2.5 shadow-2xs">
            <!-- Dynamically populated if 0 records in current upazilla -->
        </div>

        <!-- KPI SUMMARY CARDS -->
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <!-- 1. My Assigned Tasks -->
            <div class="bg-white rounded-2xl p-4 sm:p-5 border border-slate-200 shadow-sm flex items-center justify-between">
                <div>
                    <span class="text-xs font-bold uppercase tracking-wider text-slate-500" id="kpi-title-assigned">My Assigned Tasks</span>
                    <div class="text-2xl sm:text-3xl font-black text-slate-900 mt-1" id="kpi-my-assigned">0</div>
                    <span class="text-[11px] text-amber-600 font-semibold" id="kpi-sub-assigned">Active Work Orders</span>
                </div>
                <div class="w-12 h-12 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center shrink-0 border border-amber-200">
                    <i data-lucide="hard-hat" class="w-6 h-6"></i>
                </div>
            </div>

            <!-- 2. Under Repair -->
            <div class="bg-white rounded-2xl p-4 sm:p-5 border border-slate-200 shadow-sm flex items-center justify-between">
                <div>
                    <span class="text-xs font-bold uppercase tracking-wider text-slate-500" id="kpi-title-in-repair">Under Repair</span>
                    <div class="text-2xl sm:text-3xl font-black text-sky-600 mt-1" id="kpi-under-repair">0</div>
                    <span class="text-[11px] text-sky-600 font-semibold" id="kpi-sub-repair">Work In Progress</span>
                </div>
                <div class="w-12 h-12 rounded-xl bg-sky-50 text-sky-600 flex items-center justify-center shrink-0 border border-sky-200">
                    <i data-lucide="wrench" class="w-6 h-6"></i>
                </div>
            </div>

            <!-- 3. Completed / Resolved -->
            <div class="bg-white rounded-2xl p-4 sm:p-5 border border-slate-200 shadow-sm flex items-center justify-between">
                <div>
                    <span class="text-xs font-bold uppercase tracking-wider text-slate-500" id="kpi-title-completed">Repaired & Resolved</span>
                    <div class="text-2xl sm:text-3xl font-black text-emerald-600 mt-1" id="kpi-completed">0</div>
                    <span class="text-[11px] text-emerald-600 font-semibold" id="kpi-sub-completed">Traffic Restored</span>
                </div>
                <div class="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0 border border-emerald-200">
                    <i data-lucide="check-circle" class="w-6 h-6"></i>
                </div>
            </div>

            <!-- 4. Critical Hazards -->
            <div class="bg-white rounded-2xl p-4 sm:p-5 border border-slate-200 shadow-sm flex items-center justify-between">
                <div>
                    <span class="text-xs font-bold uppercase tracking-wider text-slate-500" id="kpi-title-critical">Critical Severity</span>
                    <div class="text-2xl sm:text-3xl font-black text-rose-600 mt-1" id="kpi-critical">0</div>
                    <span class="text-[11px] text-rose-600 font-semibold" id="kpi-sub-critical">Urgent Safety Hazard</span>
                </div>
                <div class="w-12 h-12 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center shrink-0 border border-rose-200">
                    <i data-lucide="alert-triangle" class="w-6 h-6"></i>
                </div>
            </div>
        </div>

        <!-- LIVE GIS ROAD HAZARD MAP FOR CREW -->
        <section id="crew-gis-section" class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden relative z-10 isolate scroll-mt-28 sm:scroll-mt-32">
            <div class="p-4 sm:p-5 border-b border-slate-100 flex items-center justify-between flex-wrap gap-3">
                <div class="flex items-center gap-2.5">
                    <div class="w-9 h-9 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center border border-amber-200">
                        <i data-lucide="map" class="w-5 h-5"></i>
                    </div>
                    <div>
                        <h2 class="text-base sm:text-lg font-bold text-slate-900" id="map-heading-crew">
                            Live GIS Road Hazard Map &bull; <span class="text-amber-600 font-bold"><?= htmlspecialchars($crewUpazilla) ?> Focus</span>
                        </h2>
                        <p class="text-xs text-slate-500" id="map-sub-crew">Field location pins colored by severity. Pulsing radar on high-risk pavement defects.</p>
                    </div>
                </div>

                <!-- Map Action Controls: Only My Location button -->
                <div class="flex items-center gap-2">
                    <button type="button" onclick="locateCrewPosition()" 
                            class="px-3.5 py-2 rounded-xl bg-sky-50 hover:bg-sky-100 text-sky-700 text-xs font-bold flex items-center gap-1.5 transition cursor-pointer border border-sky-200 shadow-2xs">
                        <i data-lucide="navigation" class="w-3.5 h-3.5 text-sky-600"></i>
                        <span id="crew-locate-text">My Location</span>
                    </button>
                </div>
            </div>

            <!-- Live Crew Location Status Chip -->
            <div id="crew-location-chip" class="hidden items-center gap-2 px-3.5 py-2 mx-4 sm:mx-5 my-2.5 rounded-xl bg-sky-50 border border-sky-200 text-xs text-sky-900 font-medium">
                <!-- Dynamically populated with live GPS position and nearest hazard -->
            </div>

            <!-- Map Container -->
            <div class="relative w-full h-[400px] sm:h-[480px]">
                <div id="crew-hazard-map" class="w-full h-full"></div>
            </div>
        </section>

        <!-- ROAD REPAIR TASKS & POTHOLE RECORDS TABLE -->
        <section class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div class="p-4 sm:p-5 border-b border-slate-100 flex flex-col md:flex-row md:items-center justify-between gap-3">
                <div class="flex items-center gap-2.5">
                    <div class="w-9 h-9 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center border border-amber-200">
                        <i data-lucide="clipboard-list" class="w-5 h-5"></i>
                    </div>
                    <div>
                        <h3 class="text-base sm:text-lg font-bold text-slate-900" id="table-heading-crew">
                            Road Repair Assignments & Pothole Records
                        </h3>
                        <p class="text-xs text-slate-500" id="table-sub-crew">
                            <span id="crew-records-count">0 records</span> in view &bull; Change lifecycle status as work progresses on site.
                        </p>
                    </div>
                </div>

                <!-- Search inside table -->
                <div class="relative min-w-[240px]">
                    <i data-lucide="search" class="w-4 h-4 text-slate-400 absolute left-3 top-2.5"></i>
                    <input type="text" id="crew-search-input" oninput="applyCrewFilters()"
                           placeholder="Search by ID, Road, Crew..."
                           class="w-full pl-9 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-amber-500 transition">
                </div>
            </div>

            <!-- Table -->
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm">
                    <thead class="bg-slate-50/80 text-[11px] font-bold uppercase text-slate-500 border-b border-slate-200">
                        <tr>
                            <th class="py-3 px-4" id="th-photo">Photo</th>
                            <th class="py-3 px-4" id="th-id-date">Defect ID & Date</th>
                            <th class="py-3 px-4" id="th-location">Location & Coordinates</th>
                            <th class="py-3 px-4" id="th-severity">Severity & Conf</th>
                            <th class="py-3 px-4" id="th-assigned-crew">Assigned Crew</th>
                            <th class="py-3 px-4" id="th-repair-photo">Upload Repaired Photo Image</th>
                            <th class="py-3 px-4" id="th-status">Lifecycle Status</th>
                            <th class="py-3 px-4 text-right" id="th-actions">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="crew-table-body" class="divide-y divide-slate-100">
                        <tr>
                            <td colspan="8" class="py-12 text-center text-slate-400">
                                <i data-lucide="loader" class="w-6 h-6 animate-spin inline mb-2"></i>
                                <div>Loading road repair records...</div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </section>

        <!-- "OTHER CREWS IN MY UPAZILLA" SECTION -->
        <section class="bg-white rounded-2xl border border-slate-200 shadow-sm p-4 sm:p-5 space-y-4">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-100 pb-3">
                <div class="flex items-center gap-2.5">
                    <div class="w-9 h-9 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center border border-indigo-200">
                        <i data-lucide="users" class="w-5 h-5"></i>
                    </div>
                    <div>
                        <h4 class="text-base font-bold text-slate-900" id="other-crews-heading">
                            Other Construction Crews in <span class="text-indigo-600 font-extrabold"><?= htmlspecialchars($crewUpazilla) ?></span>
                        </h4>
                        <p class="text-xs text-slate-500" id="other-crews-sub">
                            Peer road maintenance units assigned to other pothole repairs in this jurisdiction.
                        </p>
                    </div>
                </div>

                <!-- Search other crews -->
                <div class="relative min-w-[200px]">
                    <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3 top-2.5"></i>
                    <input type="text" id="peer-crew-search" oninput="filterPeerCrews()"
                           placeholder="Search other crews..."
                           class="w-full pl-8 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500 transition">
                </div>
            </div>

            <!-- Peer Crews Cards Container -->
            <div id="peer-crews-list" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                <!-- Injected via JavaScript -->
            </div>
        </section>

    </main>

    <!-- FOOTER -->
    <footer class="bg-white border-t border-slate-200 py-6 mt-12">
        <div class="max-w-7xl mx-auto px-4 text-center text-xs text-slate-500 space-y-1">
            <p>&copy; <?= date('Y') ?> SorokSurokkha &bull; Road & Highway Authority Construction Management Portal.</p>
            <p>Active User: <strong class="text-slate-800"><?= htmlspecialchars($crewName) ?></strong> (<?= htmlspecialchars($crewRole) ?>) &bull; Upazilla: <?= htmlspecialchars($crewUpazilla) ?>, <?= htmlspecialchars($crewDistrict) ?></p>
        </div>
    </footer>

    <!-- ================= CREW REPAIR PROGRESS MODAL ================= -->
    <div id="crew-repair-modal" class="fixed inset-0 z-50 hidden bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto">
        <div class="bg-white w-full max-w-lg rounded-2xl shadow-2xl border border-slate-200 overflow-hidden transform transition-all my-8">
            
            <div class="p-4 sm:p-5 bg-gradient-to-r from-amber-500 to-amber-600 text-white flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <i data-lucide="wrench" class="w-5 h-5"></i>
                    <h3 class="font-bold text-base sm:text-lg" id="modal-repair-title">Update Road Repair Progress</h3>
                </div>
                <button type="button" onclick="closeCrewRepairModal()" class="text-white/80 hover:text-white p-1 rounded-lg hover:bg-white/10 transition cursor-pointer">
                    <i data-lucide="x" class="w-5 h-5"></i>
                </button>
            </div>

            <form id="form-crew-repair" onsubmit="submitCrewRepair(event)" class="p-5 space-y-4">
                <input type="hidden" id="modal-report-id">

                <!-- Target Defect Preview -->
                <div class="p-3 bg-slate-50 rounded-xl border border-slate-200 flex items-center gap-3">
                    <img id="modal-defect-img" src="" alt="Defect" class="w-16 h-16 rounded-lg object-cover border border-slate-300 shrink-0">
                    <div class="min-w-0 flex-1">
                        <div class="flex items-center gap-2">
                            <span class="font-bold text-slate-900 text-sm" id="modal-defect-id">RPT-XXXX</span>
                            <span class="px-2 py-0.5 rounded text-[10px] font-bold" id="modal-defect-sev">HIGH</span>
                        </div>
                        <div class="text-xs text-slate-600 truncate mt-0.5" id="modal-defect-road">Road Name</div>
                        <div class="text-[11px] text-sky-700 font-mono mt-0.5" id="modal-defect-coords">0.0, 0.0</div>
                    </div>
                </div>

                <!-- Status Selector: verified -> under_repair -> resolved -->
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5" id="modal-lbl-status">
                        Current Lifecycle Status
                    </label>
                    <select id="modal-new-status" class="w-full bg-slate-50 border border-slate-300 rounded-xl px-3.5 py-2.5 text-sm font-semibold text-slate-900 focus:outline-none focus:border-amber-500 focus:bg-white">
                        <option value="verified">🔍 Verified</option>
                        <option value="under_repair">🔧 Under Repair</option>
                        <option value="resolved">✅ Repaired / Resolved</option>
                    </select>
                </div>

                <!-- Repair Notes & Materials -->
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5" id="modal-lbl-notes">
                        Field Repair Notes & Materials Used
                    </label>
                    <textarea id="modal-repair-notes" rows="3"
                              placeholder="e.g. Cleared water and debris. Applied 40mm bitumen hot-mix asphalt with compaction roller. Traffic restored."
                              class="w-full bg-slate-50 border border-slate-300 rounded-xl p-3 text-xs sm:text-sm text-slate-900 focus:outline-none focus:border-amber-500 focus:bg-white"></textarea>
                </div>

                <!-- Proof of Repair Photo Upload -->
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5" id="modal-lbl-photo">
                        Upload Repair Proof Photo
                    </label>
                    <input type="file" id="modal-repair-file" accept="image/*"
                           class="w-full text-xs text-slate-500 file:mr-3 file:py-2 file:px-3.5 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-amber-50 file:text-amber-700 hover:file:bg-amber-100 cursor-pointer">
                </div>

                <!-- Submit Button -->
                <div class="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
                    <button type="button" onclick="closeCrewRepairModal()" class="px-4 py-2 text-xs font-bold text-slate-600 hover:text-slate-800 transition cursor-pointer" id="modal-btn-cancel">
                        Cancel
                    </button>
                    <button type="submit" id="modal-btn-submit"
                            class="px-5 py-2.5 bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold rounded-xl shadow-md transition flex items-center gap-1.5 cursor-pointer">
                        <i data-lucide="check" class="w-4 h-4"></i>
                        <span id="modal-btn-save-text">Save Status Update</span>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Pass Current User Session Config to JS -->
    <script>
        const CREW_CONFIG = {
            userId: <?= json_encode($crewId) ?>,
            userName: <?= json_encode($crewName) ?>,
            userRole: <?= json_encode($crewRole) ?>,
            upazilla: <?= json_encode($crewUpazilla) ?>,
            district: <?= json_encode($crewDistrict) ?>,
            division: <?= json_encode($crewDivision) ?>,
            teamName: <?= json_encode($crewTeam) ?>
        };
    </script>

    <!-- Leaflet JS -->
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>

    <!-- Crew Application Scripts -->
    <script src="assets/js/crew_map.js?v=<?= time() ?>"></script>
    <script src="assets/js/crew_app.js?v=<?= time() ?>"></script>
</body>
</html>
