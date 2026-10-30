<?php
/**
 * SorokSurokkha - Road Hazard & Pothole Management Portal
 * Professional Civic & Municipal Light Design
 */
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/includes/header.php';
?>

<main class="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-6">

    <!-- KPI Metric Summary Tiles -->
    <section class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3.5">
        <!-- Total Detected -->
        <div class="bg-white border border-slate-200/90 rounded-xl p-4 flex flex-col justify-between shadow-2xs hover:shadow-xs transition">
            <div class="flex items-center justify-between text-slate-500 mb-2">
                <span class="text-[11px] font-bold uppercase tracking-wider">Total Hazards</span>
                <i data-lucide="layers" class="w-4 h-4 text-sky-600"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-total" class="text-2xl font-black text-slate-900 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-slate-400">detected</span>
            </div>
        </div>

        <!-- High & Critical Severity -->
        <div class="bg-white border border-slate-200/90 rounded-xl p-4 flex flex-col justify-between shadow-2xs hover:shadow-xs transition">
            <div class="flex items-center justify-between mb-2">
                <span class="text-[11px] font-bold uppercase tracking-wider text-rose-600">Critical / High</span>
                <i data-lucide="alert-triangle" class="w-4 h-4 text-rose-500"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-high" class="text-2xl font-black text-rose-600 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-rose-400">priority</span>
            </div>
        </div>

        <!-- Pending Review -->
        <div class="bg-white border border-slate-200/90 rounded-xl p-4 flex flex-col justify-between shadow-2xs hover:shadow-xs transition">
            <div class="flex items-center justify-between mb-2">
                <span class="text-[11px] font-bold uppercase tracking-wider text-amber-600">Pending Review</span>
                <i data-lucide="clock" class="w-4 h-4 text-amber-500"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-pending" class="text-2xl font-black text-amber-600 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-slate-400">unassigned</span>
            </div>
        </div>

        <!-- Under Maintenance / In Progress -->
        <div class="bg-white border border-slate-200/90 rounded-xl p-4 flex flex-col justify-between shadow-2xs hover:shadow-xs transition">
            <div class="flex items-center justify-between mb-2">
                <span class="text-[11px] font-bold uppercase tracking-wider text-sky-600">In Progress</span>
                <i data-lucide="wrench" class="w-4 h-4 text-sky-500"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-progress" class="text-2xl font-black text-sky-600 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-slate-400">crews active</span>
            </div>
        </div>

        <!-- Resolved -->
        <div class="bg-white border border-slate-200/90 rounded-xl p-4 flex flex-col justify-between shadow-2xs hover:shadow-xs transition">
            <div class="flex items-center justify-between mb-2">
                <span class="text-[11px] font-bold uppercase tracking-wider text-emerald-600">Resolved</span>
                <i data-lucide="check-circle-2" class="w-4 h-4 text-emerald-500"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-resolved" class="text-2xl font-black text-emerald-600 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-slate-400">repaired</span>
            </div>
        </div>

        <!-- Contributing Citizens -->
        <div class="bg-white border border-slate-200/90 rounded-xl p-4 flex flex-col justify-between shadow-2xs hover:shadow-xs transition">
            <div class="flex items-center justify-between mb-2">
                <span class="text-[11px] font-bold uppercase tracking-wider text-purple-600">App Users</span>
                <i data-lucide="users" class="w-4 h-4 text-purple-500"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-users" class="text-2xl font-black text-purple-600 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-slate-400">citizens</span>
            </div>
        </div>
    </section>

    <!-- Upazilla-wise Pothole Density Ratio & Geographic Analytics Section -->
    <section class="bg-white border border-slate-200/90 rounded-xl p-5 shadow-xs space-y-5">
        
        <!-- Header & Breadcrumb / Scope Indicator -->
        <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-3 border-b border-slate-100 pb-4">
            <div>
                <h2 class="text-base font-bold text-slate-900 flex items-center gap-2">
                    <i data-lucide="pie-chart" class="w-4.5 h-4.5 text-sky-600"></i>
                    <span>Upazilla Pothole Density Ratio & Hotspot Analytics</span>
                </h2>
                <p class="text-xs text-slate-500">Live density percentages calculated based on pothole locations in database to guide authority repair prioritization</p>
            </div>

            <!-- Total Scope Info Pill -->
            <div class="flex items-center gap-3">
                <div class="bg-slate-50 border border-slate-200 rounded-lg px-3 py-1.5 flex items-center gap-2">
                    <i data-lucide="map-pin" class="w-4 h-4 text-rose-500"></i>
                    <div>
                        <div class="text-[10px] uppercase font-bold text-slate-400">Monitored Upazillas</div>
                        <div id="stat-geo-upazillas-count" class="text-sm font-black text-slate-900">0</div>
                    </div>
                </div>
                <div class="bg-slate-50 border border-slate-200 rounded-lg px-3 py-1.5 flex items-center gap-2">
                    <i data-lucide="alert-octagon" class="w-4 h-4 text-amber-500"></i>
                    <div>
                        <div class="text-[10px] uppercase font-bold text-slate-400">Total Hazards Analyzed</div>
                        <div id="stat-geo-hazards-count" class="text-sm font-black text-slate-900">0</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Multi-tier Cascading Filter Bar: Division -> District -> Upazilla + Search -->
        <div class="bg-slate-50/80 border border-slate-200/90 rounded-xl p-3.5 space-y-3">
            <div class="text-xs font-bold text-slate-700 flex items-center gap-1.5">
                <i data-lucide="filter" class="w-3.5 h-3.5 text-sky-600"></i>
                <span>Hierarchical Geographic Filter (Select Division &rarr; District &rarr; Upazilla):</span>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-2.5">
                <!-- 1. Division Selector -->
                <div>
                    <label class="block text-[11px] font-semibold text-slate-500 mb-1">1. Select Division</label>
                    <select id="geo-division-select" onchange="onDivisionChange()" 
                            class="w-full bg-white border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-800 focus:outline-none focus:border-sky-500 transition cursor-pointer">
                        <option value="all">All Divisions</option>
                    </select>
                </div>

                <!-- 2. District Selector -->
                <div>
                    <label class="block text-[11px] font-semibold text-slate-500 mb-1">2. Select District</label>
                    <select id="geo-district-select" onchange="onDistrictChange()" 
                            class="w-full bg-white border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-800 focus:outline-none focus:border-sky-500 transition cursor-pointer">
                        <option value="all">All Districts</option>
                    </select>
                </div>

                <!-- 3. Upazilla Selector -->
                <div>
                    <label class="block text-[11px] font-semibold text-slate-500 mb-1">3. Select Upazilla</label>
                    <select id="geo-upazilla-select" onchange="onUpazillaChange()" 
                            class="w-full bg-white border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-800 focus:outline-none focus:border-sky-500 transition cursor-pointer">
                        <option value="all">All Upazillas</option>
                    </select>
                </div>

                <!-- 4. Quick Upazilla Search -->
                <div>
                    <label class="block text-[11px] font-semibold text-slate-500 mb-1">Quick Upazilla Search</label>
                    <div class="relative">
                        <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-2.5 top-2"></i>
                        <input type="text" id="geo-upazilla-search" oninput="onUpazillaSearchInput()" placeholder="Type upazilla name..." 
                               class="w-full bg-white border border-slate-200 rounded-lg pl-8 pr-2 py-1.5 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:border-sky-500 transition">
                    </div>
                </div>

                <!-- 5. Reset Action Button -->
                <div class="flex items-end">
                    <button type="button" onclick="resetGeoFilters()" 
                            class="w-full bg-slate-200 hover:bg-slate-300 text-slate-700 rounded-lg px-3 py-1.5 text-xs font-semibold transition flex items-center justify-center gap-1.5 shadow-2xs">
                        <i data-lucide="rotate-ccw" class="w-3.5 h-3.5"></i>
                        <span>Reset Filters</span>
                    </button>
                </div>
            </div>
        </div>

        <!-- Particular Upazilla Highlight Card (Shown when an upazilla is filtered/selected) -->
        <div id="particular-upazilla-card" class="hidden bg-gradient-to-r from-sky-50 via-slate-50 to-indigo-50 border border-sky-200 rounded-xl p-4.5 space-y-3">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-sky-100 pb-2.5">
                <div class="flex items-center gap-2">
                    <span id="particular-badge-grade" class="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-rose-100 text-rose-700 border border-rose-200">
                        CRITICAL HOTSPOT
                    </span>
                    <h3 id="particular-name" class="text-base font-extrabold text-slate-900">Khan Jahan Ali Upazilla</h3>
                    <span id="particular-region" class="text-xs text-slate-500">Khulna District, Khulna Division</span>
                </div>
                <div class="flex items-center gap-2">
                    <button type="button" onclick="focusParticularOnMap()" class="px-3 py-1 bg-sky-600 hover:bg-sky-700 text-white rounded-lg text-xs font-bold transition flex items-center gap-1 shadow-xs">
                        <i data-lucide="navigation" class="w-3 h-3"></i>
                        <span>Focus on Map</span>
                    </button>
                    <button type="button" onclick="filterTableToParticular()" class="px-3 py-1 bg-white hover:bg-slate-100 text-slate-700 rounded-lg text-xs font-semibold border border-slate-200 transition flex items-center gap-1 shadow-2xs">
                        <i data-lucide="table" class="w-3 h-3"></i>
                        <span>View Records</span>
                    </button>
                </div>
            </div>

            <!-- Particular Stats Grid -->
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
                <div class="bg-white/80 rounded-lg p-2.5 border border-sky-100">
                    <div class="text-[10px] uppercase font-bold text-slate-400">Pothole Density Ratio</div>
                    <div id="particular-density-ratio" class="text-xl font-black text-rose-600">62.5%</div>
                    <div class="text-[10px] text-slate-500">of total recorded defects</div>
                </div>
                <div class="bg-white/80 rounded-lg p-2.5 border border-sky-100">
                    <div class="text-[10px] uppercase font-bold text-slate-400">Total Hazards in Upazilla</div>
                    <div id="particular-total" class="text-xl font-black text-slate-900">10</div>
                    <div id="particular-severity-sub" class="text-[10px] text-rose-500 font-medium">4 Critical &bull; 5 High</div>
                </div>
                <div class="bg-white/80 rounded-lg p-2.5 border border-sky-100">
                    <div class="text-[10px] uppercase font-bold text-slate-400">Repair Status</div>
                    <div id="particular-status" class="text-xl font-black text-amber-600">0 Pending</div>
                    <div id="particular-crew-sub" class="text-[10px] text-slate-500">Inspection queue</div>
                </div>
                <div class="bg-white/80 rounded-lg p-2.5 border border-sky-100">
                    <div class="text-[10px] uppercase font-bold text-slate-400">Authority Action</div>
                    <div id="particular-urgency" class="text-xs font-bold text-slate-800 mt-1">Routine Monitoring</div>
                    <div id="particular-action-sub" class="text-[10px] text-slate-500">Action guideline</div>
                </div>
            </div>

            <!-- Affected Roads in this Upazilla -->
            <div class="text-xs text-slate-600 bg-white/70 p-2.5 rounded-lg border border-sky-100 flex items-start gap-2">
                <i data-lucide="route" class="w-4 h-4 text-sky-600 shrink-0 mt-0.5"></i>
                <div>
                    <span class="font-bold text-slate-700">Major Affected Routes in this Upazilla: </span>
                    <span id="particular-roads" class="text-slate-600">Teligati Road, Khulna-Jashore Highway, Fulbarigate Junction</span>
                </div>
            </div>
        </div>

        <!-- Upazilla Density Ranking Leaderboard (Descending Order) -->
        <div class="space-y-2">
            <div class="flex items-center justify-between text-xs font-bold text-slate-700">
                <span class="flex items-center gap-1.5">
                    <i data-lucide="trending-down" class="w-3.5 h-3.5 text-rose-600"></i>
                    <span id="geo-table-heading">Upazilla Pothole Density Ratio (Ranked in Descending Order)</span>
                </span>
                <span class="text-[11px] text-slate-400 font-normal">Click any row to inspect or focus GIS map</span>
            </div>

            <!-- Clean Table / List of Ranked Upazillas -->
            <div class="overflow-x-auto rounded-lg border border-slate-200">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-slate-50 text-slate-600 text-[11px] font-bold uppercase tracking-wider border-b border-slate-200">
                            <th class="py-2.5 px-3.5 w-12 text-center">Rank</th>
                            <th class="py-2.5 px-3.5">Upazilla</th>
                            <th class="py-2.5 px-3.5">District & Division</th>
                            <th class="py-2.5 px-3.5 text-center">Potholes Count</th>
                            <th class="py-2.5 px-3.5 w-64">Density Ratio (% of All Hazards)</th>
                            <th class="py-2.5 px-3.5 text-center">Severity Profile</th>
                            <th class="py-2.5 px-3.5">Repair Urgency</th>
                            <th class="py-2.5 px-3.5 text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="upazilla-density-body" class="divide-y divide-slate-100 text-xs">
                        <tr>
                            <td colspan="8" class="text-center py-6 text-slate-400">
                                Loading upazilla-wise density analytics...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

    </section>

    <!-- Interactive GIS Road Hazard Map -->
    <section class="bg-white border border-slate-200/90 rounded-xl p-5 shadow-xs space-y-4">
        
        <!-- Header & Integrated Toolbar -->
        <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
            <div>
                <h2 class="text-base font-bold text-slate-900 flex items-center gap-2">
                    <i data-lucide="map" class="w-4 h-4 text-sky-600"></i>
                    <span>Live GIS Road Hazard Map</span>
                </h2>
                <p class="text-xs text-slate-500">Real-time GPS coordinates transmitted from mobile surveys and citizen reports</p>
            </div>

            <!-- Integrated Controls: Search + Refresh -->
            <div class="flex flex-wrap items-center gap-2">
                <div class="relative flex-1 sm:w-80">
                    <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3 top-2.5"></i>
                    <input type="text" id="osm-street-search" placeholder="Search street or city (e.g. Teligati Road, Mirpur Road)..." 
                           class="w-full bg-slate-50 border border-slate-200 rounded-lg pl-8 pr-20 py-1.5 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-sky-500 transition">
                    <button type="button" onclick="searchOsmStreet()" class="absolute right-1 top-1 px-2.5 py-1 rounded bg-slate-800 hover:bg-slate-700 text-[11px] font-semibold text-white transition">
                        Find
                    </button>
                </div>

                <button onclick="loadHazardsData()" class="px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-xs font-semibold text-slate-700 transition flex items-center gap-1.5 border border-slate-200 shadow-2xs">
                    <i data-lucide="refresh-cw" class="w-3.5 h-3.5"></i>
                    <span>Refresh</span>
                </button>
            </div>
        </div>

        <!-- Search Status Box -->
        <div id="osm-search-status" class="text-xs text-sky-700 bg-sky-50 px-3 py-1.5 rounded-lg border border-sky-200 hidden"></div>

        <!-- Live Authority GPS Status Chip -->
        <div id="authority-location-chip" class="hidden items-center gap-2 px-3.5 py-2 rounded-lg bg-sky-50 border border-sky-200 text-xs text-sky-900 font-medium">
            <!-- Dynamic Authority GPS & Proximity Info -->
        </div>

        <!-- The Map Canvas -->
        <div id="hazard-map" class="border border-slate-200 rounded-lg shadow-inner"></div>

        <!-- Professional Map Legend -->
        <div class="flex flex-wrap items-center justify-between gap-3 pt-2 text-xs text-slate-600 border-t border-slate-100">
            <div class="flex flex-wrap items-center gap-4">
                <span class="font-bold text-slate-700">Map Legend:</span>
                <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-sky-500"></span> Authority Position</span>
                <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-rose-500"></span> High / Critical Defect</span>
                <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-orange-500"></span> Medium Defect</span>
                <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-amber-400"></span> Low Defect</span>
                <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-emerald-500"></span> Repaired / Resolved</span>
            </div>
            <div class="text-[11px] text-slate-400">
                Tiles &copy; OpenStreetMap contributors
            </div>
        </div>
    </section>

    <!-- Authority Database Management Section -->
    <section class="bg-white border border-slate-200/90 rounded-xl p-5 shadow-xs space-y-4">
        
        <!-- Section Header & Filter Controls -->
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-3 pb-3 border-b border-slate-100">
            <div>
                <h2 class="text-base font-bold text-slate-900 flex items-center gap-2">
                    <i data-lucide="database" class="w-4 h-4 text-sky-600"></i>
                    <span>Road Hazard & Pothole Records</span>
                </h2>
                <span id="filter-count" class="text-xs text-slate-500 font-medium">Loading records...</span>
            </div>

            <!-- Filters Bar -->
            <div class="flex flex-wrap items-center gap-2">
                <!-- Search Input -->
                <div class="relative">
                    <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3 top-2.5"></i>
                    <input type="text" id="search-input" placeholder="Search by ID, User, Road..."
                           class="bg-slate-50 border border-slate-200 rounded-lg pl-8 pr-3 py-1.5 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-sky-500 w-48 sm:w-56 transition">
                </div>

                <!-- Citizen / User Filter -->
                <select id="filter-user" class="bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-700 focus:outline-none focus:bg-white focus:border-sky-500 cursor-pointer">
                    <option value="all">All Users</option>
                </select>

                <!-- Severity Filter -->
                <select id="filter-severity" class="bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-700 focus:outline-none focus:bg-white focus:border-sky-500 cursor-pointer">
                    <option value="all">All Severities</option>
                    <option value="CRITICAL">Critical</option>
                    <option value="HIGH">High</option>
                    <option value="MEDIUM">Medium</option>
                    <option value="LOW">Low</option>
                </select>

                <!-- Status Filter -->
                <select id="filter-status" class="bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-700 focus:outline-none focus:bg-white focus:border-sky-500 cursor-pointer">
                    <option value="all">All Statuses</option>
                    <option value="reported">Pending Review</option>
                    <option value="verified">Verified</option>
                    <option value="assigned">Assigned</option>
                    <option value="under_repair">Under Repair</option>
                    <option value="resolved">Resolved</option>
                </select>

                <!-- Export CSV Button -->
                <button onclick="exportToCSV()" class="px-3 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold transition flex items-center gap-1.5 border border-slate-200 shadow-2xs">
                    <i data-lucide="download" class="w-3.5 h-3.5"></i>
                    <span>Export CSV</span>
                </button>
            </div>
        </div>

        <!-- Clean Data Table -->
        <div class="overflow-x-auto rounded-lg border border-slate-200">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-50 text-slate-600 text-[11px] font-bold uppercase tracking-wider border-b border-slate-200">
                        <th class="py-3 px-4">Photo</th>
                        <th class="py-3 px-4">Record ID & Date</th>
                        <th class="py-3 px-4">Contributor / Device</th>
                        <th class="py-3 px-4">Severity & Confidence</th>
                        <th class="py-3 px-4">Location & Coordinates</th>
                        <th class="py-3 px-4">Lifecycle Status</th>
                        <th class="py-3 px-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody id="reports-table-body" class="divide-y divide-slate-100 text-xs">
                    <tr>
                        <td colspan="7" class="text-center py-10 text-slate-400">
                            Loading hazard records from all app users...
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </section>

