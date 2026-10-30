<?php
/**
 * SorokSurokkha - Road Hazard & Pothole Management Portal
 * Professional Civic & Municipal Light Design - Bilingual (English / বাংলা)
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
                <span class="text-[11px] font-bold uppercase tracking-wider" data-i18n="kpi_total_hazards">Total Hazards</span>
                <i data-lucide="layers" class="w-4 h-4 text-sky-600"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-total" class="text-2xl font-black text-slate-900 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-slate-400" data-i18n="kpi_detected">detected</span>
            </div>
        </div>

        <!-- High & Critical Severity -->
        <div class="bg-white border border-slate-200/90 rounded-xl p-4 flex flex-col justify-between shadow-2xs hover:shadow-xs transition">
            <div class="flex items-center justify-between mb-2">
                <span class="text-[11px] font-bold uppercase tracking-wider text-rose-600" data-i18n="kpi_critical_high">Critical / High</span>
                <i data-lucide="alert-triangle" class="w-4 h-4 text-rose-500"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-high" class="text-2xl font-black text-rose-600 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-rose-400" data-i18n="kpi_priority">priority</span>
            </div>
        </div>

        <!-- Pending Review -->
        <div class="bg-white border border-slate-200/90 rounded-xl p-4 flex flex-col justify-between shadow-2xs hover:shadow-xs transition">
            <div class="flex items-center justify-between mb-2">
                <span class="text-[11px] font-bold uppercase tracking-wider text-amber-600" data-i18n="kpi_pending_review">Pending Review</span>
                <i data-lucide="clock" class="w-4 h-4 text-amber-500"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-pending" class="text-2xl font-black text-amber-600 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-slate-400" data-i18n="kpi_unassigned">unassigned</span>
            </div>
        </div>

        <!-- Under Maintenance / In Progress -->
        <div class="bg-white border border-slate-200/90 rounded-xl p-4 flex flex-col justify-between shadow-2xs hover:shadow-xs transition">
            <div class="flex items-center justify-between mb-2">
                <span class="text-[11px] font-bold uppercase tracking-wider text-sky-600" data-i18n="kpi_in_progress">In Progress</span>
                <i data-lucide="wrench" class="w-4 h-4 text-sky-500"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-progress" class="text-2xl font-black text-sky-600 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-slate-400" data-i18n="kpi_crews_active">crews active</span>
            </div>
        </div>

        <!-- Resolved -->
        <div class="bg-white border border-slate-200/90 rounded-xl p-4 flex flex-col justify-between shadow-2xs hover:shadow-xs transition">
            <div class="flex items-center justify-between mb-2">
                <span class="text-[11px] font-bold uppercase tracking-wider text-emerald-600" data-i18n="kpi_resolved">Resolved</span>
                <i data-lucide="check-circle-2" class="w-4 h-4 text-emerald-500"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-resolved" class="text-2xl font-black text-emerald-600 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-slate-400" data-i18n="kpi_repaired">repaired</span>
            </div>
        </div>

        <!-- Contributing Citizens -->
        <div class="bg-white border border-slate-200/90 rounded-xl p-4 flex flex-col justify-between shadow-2xs hover:shadow-xs transition">
            <div class="flex items-center justify-between mb-2">
                <span class="text-[11px] font-bold uppercase tracking-wider text-purple-600" data-i18n="kpi_app_users">App Users</span>
                <i data-lucide="users" class="w-4 h-4 text-purple-500"></i>
            </div>
            <div class="flex items-baseline gap-2">
                <span id="stat-users" class="text-2xl font-black text-purple-600 tracking-tight">0</span>
                <span class="text-[11px] font-medium text-slate-400" data-i18n="kpi_citizens">citizens</span>
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
                    <span data-i18n="geo_section_title">Upazilla Pothole Density Ratio & Hotspot Analytics</span>
                </h2>
                <p class="text-xs text-slate-500" data-i18n="geo_section_sub">Live density percentages calculated based on pothole locations in database to guide authority repair prioritization</p>
            </div>

            <!-- Total Scope Info Pill -->
            <div class="flex items-center gap-3">
                <div class="bg-slate-50 border border-slate-200 rounded-lg px-3 py-1.5 flex items-center gap-2">
                    <i data-lucide="map-pin" class="w-4 h-4 text-rose-500"></i>
                    <div>
                        <div class="text-[10px] uppercase font-bold text-slate-400" data-i18n="geo_monitored_upazillas">Monitored Upazillas</div>
                        <div id="stat-geo-upazillas-count" class="text-sm font-black text-slate-900">0</div>
                    </div>
                </div>
                <div class="bg-slate-50 border border-slate-200 rounded-lg px-3 py-1.5 flex items-center gap-2">
                    <i data-lucide="alert-octagon" class="w-4 h-4 text-amber-500"></i>
                    <div>
                        <div class="text-[10px] uppercase font-bold text-slate-400" data-i18n="geo_total_hazards">Total Hazards Analyzed</div>
                        <div id="stat-geo-hazards-count" class="text-sm font-black text-slate-900">0</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Multi-tier Cascading Filter Bar: Division -> District -> Upazilla + Search -->
        <div class="bg-slate-50/80 border border-slate-200/90 rounded-xl p-3.5 space-y-3">
            <div class="text-xs font-bold text-slate-700 flex items-center gap-1.5">
                <i data-lucide="filter" class="w-3.5 h-3.5 text-sky-600"></i>
                <span data-i18n="geo_filter_title">Hierarchical Geographic Filter (Select Division &rarr; District &rarr; Upazilla):</span>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-2.5">
                <!-- 1. Division Selector -->
                <div>
                    <label class="block text-[11px] font-semibold text-slate-500 mb-1" data-i18n="geo_select_division">1. Select Division</label>
                    <select id="geo-division-select" onchange="onDivisionChange()" 
                            class="w-full bg-white border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-800 focus:outline-none focus:border-sky-500 transition cursor-pointer">
                        <option value="all" data-i18n="geo_all_divisions">All Divisions</option>
                    </select>
                </div>

                <!-- 2. District Selector -->
                <div>
                    <label class="block text-[11px] font-semibold text-slate-500 mb-1" data-i18n="geo_select_district">2. Select District</label>
                    <select id="geo-district-select" onchange="onDistrictChange()" 
                            class="w-full bg-white border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-800 focus:outline-none focus:border-sky-500 transition cursor-pointer">
                        <option value="all" data-i18n="geo_all_districts">All Districts</option>
                    </select>
                </div>

                <!-- 3. Upazilla Selector -->
                <div>
                    <label class="block text-[11px] font-semibold text-slate-500 mb-1" data-i18n="geo_select_upazilla">3. Select Upazilla</label>
                    <select id="geo-upazilla-select" onchange="onUpazillaChange()" 
                            class="w-full bg-white border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-800 focus:outline-none focus:border-sky-500 transition cursor-pointer">
                        <option value="all" data-i18n="geo_all_upazillas">All Upazillas</option>
                    </select>
                </div>

                <!-- 4. Quick Upazilla Search -->
                <div>
                    <label class="block text-[11px] font-semibold text-slate-500 mb-1" data-i18n="geo_search_label">Quick Upazilla Search</label>
                    <div class="relative">
                        <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-2.5 top-2"></i>
                        <input type="text" id="geo-upazilla-search" oninput="onUpazillaSearchInput()" placeholder="Type upazilla name..." data-i18n-placeholder="geo_search_placeholder" 
                               class="w-full bg-white border border-slate-200 rounded-lg pl-8 pr-2 py-1.5 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:border-sky-500 transition">
                    </div>
                </div>

                <!-- 5. Reset Action Button -->
                <div class="flex items-end">
                    <button type="button" onclick="resetGeoFilters()" 
                            class="w-full bg-slate-200 hover:bg-slate-300 text-slate-700 rounded-lg px-3 py-1.5 text-xs font-semibold transition flex items-center justify-center gap-1.5 shadow-2xs cursor-pointer">
                        <i data-lucide="rotate-ccw" class="w-3.5 h-3.5"></i>
                        <span data-i18n="geo_reset_filters">Reset Filters</span>
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
                    <button type="button" onclick="focusParticularOnMap()" class="px-3 py-1 bg-sky-600 hover:bg-sky-700 text-white rounded-lg text-xs font-bold transition flex items-center gap-1 shadow-xs cursor-pointer">
                        <i data-lucide="navigation" class="w-3 h-3"></i>
                        <span data-i18n="card_focus_map">Focus on Map</span>
                    </button>
                    <button type="button" onclick="filterTableToParticular()" class="px-3 py-1 bg-white hover:bg-slate-100 text-slate-700 rounded-lg text-xs font-semibold border border-slate-200 transition flex items-center gap-1 shadow-2xs cursor-pointer">
                        <i data-lucide="table" class="w-3 h-3"></i>
                        <span data-i18n="card_view_records">View Records</span>
                    </button>
                </div>
            </div>

            <!-- Particular Stats Grid -->
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
                <div class="bg-white/80 rounded-lg p-2.5 border border-sky-100">
                    <div class="text-[10px] uppercase font-bold text-slate-400" data-i18n="card_density_ratio">Pothole Density Ratio</div>
                    <div id="particular-density-ratio" class="text-xl font-black text-rose-600">62.5%</div>
                    <div class="text-[10px] text-slate-500" data-i18n="card_density_ratio_sub">of total recorded defects</div>
                </div>
                <div class="bg-white/80 rounded-lg p-2.5 border border-sky-100">
                    <div class="text-[10px] uppercase font-bold text-slate-400" data-i18n="card_total_in_upazilla">Total Hazards in Upazilla</div>
                    <div id="particular-total" class="text-xl font-black text-slate-900">10</div>
                    <div id="particular-severity-sub" class="text-[10px] text-rose-500 font-medium">4 Critical &bull; 5 High</div>
                </div>
                <div class="bg-white/80 rounded-lg p-2.5 border border-sky-100">
                    <div class="text-[10px] uppercase font-bold text-slate-400" data-i18n="card_repair_status">Repair Status</div>
                    <div id="particular-status" class="text-xl font-black text-amber-600">0 Pending</div>
                    <div id="particular-crew-sub" class="text-[10px] text-slate-500" data-i18n="card_inspection_queue">Inspection queue</div>
                </div>
                <div class="bg-white/80 rounded-lg p-2.5 border border-sky-100">
                    <div class="text-[10px] uppercase font-bold text-slate-400" data-i18n="card_authority_action">Authority Action</div>
                    <div id="particular-urgency" class="text-xs font-bold text-slate-800 mt-1">Routine Monitoring</div>
                    <div id="particular-action-sub" class="text-[10px] text-slate-500" data-i18n="card_action_guideline">Action guideline</div>
                </div>
            </div>

            <!-- Affected Roads in this Upazilla -->
            <div class="text-xs text-slate-600 bg-white/70 p-2.5 rounded-lg border border-sky-100 flex items-start gap-2">
                <i data-lucide="route" class="w-4 h-4 text-sky-600 shrink-0 mt-0.5"></i>
                <div>
                    <span class="font-bold text-slate-700" data-i18n="card_major_routes">Major Affected Routes in this Upazilla: </span>
                    <span id="particular-roads" class="text-slate-600">Teligati Road, Khulna-Jashore Highway, Fulbarigate Junction</span>
                </div>
            </div>
        </div>

        <!-- Upazilla Density Ranking Leaderboard (Descending Order) -->
        <div class="space-y-2">
            <div class="flex items-center justify-between text-xs font-bold text-slate-700">
                <span class="flex items-center gap-1.5">
                    <i data-lucide="trending-down" class="w-3.5 h-3.5 text-rose-600"></i>
                    <span id="geo-table-heading" data-i18n="table_density_heading">Upazilla Pothole Density Ratio (Ranked in Descending Order)</span>
                </span>
                <span class="text-[11px] text-slate-400 font-normal" data-i18n="table_density_sub">Click any row to inspect or focus GIS map</span>
            </div>

            <!-- Clean Table / List of Ranked Upazillas -->
            <div class="overflow-x-auto rounded-lg border border-slate-200">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-slate-50 text-slate-600 text-[11px] font-bold uppercase tracking-wider border-b border-slate-200">
                            <th class="py-2.5 px-3.5 w-12 text-center" data-i18n="th_rank">Rank</th>
                            <th class="py-2.5 px-3.5" data-i18n="th_upazilla">Upazilla</th>
                            <th class="py-2.5 px-3.5" data-i18n="th_district_div">District & Division</th>
                            <th class="py-2.5 px-3.5 text-center" data-i18n="th_potholes_count">Potholes Count</th>
                            <th class="py-2.5 px-3.5 w-64" data-i18n="th_density_ratio">Density Ratio (% of All Hazards)</th>
                            <th class="py-2.5 px-3.5 text-center" data-i18n="th_severity_profile">Severity Profile</th>
                            <th class="py-2.5 px-3.5" data-i18n="th_repair_urgency">Repair Urgency</th>
                            <th class="py-2.5 px-3.5 text-right" data-i18n="th_actions">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="upazilla-density-body" class="divide-y divide-slate-100 text-xs">
                        <tr>
                            <td colspan="8" class="text-center py-6 text-slate-400" data-i18n="table_loading_analytics">
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
                    <span data-i18n="map_title">Live GIS Road Hazard Map</span>
                </h2>
                <p class="text-xs text-slate-500" data-i18n="map_subtitle">Real-time GPS coordinates transmitted from mobile surveys and citizen reports</p>
            </div>

            <!-- Integrated Controls: Search + Refresh -->
            <div class="flex flex-wrap items-center gap-2">
                <div class="relative flex-1 sm:w-80">
                    <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3 top-2.5"></i>
                    <input type="text" id="osm-street-search" placeholder="Search street or city (e.g. Teligati Road, Mirpur Road)..." data-i18n-placeholder="map_search_placeholder" 
                           class="w-full bg-slate-50 border border-slate-200 rounded-lg pl-8 pr-20 py-1.5 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-sky-500 transition">
                    <button type="button" onclick="searchOsmStreet()" class="absolute right-1 top-1 px-2.5 py-1 rounded bg-slate-800 hover:bg-slate-700 text-[11px] font-semibold text-white transition cursor-pointer" data-i18n="map_find_btn">
                        Find
                    </button>
                </div>

                <button onclick="loadHazardsData()" class="px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-xs font-semibold text-slate-700 transition flex items-center gap-1.5 border border-slate-200 shadow-2xs cursor-pointer">
                    <i data-lucide="refresh-cw" class="w-3.5 h-3.5"></i>
                    <span data-i18n="map_refresh_btn">Refresh</span>
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
                <span class="font-bold text-slate-700" data-i18n="map_legend_title">Map Legend:</span>
                <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-sky-500"></span> <span data-i18n="legend_authority">Authority Position</span></span>
                <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-rose-500"></span> <span data-i18n="legend_critical">High / Critical Defect</span></span>
                <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-orange-500"></span> <span data-i18n="legend_medium">Medium Defect</span></span>
                <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-amber-400"></span> <span data-i18n="legend_low">Low Defect</span></span>
                <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-full bg-emerald-500"></span> <span data-i18n="legend_resolved">Repaired / Resolved</span></span>
            </div>
            <div class="text-[11px] text-slate-400" data-i18n="map_attribution">
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
                    <span data-i18n="records_title">Road Hazard & Pothole Records</span>
                </h2>
                <span id="filter-count" class="text-xs text-slate-500 font-medium" data-i18n="records_loading">Loading records...</span>
            </div>

            <!-- Filters Bar -->
            <div class="flex flex-wrap items-center gap-2">
                <!-- Search Input -->
                <div class="relative">
                    <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3 top-2.5"></i>
                    <input type="text" id="search-input" placeholder="Search by ID, User, Road..." data-i18n-placeholder="search_records_placeholder" 
                           class="bg-slate-50 border border-slate-200 rounded-lg pl-8 pr-3 py-1.5 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-sky-500 w-48 sm:w-56 transition">
                </div>

                <!-- Citizen / User Filter -->
                <select id="filter-user" class="bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-700 focus:outline-none focus:bg-white focus:border-sky-500 cursor-pointer">
                    <option value="all" data-i18n="filter_all_users">All Users</option>
                </select>

                <!-- Severity Filter -->
                <select id="filter-severity" class="bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-700 focus:outline-none focus:bg-white focus:border-sky-500 cursor-pointer">
                    <option value="all" data-i18n="filter_all_severities">All Severities</option>
                    <option value="CRITICAL" data-i18n="filter_critical">Critical</option>
                    <option value="HIGH" data-i18n="filter_high">High</option>
                    <option value="MEDIUM" data-i18n="filter_medium">Medium</option>
                    <option value="LOW" data-i18n="filter_low">Low</option>
                </select>

                <!-- Status Filter -->
                <select id="filter-status" class="bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-700 focus:outline-none focus:bg-white focus:border-sky-500 cursor-pointer">
                    <option value="all" data-i18n="filter_all_statuses">All Statuses</option>
                    <option value="reported" data-i18n="status_reported">Pending Review</option>
                    <option value="verified" data-i18n="status_verified">Verified</option>
                    <option value="assigned" data-i18n="status_assigned">Assigned</option>
                    <option value="under_repair" data-i18n="status_under_repair">Under Repair</option>
                    <option value="resolved" data-i18n="status_resolved">Resolved</option>
                </select>

                <!-- Export CSV Button -->
                <button onclick="exportToCSV()" class="px-3 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold transition flex items-center gap-1.5 border border-slate-200 shadow-2xs cursor-pointer">
                    <i data-lucide="download" class="w-3.5 h-3.5"></i>
                    <span data-i18n="btn_export_csv">Export CSV</span>
                </button>
            </div>
        </div>

        <!-- Clean Data Table -->
        <div class="overflow-x-auto rounded-lg border border-slate-200">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-50 text-slate-600 text-[11px] font-bold uppercase tracking-wider border-b border-slate-200">
                        <th class="py-3 px-4" data-i18n="th_photo">Photo</th>
                        <th class="py-3 px-4" data-i18n="th_id_date">Record ID & Date</th>
                        <th class="py-3 px-4" data-i18n="th_contributor">Contributor</th>
                        <th class="py-3 px-4" data-i18n="th_severity_conf">Severity & Confidence</th>
                        <th class="py-3 px-4" data-i18n="th_location">Location & Coordinates</th>
                        <th class="py-3 px-4" data-i18n="th_status">Lifecycle Status</th>
                        <th class="py-3 px-4 text-right" data-i18n="th_actions">Actions</th>
                    </tr>
                </thead>
                <tbody id="reports-table-body" class="divide-y divide-slate-100 text-xs">
                    <tr>
                        <td colspan="7" class="text-center py-10 text-slate-400" data-i18n="table_loading_records">
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
                <h3 id="modal-title" class="text-lg font-bold text-slate-900" data-i18n="modal_details_title">Pothole Defect Details</h3>
            </div>
            <div class="flex items-center gap-3">
                <span id="modal-severity-badge" class="px-2.5 py-0.5 rounded text-xs font-bold uppercase tracking-wider bg-rose-50 text-rose-700 border border-rose-200">
                    HIGH
                </span>
                <button onclick="closeInspectionModal()" class="w-8 h-8 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-500 hover:text-slate-800 flex items-center justify-center transition text-lg font-semibold cursor-pointer">
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
                        <span id="modal-photo-caption" data-i18n="modal_photo_caption">Field Mobile Photo & AI Detections</span>
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
                            <div class="text-[10px] text-slate-500 uppercase font-semibold" data-i18n="modal_submitted_by">Submitted by Citizen Scanner</div>
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
                    <h4 class="text-xs font-bold text-slate-600 uppercase tracking-wider mb-2" data-i18n="modal_ai_assessment">AI Defect Assessment</h4>
                    <div class="grid grid-cols-3 gap-2">
                        <div class="bg-slate-50 p-3 rounded-lg border border-slate-200 text-center">
                            <i data-lucide="check-circle" class="w-4 h-4 text-sky-600 mx-auto mb-1"></i>
                            <div id="modal-conf" class="text-base font-extrabold text-slate-900">66.0%</div>
                            <div class="text-[10px] text-slate-500 font-medium" data-i18n="modal_confidence">Confidence</div>
                        </div>
                        <div class="bg-slate-50 p-3 rounded-lg border border-slate-200 text-center">
                            <i data-lucide="gauge" class="w-4 h-4 text-rose-600 mx-auto mb-1"></i>
                            <div id="modal-sev-text" class="text-base font-extrabold text-rose-600">High</div>
                            <div class="text-[10px] text-slate-500 font-medium" data-i18n="modal_severity">Severity</div>
                        </div>
                        <div class="bg-slate-50 p-3 rounded-lg border border-slate-200 text-center">
                            <i data-lucide="grid" class="w-4 h-4 text-purple-600 mx-auto mb-1"></i>
                            <div id="modal-defects" class="text-base font-extrabold text-slate-900">2 detected</div>
                            <div class="text-[10px] text-slate-500 font-medium" data-i18n="modal_total_defects">Total Defects</div>
                        </div>
                    </div>

                    <!-- Physical Dimensions -->
                    <div class="grid grid-cols-4 gap-2 mt-2">
                        <div class="bg-slate-50 p-2 rounded-lg border border-slate-200 text-center">
                            <div class="text-[9px] text-slate-500 uppercase font-bold" data-i18n="modal_dim_type">Type</div>
                            <div id="modal-damage-type" class="text-xs font-bold text-slate-800 truncate mt-0.5">Pothole</div>
                        </div>
                        <div class="bg-slate-50 p-2 rounded-lg border border-slate-200 text-center">
                            <div class="text-[9px] text-slate-500 uppercase font-bold" data-i18n="modal_dim_depth">Est. Depth</div>
                            <div id="modal-depth" class="text-xs font-bold text-amber-700 mt-0.5">-- cm</div>
                        </div>
                        <div class="bg-slate-50 p-2 rounded-lg border border-slate-200 text-center">
                            <div class="text-[9px] text-slate-500 uppercase font-bold" data-i18n="modal_dim_crack_width">Crack Width</div>
                            <div id="modal-crack-width" class="text-xs font-bold text-sky-700 mt-0.5">-- mm</div>
                        </div>
                        <div class="bg-slate-50 p-2 rounded-lg border border-slate-200 text-center">
                            <div class="text-[9px] text-slate-500 uppercase font-bold" data-i18n="modal_dim_area">Damage Area</div>
                            <div id="modal-area" class="text-xs font-bold text-emerald-700 mt-0.5">-- m²</div>
                        </div>
                    </div>
                </div>

                <!-- Breakdown -->
                <div>
                    <div class="flex items-center justify-between mb-2">
                        <h4 class="text-xs font-bold text-slate-600 uppercase tracking-wider" data-i18n="modal_defect_breakdown">Defect Breakdown</h4>
                        <span id="modal-hazard-count" class="text-[10px] font-bold px-2 py-0.5 rounded bg-slate-100 text-slate-700 border border-slate-200">2 Items</span>
                    </div>
                    <div id="modal-breakdown-list" class="space-y-1.5">
                        <!-- Populated via JS -->
                    </div>
                </div>

                <!-- Location & GPS -->
                <div class="bg-slate-50 p-3.5 rounded-xl border border-slate-200 space-y-1.5">
                    <h4 class="text-xs font-bold text-slate-600 uppercase tracking-wider" data-i18n="modal_geo_coords">Geographic Coordinates</h4>
                    <div class="flex items-center justify-between">
                        <div class="flex items-center gap-2 text-xs font-semibold text-slate-800">
                            <i data-lucide="map-pin" class="w-4 h-4 text-sky-600"></i>
                            <span id="modal-gps">GPS Coordinates</span>
                        </div>
                        <a id="modal-gmaps-link" href="#" target="_blank" class="text-xs text-sky-600 hover:text-sky-700 font-semibold flex items-center gap-1">
                            <span data-i18n="modal_open_gmaps">Open in Google Maps</span>
                            <i data-lucide="external-link" class="w-3 h-3"></i>
                        </a>
                    </div>
                    <p id="modal-road-name" class="text-xs text-slate-600">Road name</p>
                    <p id="modal-latlng-text" class="text-[11px] font-mono text-slate-400"></p>
                </div>

                <!-- Model Notes -->
                <div class="bg-slate-50 p-3 rounded-lg border border-slate-200">
                    <span class="text-[10px] uppercase font-bold text-slate-500 block mb-1" data-i18n="modal_model_notes">Model Inference Notes</span>
                    <p id="modal-inference" class="text-xs text-slate-600 font-mono"></p>
                </div>

            </div>

            <!-- Right: Authority Management & Workflow Panel -->
            <div class="lg:col-span-5 bg-slate-50 p-5 rounded-xl border border-slate-200 space-y-4">
                <div class="border-b border-slate-200 pb-3">
                    <h4 class="text-sm font-bold text-slate-900 flex items-center gap-2">
                        <i data-lucide="clipboard-check" class="w-4 h-4 text-sky-600"></i>
                        <span data-i18n="modal_authority_workflow">Authority Action & Repair Workflow</span>
                    </h4>
                    <p class="text-xs text-slate-500" data-i18n="modal_workflow_sub">Update maintenance status, assign repair crews and log field notes</p>
                </div>

                <form id="authority-action-form" onsubmit="handleAuthorityFormSubmit(event)" class="space-y-3.5">
                    <input type="hidden" id="form-report-id" name="report_id" value="">

                    <!-- Status Selector -->
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1" data-i18n="modal_form_status">Lifecycle Status</label>
                        <select id="form-status" name="status" class="w-full bg-white border border-slate-200 rounded-lg px-3 py-2 text-xs text-slate-800 focus:outline-none focus:border-sky-500 cursor-pointer">
                            <option value="reported" data-i18n="modal_opt_reported">⏳ Pending Inspection</option>
                            <option value="verified" data-i18n="modal_opt_verified">🔍 Field Verified</option>
                            <option value="assigned" data-i18n="modal_opt_assigned">👷 Crew Assigned</option>
                            <option value="under_repair" data-i18n="modal_opt_under_repair">🛠️ Under Repair</option>
                            <option value="resolved" data-i18n="modal_opt_resolved">✅ Repaired & Resolved</option>
                        </select>
                    </div>

                    <!-- Assign Contractor / Crew -->
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1" data-i18n="modal_form_crew">Assigned Repair Crew / Team</label>
                        <input type="text" id="form-crew" name="assigned_crew" placeholder="e.g. Zone 2 Rapid Maintenance Team" data-i18n-placeholder="modal_form_crew_ph"
                                class="w-full bg-white border border-slate-200 rounded-lg px-3 py-2 text-xs text-slate-800 focus:outline-none focus:border-sky-500">
                    </div>

                    <!-- Scheduled Date -->
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1" data-i18n="modal_form_date">Scheduled Repair Date</label>
                        <input type="date" id="form-scheduled-date" name="scheduled_repair_date"
                                class="w-full bg-white border border-slate-200 rounded-lg px-3 py-2 text-xs text-slate-800 focus:outline-none focus:border-sky-500">
                    </div>

                    <!-- Inspection & Maintenance Notes -->
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1" data-i18n="modal_form_notes">Authority Notes & Log</label>
                        <textarea id="form-notes" name="repair_notes" rows="3" placeholder="Enter inspection details, contractor estimates, or repair confirmation..." data-i18n-placeholder="modal_form_notes_ph"
                                  class="w-full bg-white border border-slate-200 rounded-lg p-2.5 text-xs text-slate-800 focus:outline-none focus:border-sky-500"></textarea>
                    </div>

                    <!-- Optional Completion Proof Photo -->
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1" data-i18n="modal_form_proof">Upload Repair Proof Photo (Optional)</label>
                        <input type="file" name="repair_image" accept="image/*"
                               class="w-full text-xs text-slate-500 file:mr-3 file:py-1.5 file:px-3 file:rounded-md file:border-0 file:text-xs file:font-semibold file:bg-slate-200 file:text-slate-700 hover:file:bg-slate-300 cursor-pointer">
                    </div>

                    <div class="pt-2 flex items-center justify-end gap-2 border-t border-slate-200">
                        <button type="button" onclick="closeInspectionModal()" class="px-3.5 py-1.5 rounded-lg text-xs font-semibold bg-white hover:bg-slate-100 text-slate-700 border border-slate-200 transition cursor-pointer" data-i18n="modal_btn_cancel">
                            Cancel
                        </button>
                        <button type="submit" class="px-4 py-1.5 rounded-lg text-xs font-bold bg-slate-900 hover:bg-slate-800 text-white transition shadow-sm flex items-center gap-1.5 cursor-pointer">
                            <i data-lucide="save" class="w-3.5 h-3.5"></i>
                            <span data-i18n="modal_btn_save">Save Action</span>
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