</main>

<!-- Detailed Inspection Modal (Clean Administrative Modal) -->
<div id="inspection-modal" class="fixed inset-0 z-50 hidden bg-slate-900/40 backdrop-blur-xs items-center justify-center p-4 overflow-y-auto">
    <div class="bg-white border border-slate-200 rounded-2xl max-w-4xl w-full max-h-[92vh] overflow-y-auto shadow-xl p-6 text-slate-800 space-y-5">
        
        <!-- Modal Top Bar -->
        <div class="flex items-start justify-between border-b border-slate-100 pb-3">
            <div>
                <div class="flex items-center gap-2 mb-1">
                    <span id="modal-report-id" class="text-xs font-mono font-bold text-sky-700">RPT-1792217799588</span>
                    <span class="text-slate-300">&bull;</span>
                    <span id="modal-status-badge" class="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded bg-slate-100 text-slate-700 border border-slate-200">
                        DETECTED
                    </span>
                </div>
                <h3 id="modal-title" class="text-lg font-bold text-slate-900">Pothole Defect Details</h3>
            </div>
            <div class="flex items-center gap-3">
                <span id="modal-severity-badge" class="px-2.5 py-0.5 rounded text-xs font-bold uppercase tracking-wider bg-rose-50 text-rose-700 border border-rose-200">
                    HIGH
                </span>
                <button onclick="closeInspectionModal()" class="w-8 h-8 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-500 hover:text-slate-800 flex items-center justify-center transition text-lg font-semibold">
                    &times;
                </button>
            </div>
        </div>

        <!-- Body Grid: Left = Photographic Evidence & AI Metrics, Right = Authority Action -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-5">
            
            <!-- Left Side -->
            <div class="lg:col-span-7 space-y-4">
                
                <!-- Main Detection Image Box with AI Bounding Box Overlay -->
                <div class="relative rounded-xl bg-slate-950 overflow-hidden border border-slate-200 shadow-2xs">
                    <div class="absolute top-2.5 left-2.5 z-20 flex items-center gap-1.5 bg-slate-900/80 backdrop-blur px-2.5 py-1 rounded-md text-[11px] text-white font-medium">
                        <span class="w-2 h-2 rounded-full bg-rose-500 animate-pulse"></span>
                        <span id="modal-photo-caption">Field Mobile Photo & AI Detections</span>
                    </div>
                    <div class="relative w-full h-80 flex items-center justify-center">
                        <img id="modal-image" src="" alt="Detection Preview" class="w-full h-full object-contain">
                        <div id="modal-boxes-overlay" class="absolute inset-0 pointer-events-none"></div>
                    </div>
                </div>

                <!-- Citizen Contributor Info -->
                <div class="bg-slate-50 p-3.5 rounded-xl border border-slate-200 flex items-center justify-between text-xs">
                    <div class="flex items-center gap-3">
                        <div id="modal-user-avatar" class="w-9 h-9 rounded-full bg-sky-600 flex items-center justify-center text-xs font-black text-white shrink-0 shadow-xs">
                            U
                        </div>
                        <div>
                            <div class="text-[10px] text-slate-500 uppercase font-semibold">Submitted by Citizen Scanner</div>
                            <div id="modal-user-name" class="font-bold text-slate-900 text-sm">Munem Shahriar</div>
                            <div id="modal-user-device" class="text-[11px] text-slate-500 flex items-center gap-1 mt-0.5">
                                <i data-lucide="smartphone" class="w-3 h-3"></i>
                                <span>Samsung Galaxy S23 Ultra</span>
                            </div>
                        </div>
                    </div>
                    <div class="text-right">
                        <span id="modal-user-id" class="px-2 py-0.5 rounded bg-white border border-slate-200 font-mono text-[10px] text-sky-800 font-semibold">user_munem_01</span>
                        <div id="modal-user-phone" class="text-[11px] text-slate-500 mt-1"></div>
                    </div>
                </div>

                <!-- AI Detection Metrics -->
                <div>
                    <h4 class="text-xs font-bold text-slate-600 uppercase tracking-wider mb-2">AI Defect Assessment</h4>
                    <div class="grid grid-cols-3 gap-2">
                        <div class="bg-slate-50 p-3 rounded-lg border border-slate-200 text-center">
                            <i data-lucide="check-circle" class="w-4 h-4 text-sky-600 mx-auto mb-1"></i>
                            <div id="modal-conf" class="text-base font-extrabold text-slate-900">66.0%</div>
                            <div class="text-[10px] text-slate-500 font-medium">Confidence</div>
                        </div>
                        <div class="bg-slate-50 p-3 rounded-lg border border-slate-200 text-center">
                            <i data-lucide="gauge" class="w-4 h-4 text-rose-600 mx-auto mb-1"></i>
                            <div id="modal-sev-text" class="text-base font-extrabold text-rose-600">High</div>
                            <div class="text-[10px] text-slate-500 font-medium">Severity</div>
                        </div>
                        <div class="bg-slate-50 p-3 rounded-lg border border-slate-200 text-center">
                            <i data-lucide="grid" class="w-4 h-4 text-purple-600 mx-auto mb-1"></i>
                            <div id="modal-defects" class="text-base font-extrabold text-slate-900">2 detected</div>
                            <div class="text-[10px] text-slate-500 font-medium">Total Defects</div>
                        </div>
                    </div>

                    <!-- Physical Dimensions -->
                    <div class="grid grid-cols-4 gap-2 mt-2">
                        <div class="bg-slate-50 p-2 rounded-lg border border-slate-200 text-center">
                            <div class="text-[9px] text-slate-500 uppercase font-bold">Type</div>
                            <div id="modal-damage-type" class="text-xs font-bold text-slate-800 truncate mt-0.5">Pothole</div>
                        </div>
                        <div class="bg-slate-50 p-2 rounded-lg border border-slate-200 text-center">
                            <div class="text-[9px] text-slate-500 uppercase font-bold">Est. Depth</div>
                            <div id="modal-depth" class="text-xs font-bold text-amber-700 mt-0.5">-- cm</div>
                        </div>
                        <div class="bg-slate-50 p-2 rounded-lg border border-slate-200 text-center">
                            <div class="text-[9px] text-slate-500 uppercase font-bold">Crack Width</div>
                            <div id="modal-crack-width" class="text-xs font-bold text-sky-700 mt-0.5">-- mm</div>
                        </div>
                        <div class="bg-slate-50 p-2 rounded-lg border border-slate-200 text-center">
                            <div class="text-[9px] text-slate-500 uppercase font-bold">Damage Area</div>
                            <div id="modal-area" class="text-xs font-bold text-emerald-700 mt-0.5">-- m²</div>
                        </div>
                    </div>
                </div>

                <!-- Breakdown -->
                <div>
                    <div class="flex items-center justify-between mb-2">
                        <h4 class="text-xs font-bold text-slate-600 uppercase tracking-wider">Defect Breakdown</h4>
                        <span id="modal-hazard-count" class="text-[10px] font-bold px-2 py-0.5 rounded bg-slate-100 text-slate-700 border border-slate-200">2 Items</span>
                    </div>
                    <div id="modal-breakdown-list" class="space-y-1.5">
                        <!-- Populated via JS -->
                    </div>
                </div>

                <!-- Location & GPS -->
                <div class="bg-slate-50 p-3.5 rounded-xl border border-slate-200 space-y-1.5">
                    <h4 class="text-xs font-bold text-slate-600 uppercase tracking-wider">Geographic Coordinates</h4>
                    <div class="flex items-center justify-between">
                        <div class="flex items-center gap-2 text-xs font-semibold text-slate-800">
                            <i data-lucide="map-pin" class="w-4 h-4 text-sky-600"></i>
                            <span id="modal-gps">GPS Coordinates</span>
                        </div>
                        <a id="modal-gmaps-link" href="#" target="_blank" class="text-xs text-sky-600 hover:text-sky-700 font-semibold flex items-center gap-1">
                            <span>Open in Google Maps</span>
                            <i data-lucide="external-link" class="w-3 h-3"></i>
                        </a>
                    </div>
                    <p id="modal-road-name" class="text-xs text-slate-600">Road name</p>
                    <p id="modal-latlng-text" class="text-[11px] font-mono text-slate-400"></p>
                </div>

                <!-- Model Notes -->
                <div class="bg-slate-50 p-3 rounded-lg border border-slate-200">
                    <span class="text-[10px] uppercase font-bold text-slate-500 block mb-1">Model Inference Notes</span>
                    <p id="modal-inference" class="text-xs text-slate-600 font-mono"></p>
                </div>

            </div>

            <!-- Right: Authority Management & Workflow Panel -->
            <div class="lg:col-span-5 bg-slate-50 p-5 rounded-xl border border-slate-200 space-y-4">
                <div class="border-b border-slate-200 pb-3">
                    <h4 class="text-sm font-bold text-slate-900 flex items-center gap-2">
                        <i data-lucide="clipboard-check" class="w-4 h-4 text-sky-600"></i>
                        <span>Authority Action & Repair Workflow</span>
                    </h4>
                    <p class="text-xs text-slate-500">Update maintenance status, assign repair crews and log field notes</p>
                </div>

                <form id="authority-action-form" onsubmit="handleAuthorityFormSubmit(event)" class="space-y-3.5">
                    <input type="hidden" id="form-report-id" name="report_id" value="">

                    <!-- Status Selector -->
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1">Lifecycle Status</label>
                        <select id="form-status" name="status" class="w-full bg-white border border-slate-200 rounded-lg px-3 py-2 text-xs text-slate-800 focus:outline-none focus:border-sky-500">
                            <option value="reported">⏳ Pending Inspection</option>
                            <option value="verified">🔍 Field Verified</option>
                            <option value="assigned">👷 Crew Assigned</option>
                            <option value="under_repair">🛠️ Under Repair</option>
                            <option value="resolved">✅ Repaired & Resolved</option>
                        </select>
                    </div>

                    <!-- Assign Contractor / Crew -->
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1">Assigned Repair Crew / Team</label>
                        <input type="text" id="form-crew" name="assigned_crew" placeholder="e.g. Zone 2 Rapid Maintenance Team"
                                class="w-full bg-white border border-slate-200 rounded-lg px-3 py-2 text-xs text-slate-800 focus:outline-none focus:border-sky-500">
                    </div>

                    <!-- Scheduled Date -->
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1">Scheduled Repair Date</label>
                        <input type="date" id="form-scheduled-date" name="scheduled_repair_date"
                                class="w-full bg-white border border-slate-200 rounded-lg px-3 py-2 text-xs text-slate-800 focus:outline-none focus:border-sky-500">
                    </div>

                    <!-- Inspection & Maintenance Notes -->
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1">Authority Notes & Log</label>
                        <textarea id="form-notes" name="repair_notes" rows="3" placeholder="Enter inspection details, contractor estimates, or repair confirmation..."
                                  class="w-full bg-white border border-slate-200 rounded-lg p-2.5 text-xs text-slate-800 focus:outline-none focus:border-sky-500"></textarea>
                    </div>

                    <!-- Optional Completion Proof Photo -->
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1">Upload Repair Proof Photo (Optional)</label>
                        <input type="file" name="repair_image" accept="image/*"
                               class="w-full text-xs text-slate-500 file:mr-3 file:py-1.5 file:px-3 file:rounded-md file:border-0 file:text-xs file:font-semibold file:bg-slate-200 file:text-slate-700 hover:file:bg-slate-300 cursor-pointer">
                    </div>

                    <div class="pt-2 flex items-center justify-end gap-2 border-t border-slate-200">
                        <button type="button" onclick="closeInspectionModal()" class="px-3.5 py-1.5 rounded-lg text-xs font-semibold bg-white hover:bg-slate-100 text-slate-700 border border-slate-200 transition">
                            Cancel
                        </button>
                        <button type="submit" class="px-4 py-1.5 rounded-lg text-xs font-bold bg-slate-900 hover:bg-slate-800 text-white transition shadow-sm flex items-center gap-1.5">
                            <i data-lucide="save" class="w-3.5 h-3.5"></i>
                            <span>Save Action</span>
                        </button>
                    </div>
                </form>

            </div>

        </div>

    </div>
</div>

<!-- Load Application JS -->
<script src="assets/js/map.js?v=<?= time() ?>"></script>
<script src="assets/js/app.js?v=<?= time() ?>"></script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
