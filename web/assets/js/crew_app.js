/**
 * Construction Crew Web Dashboard Application Logic - SorokSurokkha
 * Powered by Supabase Cloud Database + Realtime Sync Engine + Local Authority Cache
 * Features:
 * - Direct Supabase Cloud Database Connection & Fallback
 * - Real-time Postgres changes synchronization (INSERT / UPDATE)
 * - Scope Toggle: Upazilla-Specific vs All Bangladesh Nationwide View
 * - Status Lifecycle Management (Verified -> Under Repair -> Repaired / Resolved)
 * - Clickable Live Map Navigation directly from Table Rows
 * - Peer Crew Collaboration in Same Upazilla
 */

const SUPABASE_CONFIG = {
    url: 'https://dytilqslhxmlhrwselam.supabase.co',
    key: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR5dGlscXNsaHhtbGhyd3NlbGFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5NDE5MDIsImV4cCI6MjEwODUxNzkwMn0.NHMeba85rqFXLO7UAnLqAT_j9J50Y-mwqRVpiVV59Uk'
};

let supabaseClient = null;
let allCrewReports = [];
let peerCrewsData = [];
let currentScope = 'upazilla'; // 'upazilla' (default) | 'national'
let currentAssignmentFilter = 'all'; // 'all' (default to show all hazards) | 'me'

document.addEventListener('DOMContentLoaded', () => {
    initCrewMap();
    initCrewSupabase();
    loadCrewData();
    loadPeerCrews();
    applyCrewLanguage(currentAppLang);
});

// Initialize Supabase Client & Realtime Subscription
function initCrewSupabase() {
    if (window.supabase) {
        try {
            if (!supabaseClient) {
                supabaseClient = window.supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.key);
            }
            supabaseClient
                .channel('public:crew_damage_reports')
                .on('postgres_changes', { event: '*', schema: 'public', table: 'damage_reports' }, (payload) => {
                    console.log('Realtime database event from mobile/authority sync:', payload);
                    if (payload.eventType === 'INSERT') {
                        showCrewToast(currentAppLang === 'bn' 
                            ? `📡 নতুন সড়ক ঝুঁকি আপলোড হয়েছে (${payload.new.damage_type || 'Pothole'})` 
                            : `📡 Live Mobile Upload: New ${payload.new.damage_type || 'pothole'} detected`);
                    } else if (payload.eventType === 'UPDATE') {
                        showCrewToast(currentAppLang === 'bn'
                            ? `📝 ত্রুটি #${payload.new.id} স্ট্যাটাস পরিবর্তন: ${payload.new.status}`
                            : `📝 Defect #${payload.new.id} updated to ${payload.new.status}`);
                    }
                    loadCrewData();
                })
                .subscribe((status) => {
                    console.log('Crew Supabase Realtime Channel Status:', status);
                });
        } catch (e) {
            console.warn('Supabase initialization warning:', e);
        }
    }
}

// Direct Fallback to Supabase Cloud Database REST / Client SDK
async function fetchSupabaseDirectly() {
    if (!window.supabase) return [];
    try {
        if (!supabaseClient) {
            supabaseClient = window.supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.key);
        }
        const { data, error } = await supabaseClient
            .from('damage_reports')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) {
            console.warn('Direct Supabase query error:', error);
            return [];
        }

        return (data || []).map(sr => {
            const lat = parseFloat(sr.latitude) || 22.8985;
            const lng = parseFloat(sr.longitude) || 89.5003;
            
            // Resolve upazilla if null
            let upz = sr.upazilla;
            let dist = sr.district;
            let div = sr.division;
            if (!upz) {
                if (lat > 23.5) {
                    upz = 'Gulshan'; dist = 'Dhaka'; div = 'Dhaka';
                } else {
                    upz = 'Khan Jahan Ali'; dist = 'Khulna'; div = 'Khulna';
                }
            }

            return {
                id: sr.id,
                title: sr.damage_type || 'Pothole Defect',
                severity: (sr.severity || 'HIGH').toUpperCase(),
                status: sr.status || 'detected',
                latitude: lat,
                longitude: lng,
                road_name: sr.address || `GPS (${lat.toFixed(5)}, ${lng.toFixed(5)})`,
                upazilla: upz,
                district: dist,
                division: div,
                confidence: parseFloat(sr.confidence_score) || 0.65,
                defects_count: Array.isArray(sr.detections) ? sr.detections.length : 1,
                image_url: sr.image_url || '',
                user_id: sr.user_id || 'mobile_user',
                user_name: sr.reported_by || 'Citizen User',
                device_model: 'Android YOLOv8 Mobile',
                reported_at: sr.created_at || new Date().toISOString(),
                assigned_crew: sr.assigned_crew || null,
                assigned_crew_id: sr.assigned_crew_id || null,
                repair_notes: sr.repair_notes || null
            };
        });
    } catch (err) {
        console.warn('Direct Supabase fetch exception:', err);
        return [];
    }
}

// Load Hazards Data (API first, then direct Supabase fallback)
async function loadCrewData() {
    try {
        let loaded = false;

        // 1. Fetch from local API endpoint
        try {
            const resp = await fetch('api/get_hazards.php');
            if (resp.ok) {
                const data = await resp.json();
                if (data.success && Array.isArray(data.data) && data.data.length > 0) {
                    allCrewReports = data.data;
                    loaded = true;
                }
            }
        } catch (apiErr) {
            console.warn('Local API fetch error, checking Supabase directly:', apiErr);
        }

        // 2. Direct Supabase Cloud Database Query Fallback
        if (!loaded || allCrewReports.length === 0) {
            const supaReports = await fetchSupabaseDirectly();
            if (supaReports.length > 0) {
                allCrewReports = supaReports;
                loaded = true;
            }
        }

        window.allCrewReports = allCrewReports;
        applyCrewFilters();
    } catch (e) {
        console.error('Failed to load crew hazards:', e);
    }
}

// Scope Switcher: My Upazilla vs All Bangladesh
function setCrewScope(scope) {
    currentScope = scope;
    const btnUpz = document.getElementById('btn-scope-upazilla');
    const btnNat = document.getElementById('btn-scope-national');

    if (scope === 'upazilla') {
        if (btnUpz) btnUpz.className = "px-3.5 py-2 rounded-lg text-xs sm:text-sm font-bold flex items-center gap-1.5 transition cursor-pointer bg-amber-500 text-white shadow-xs";
        if (btnNat) btnNat.className = "px-3.5 py-2 rounded-lg text-xs sm:text-sm font-bold flex items-center gap-1.5 transition cursor-pointer text-slate-600 hover:text-slate-900";
    } else {
        if (btnNat) btnNat.className = "px-3.5 py-2 rounded-lg text-xs sm:text-sm font-bold flex items-center gap-1.5 transition cursor-pointer bg-sky-600 text-white shadow-xs";
        if (btnUpz) btnUpz.className = "px-3.5 py-2 rounded-lg text-xs sm:text-sm font-bold flex items-center gap-1.5 transition cursor-pointer text-slate-600 hover:text-slate-900";
    }

    applyCrewFilters();
}

// Assignment Filter: All Hazards vs Assigned to Me
function setAssignmentFilter(filter) {
    currentAssignmentFilter = filter;
    const btnAll = document.getElementById('btn-filter-assigned-all');
    const btnMe = document.getElementById('btn-filter-assigned-me');

    if (filter === 'all') {
        if (btnAll) btnAll.className = "px-3 py-1.5 rounded-lg transition cursor-pointer bg-white text-slate-900 shadow-2xs font-bold";
        if (btnMe) btnMe.className = "px-3 py-1.5 rounded-lg transition cursor-pointer text-slate-500 hover:text-slate-800 font-bold";
    } else {
        if (btnMe) btnMe.className = "px-3 py-1.5 rounded-lg transition cursor-pointer bg-white text-slate-900 shadow-2xs font-bold";
        if (btnAll) btnAll.className = "px-3 py-1.5 rounded-lg transition cursor-pointer text-slate-500 hover:text-slate-800 font-bold";
    }

    applyCrewFilters();
}

// Filter and Render
function applyCrewFilters() {
    let list = [...allCrewReports];

    const targetUpz = (CREW_CONFIG.upazilla || '').trim().toLowerCase();
    
    // Flexible Upazilla Matching
    const upazillaOnly = allCrewReports.filter(r => {
        const rUpz = (r.upazilla || '').trim().toLowerCase();
        const rRoad = (r.road_name || '').toLowerCase();
        return rUpz === targetUpz || (targetUpz && rRoad.includes(targetUpz));
    });

    const upazillaCount = upazillaOnly.length;
    const nationalCount = allCrewReports.length;

    // Update Scope Count Badges on UI
    const upzBadge = document.getElementById('badge-scope-upazilla-count');
    const natBadge = document.getElementById('badge-scope-national-count');
    if (upzBadge) upzBadge.textContent = formatNumber(upazillaCount);
    if (natBadge) natBadge.textContent = formatNumber(nationalCount);

    // Dynamic Scope Notice Banner
    const noticeEl = document.getElementById('crew-scope-notice');

    // 1. Scope Filter: Upazilla vs All Bangladesh
    if (currentScope === 'upazilla') {
        if (upazillaCount > 0) {
            list = upazillaOnly;
            if (noticeEl) noticeEl.classList.add('hidden');
        } else {
            // Friendly fallback: If current upazilla has 0 records, show all nationwide records so table is NEVER blank!
            list = allCrewReports;
            if (noticeEl) {
                noticeEl.classList.remove('hidden');
                noticeEl.innerHTML = `
                    <i data-lucide="info" class="w-4 h-4 text-amber-600 shrink-0"></i>
                    <span>
                        ${currentAppLang === 'bn' 
                            ? `<strong>${CREW_CONFIG.upazilla}</strong> উপজেলায় বর্তমানে কোন ত্রুটি রেকর্ড নেই। সমগ্র বাংলাদেশের মোট <strong>${formatNumber(nationalCount)}</strong> টি রেকর্ড প্রদর্শিত হচ্ছে।` 
                            : `0 defects recorded specifically in <strong>${CREW_CONFIG.upazilla}</strong>. Showing all <strong>${nationalCount}</strong> nationwide road defect records.`}
                    </span>
                `;
            }
        }
    } else {
        list = allCrewReports;
        if (noticeEl) noticeEl.classList.add('hidden');
    }

    // Dynamic Filter Counts for buttons
    const myCount = list.filter(r => isReportAssignedToCurrentCrew(r)).length;
    const allCount = list.length;

    const btnAllText = document.getElementById('txt-filter-all');
    const btnMeText = document.getElementById('txt-filter-me');

    if (btnAllText) {
        btnAllText.textContent = currentAppLang === 'bn' 
            ? `🔍 সকল সড়ক ত্রুটি (${formatNumber(allCount)})` 
            : `🔍 All Road Defects (${allCount})`;
    }
    if (btnMeText) {
        btnMeText.textContent = currentAppLang === 'bn' 
            ? `📋 আমাকে অর্পিত (${formatNumber(myCount)})` 
            : `📋 Assigned to Me (${myCount})`;
    }

    // 2. Assignment Filter: Assigned to me vs All
    if (currentAssignmentFilter === 'me') {
        list = list.filter(r => isReportAssignedToCurrentCrew(r));
    }

    // 3. Search query
    const q = (document.getElementById('crew-search-input')?.value || '').trim().toLowerCase();
    if (q) {
        list = list.filter(r => 
            (r.id || '').toLowerCase().includes(q) ||
            (r.road_name || '').toLowerCase().includes(q) ||
            (r.assigned_crew || '').toLowerCase().includes(q) ||
            (r.upazilla || '').toLowerCase().includes(q) ||
            (r.severity || '').toLowerCase().includes(q)
        );
    }

    updateCrewKPIs(allCrewReports);
    renderCrewTable(list);
    updateCrewMapMarkers(list);

    // Update Subtitle Count (Without duplication)
    const countEl = document.getElementById('crew-records-count');
    if (countEl) {
        countEl.textContent = currentAppLang === 'bn' 
            ? `${formatNumber(list.length)} টি রেকর্ড` 
            : `${list.length} records`;
    }

    lucide.createIcons();
}

// Helper: Check if report is assigned to this crew
function isReportAssignedToCurrentCrew(r) {
    if (r.assigned_crew_id && r.assigned_crew_id === CREW_CONFIG.userId) return true;
    if (r.assigned_crew && r.assigned_crew.toLowerCase().includes((CREW_CONFIG.userName || '').toLowerCase())) return true;
    return false;
}

// Update KPI Cards
function updateCrewKPIs(all) {
    const targetUpz = (CREW_CONFIG.upazilla || '').trim().toLowerCase();
    let relevantReports = all.filter(r => (r.upazilla || '').trim().toLowerCase() === targetUpz);
    if (relevantReports.length === 0) relevantReports = all;

    // My Assigned: status assigned or under_repair
    const myAssigned = all.filter(r => isReportAssignedToCurrentCrew(r) && r.status !== 'resolved').length;
    // Under Repair in Active Scope
    const underRepair = relevantReports.filter(r => r.status === 'under_repair' || r.status === 'in_progress').length;
    // Resolved in Active Scope
    const resolved = relevantReports.filter(r => r.status === 'resolved' || r.status === 'verified').length;
    // Critical in Active Scope
    const critical = relevantReports.filter(r => (r.severity === 'CRITICAL' || r.severity === 'HIGH') && r.status !== 'resolved').length;

    const elAssigned = document.getElementById('kpi-my-assigned');
    const elRepair = document.getElementById('kpi-under-repair');
    const elComp = document.getElementById('kpi-completed');
    const elCrit = document.getElementById('kpi-critical');

    if (elAssigned) elAssigned.textContent = formatNumber(myAssigned);
    if (elRepair) elRepair.textContent = formatNumber(underRepair);
    if (elComp) elComp.textContent = formatNumber(resolved);
    if (elCrit) elCrit.textContent = formatNumber(critical);
}

// Render Table
function renderCrewTable(reports) {
    const tbody = document.getElementById('crew-table-body');
    if (!tbody) return;

    if (reports.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="7" class="py-12 text-center text-slate-500">
                    <div class="flex flex-col items-center justify-center gap-2">
                        <i data-lucide="inbox" class="w-8 h-8 text-slate-400"></i>
                        <span class="font-bold text-sm">${currentAppLang === 'bn' ? 'কোন কাজের রেকর্ড পাওয়া যায়নি' : 'No road defect records found in this view.'}</span>
                        <span class="text-xs text-slate-400">${currentAppLang === 'bn' ? 'উপরে "All Bangladesh" নির্বাচন করে সব রেকর্ড দেখুন' : 'Switch scope to "All Bangladesh" above to view nationwide defects.'}</span>
                    </div>
                </td>
            </tr>
        `;
        lucide.createIcons();
        return;
    }

    tbody.innerHTML = reports.map(r => {
        const lat = parseFloat(r.latitude).toFixed(5);
        const lng = parseFloat(r.longitude).toFixed(5);
        const upazillaText = typeof translateGeoName === 'function' ? translateGeoName(r.upazilla || 'Khan Jahan Ali') : (r.upazilla || 'Khan Jahan Ali');
        const districtText = typeof translateGeoName === 'function' ? translateGeoName(r.district || 'Khulna') : (r.district || 'Khulna');
        const isMine = isReportAssignedToCurrentCrew(r);

        // Severity Badge
        let sevClass = 'bg-amber-100 text-amber-800 border border-amber-200';
        if (r.severity === 'CRITICAL') sevClass = 'bg-rose-100 text-rose-800 border border-rose-300 font-extrabold';
        else if (r.severity === 'HIGH') sevClass = 'bg-rose-50 text-rose-700 border border-rose-200';
        else if (r.severity === 'LOW') sevClass = 'bg-sky-50 text-sky-700 border border-sky-200';

        const conf = Math.round((r.confidence || 0) * 100);

        // Current Lifecycle Status
        const st = (r.status || 'detected').toLowerCase();

        return `
            <tr class="hover:bg-slate-50/80 transition-colors ${isMine ? 'bg-amber-50/20' : ''}">
                <!-- Photo -->
                <td class="py-3 px-4">
                    <div class="relative w-14 h-14 rounded-xl overflow-hidden bg-slate-100 border border-slate-200">
                        <img src="${r.image_url || 'uploads/potholes/rpt-1792217799588.jpg'}" alt="${r.id}"
                             class="w-full h-full object-cover cursor-pointer hover:scale-105 transition"
                             onclick="openCrewRepairModal('${r.id}')"
                             onerror="this.src='uploads/potholes/rpt-1792217799588.jpg'">
                        <span class="absolute bottom-0 right-0 bg-slate-900/80 text-[9px] px-1 font-mono text-white rounded-tl">
                            ${r.defects_count || 1}x
                        </span>
                    </div>
                </td>

                <!-- ID & Date -->
                <td class="py-3 px-4">
                    <div class="font-bold text-slate-900 text-xs hover:text-amber-600 cursor-pointer" onclick="openCrewRepairModal('${r.id}')">
                        ${r.id}
                    </div>
                    <div class="text-[11px] text-slate-500 mt-0.5">
                        ${formatDate(r.reported_at)}
                    </div>
                    ${r.title ? `
                        <span class="inline-block mt-1 text-[10px] px-1.5 py-0.5 rounded bg-slate-100 text-slate-700 font-medium">
                            ${r.title}
                        </span>
                    ` : ''}
                </td>

                <!-- Location & Coordinates (Click-to-Fly directly on GIS Map) -->
                <td class="py-3 px-4">
                    <div class="flex items-center gap-1.5 mb-1">
                        <button type="button" onclick="flyToCrewReport('${r.id}')" 
                                title="${currentAppLang === 'bn' ? 'ম্যাপে সরাসরি এই অবস্থানটি দেখুন' : 'Click to locate on live map'}"
                                class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-bold bg-sky-50 hover:bg-sky-100 text-sky-700 border border-sky-200 transition cursor-pointer whitespace-nowrap shadow-2xs">
                            <i data-lucide="map-pin" class="w-3.5 h-3.5 text-sky-600"></i>
                            <span>${upazillaText}, ${districtText}</span>
                        </button>
                    </div>
                    <div class="text-xs font-semibold text-slate-800 truncate max-w-[210px]" title="${r.road_name || ''}">
                        ${r.road_name || (currentAppLang === 'bn' ? `${upazillaText} সড়ক সেগমেন্ট` : `${r.upazilla || 'Survey'} Route Segment`)}
                    </div>
                    <div class="text-[11px] text-slate-500 flex items-center gap-1.5 mt-0.5">
                        <button type="button" onclick="flyToCrewReport('${r.id}')" class="font-mono text-sky-700 hover:text-sky-900 font-medium cursor-pointer">
                            ${lat}, ${lng}
                        </button>
                    </div>
                </td>

                <!-- Severity & Confidence -->
                <td class="py-3 px-4">
                    <span class="inline-block px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase tracking-wider ${sevClass}">
                        ${r.severity || 'HIGH'}
                    </span>
                    <div class="text-[11px] text-slate-500 mt-1 font-medium">
                        ${conf}% ${currentAppLang === 'bn' ? 'নির্ভুলতা' : 'confidence'}
                    </div>
                </td>

                <!-- Assigned Crew -->
                <td class="py-3 px-4">
                    ${r.assigned_crew ? `
                        <div class="flex items-center gap-1.5">
                            <span class="w-6 h-6 rounded-full bg-amber-100 text-amber-800 text-[10px] font-bold flex items-center justify-center shrink-0 border border-amber-300">
                                👷
                            </span>
                            <div class="truncate max-w-[150px]">
                                <div class="text-xs font-bold text-slate-800 truncate" title="${r.assigned_crew}">
                                    ${r.assigned_crew.split('(')[0].trim()}
                                </div>
                                ${isMine ? `
                                    <span class="inline-block text-[9px] font-extrabold text-amber-700 bg-amber-50 px-1 rounded border border-amber-200">
                                        ${currentAppLang === 'bn' ? 'আমার দল' : 'My Team'}
                                    </span>
                                ` : ''}
                            </div>
                        </div>
                    ` : `
                        <span class="text-xs text-slate-400 italic">
                            ${currentAppLang === 'bn' ? 'অর্পণ করা হয়নি' : 'Unassigned'}
                        </span>
                    `}
                </td>

                <!-- Upload Repaired Photo Image -->
                <td class="py-3 px-4">
                    ${r.repair_image_url ? `
                        <div class="flex items-center gap-2">
                            <a href="${r.repair_image_url}" target="_blank" title="View Full Repair Photo" class="relative group block">
                                <img src="${r.repair_image_url}" alt="Repaired Photo" class="w-12 h-12 rounded-lg object-cover border-2 border-emerald-500 shadow-2xs group-hover:scale-105 transition" onerror="this.src='uploads/potholes/rpt-1792217799588.jpg'">
                                <div class="absolute -bottom-1 -right-1 bg-emerald-600 text-white rounded-full p-0.5 shadow-xs">
                                    <i data-lucide="check" class="w-2.5 h-2.5"></i>
                                </div>
                            </a>
                            <div class="flex flex-col">
                                <span class="text-[11px] font-bold text-emerald-700 flex items-center gap-0.5">
                                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 inline-block"></span>
                                    ${currentAppLang === 'bn' ? 'ছবি সম্পন্ন' : 'Uploaded'}
                                </span>
                                ${isMine ? `
                                    <label class="text-[10px] text-amber-600 hover:text-amber-700 underline font-semibold cursor-pointer mt-0.5">
                                        <span>${currentAppLang === 'bn' ? 'ছবি পরিবর্তন' : 'Replace Photo'}</span>
                                        <input type="file" accept="image/*" class="hidden" onchange="uploadCrewRepairPhoto('${r.id}', this)">
                                    </label>
                                ` : ''}
                            </div>
                        </div>
                    ` : `
                        ${isMine ? `
                            ${(st === 'under_repair' || st === 'in_progress' || st === 'resolved') ? `
                                <div>
                                    <label class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-dashed border-emerald-400 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 text-xs font-bold cursor-pointer transition shadow-2xs"
                                           title="${currentAppLang === 'bn' ? 'মেরামতের সমাপ্তির ছবি আপলোড করুন (স্ট্যাটাস Repaired হয়ে যাবে)' : 'Upload repaired photo (Status will be changed to Repaired)'}">
                                        <i data-lucide="camera" class="w-3.5 h-3.5 text-emerald-600"></i>
                                        <span>${currentAppLang === 'bn' ? 'ছবি আপলোড' : 'Upload Photo'}</span>
                                        <input type="file" accept="image/*" class="hidden" onchange="uploadCrewRepairPhoto('${r.id}', this)">
                                    </label>
                                </div>
                            ` : `
                                <div class="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-slate-100 border border-slate-200 text-slate-500 text-xs font-medium"
                                     title="${currentAppLang === 'bn' ? 'ছবি আপলোড করার পূর্বে স্ট্যাটাস \"মেরামত চলছে\" (Under Repair) হতে হবে' : 'Status must be changed to Under Repair before uploading repair photo'}">
                                    <i data-lucide="lock" class="w-3.5 h-3.5 text-slate-400"></i>
                                    <span>${currentAppLang === 'bn' ? 'আগে কাজ শুরু করুন' : 'Start Repair First'}</span>
                                </div>
                            `}
                        ` : `
                            <span class="text-xs text-slate-400 italic">
                                ${currentAppLang === 'bn' ? 'কোনো ছবি নেই' : 'No photo'}
                            </span>
                        `}
                    `}
                </td>

                <!-- Lifecycle Status (Editable ONLY if assigned to Current Crew; otherwise Read-Only) -->
                <td class="py-3 px-4">
                    ${isMine ? `
                        <div class="flex items-center gap-1.5">
                            <select onchange="updateCrewDefectStatus('${r.id}', this.value, this)"
                                    title="${currentAppLang === 'bn' ? 'কাজের অগ্রগতি অনুসারে স্ট্যাটাস পরিবর্তন করুন' : 'Change status as field repair progresses'}"
                                    class="text-xs font-bold px-2.5 py-1.5 rounded-xl border transition cursor-pointer shadow-2xs ${
                                        st === 'resolved' ? 'bg-emerald-50 text-emerald-800 border-emerald-300' :
                                        st === 'under_repair' || st === 'in_progress' ? 'bg-sky-50 text-sky-800 border-sky-300' :
                                        st === 'assigned' ? 'bg-amber-50 text-amber-800 border-amber-300' :
                                        'bg-slate-50 text-slate-700 border-slate-300'
                                    }">
                                <option value="assigned" ${st === 'assigned' ? 'selected' : ''}>👷 ${currentAppLang === 'bn' ? 'অর্পণকৃত' : 'Assigned'}</option>
                                <option value="under_repair" ${st === 'under_repair' || st === 'in_progress' ? 'selected' : ''}>🔧 ${currentAppLang === 'bn' ? "মেরামত চলছে" : 'Under Repair'}</option>
                                <option value="resolved" ${st === 'resolved' ? 'selected' : ''}>✅ ${currentAppLang === 'bn' ? "মেরামত সম্পন্ন" : 'Repaired / Resolved'}</option>
                            </select>
                        </div>
                    ` : `
                        <!-- Read-Only Badge for Other Crews & Unassigned Tasks -->
                        <div class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border text-xs font-bold select-none shadow-2xs ${
                            st === 'resolved' ? 'bg-emerald-50 text-emerald-700 border-emerald-200' :
                            st === 'under_repair' || st === 'in_progress' ? 'bg-sky-50 text-sky-700 border-sky-200' :
                            st === 'assigned' ? 'bg-amber-50 text-amber-800 border-amber-200' :
                            st === 'verified' ? 'bg-indigo-50 text-indigo-700 border-indigo-200' :
                            'bg-slate-50 text-slate-600 border-slate-200'
                        }" title="${r.assigned_crew ? (currentAppLang === 'bn' ? `অন্য মেরামত দলের (${r.assigned_crew.split('(')[0].trim()}) কাজ - কেবল দেখা যাবে` : `Assigned to ${r.assigned_crew.split('(')[0].trim()} (View Only)`) : (currentAppLang === 'bn' ? 'কর্তৃপক্ষের অনুমোদন প্রয়োজন' : 'Unassigned (Authority Action Required)')}">
                            <span>${
                                st === 'resolved' ? '✅' :
                                st === 'under_repair' || st === 'in_progress' ? '🔧' :
                                st === 'assigned' ? '👷' :
                                st === 'verified' ? '🔍' : '⏳'
                            }</span>
                            <span>${
                                st === 'resolved' ? (currentAppLang === 'bn' ? "মেরামত সম্পন্ন" : 'Resolved') :
                                st === 'under_repair' || st === 'in_progress' ? (currentAppLang === 'bn' ? "মেরামত চলছে" : 'Under Repair') :
                                st === 'assigned' ? (currentAppLang === 'bn' ? 'অর্পণকৃত' : 'Assigned') :
                                st === 'verified' ? (currentAppLang === 'bn' ? 'যাচাইকৃত' : 'Verified') :
                                (currentAppLang === 'bn' ? 'অপেক্ষমান' : 'Pending Review')
                            }</span>
                            <i data-lucide="lock" class="w-3 h-3 text-slate-400 ml-0.5"></i>
                        </div>
                    `}
                </td>

                <!-- Actions (Log icon removed, clean map locate button retained) -->
                <td class="py-3 px-4 text-right">
                    <div class="flex items-center justify-end">
                        <button type="button" onclick="flyToCrewReport('${r.id}')" 
                                title="${currentAppLang === 'bn' ? 'ম্যাপে সরাসরি অবস্থান দেখুন' : 'Locate on GIS Map'}"
                                class="p-2 rounded-xl bg-sky-50 hover:bg-sky-100 text-sky-700 border border-sky-200 transition cursor-pointer shadow-2xs">
                            <i data-lucide="map" class="w-4 h-4"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }).join('');

    lucide.createIcons();
}

// Interactive Status Update directly from Table Selector
async function updateCrewDefectStatus(reportId, newStatus, selectEl = null) {
    // MANDATORY REPAIR PHOTO ENFORCEMENT:
    // Without uploading repair photo, crew cannot change status to Repaired (resolved)
    const report = allCrewReports.find(r => r.id === reportId);
    if (newStatus === 'resolved' && (!report || !report.repair_image_url)) {
        const errorMsg = currentAppLang === 'bn' 
            ? '⚠️ মেরামতের ছবি আপলোড করা আবশ্যক!\n\nমেরামত সম্পন্ন (Repaired) করার পূর্বে অনুগ্রহ করে \'মেরামতের ছবি আপলোড\' কলাম থেকে কাজের সমাপ্তির ছবি আপলোড করুন।'
            : '⚠️ Repair Photo Required!\n\nPlease upload a Repaired Photo in the \'Upload Repaired Photo Image\' column before changing status to Repaired / Resolved.';
        alert(errorMsg);
        if (selectEl) {
            selectEl.value = (report && report.status) ? report.status : 'under_repair';
        }
        return;
    }

    try {
        const formData = new FormData();
        formData.append('report_id', reportId);
        formData.append('status', newStatus);
        formData.append('assigned_crew', `${CREW_CONFIG.userName} (${CREW_CONFIG.teamName || 'Road Repair Unit'})`);
        formData.append('assigned_crew_id', CREW_CONFIG.userId);

        const resp = await fetch('api/update_status.php', {
            method: 'POST',
            body: formData
        });
        const res = await resp.json();

        if (res.success) {
            // Also sync to Supabase Client directly for instant realtime broadcast
            if (supabaseClient) {
                let supaStatus = newStatus;
                if (newStatus === 'under_repair' || newStatus === 'assigned') supaStatus = 'in_progress';
                supabaseClient
                    .from('damage_reports')
                    .update({ status: supaStatus })
                    .eq('id', reportId)
                    .then(() => console.log('Direct Supabase cloud status updated'));
            }

            showCrewToast(currentAppLang === 'bn' 
                ? `সফলভাবে স্ট্যাটাস আপডেট হয়েছে: ${newStatus}` 
                : `Status updated successfully to ${newStatus}`);
            loadCrewData();
        } else {
            alert('Failed to update status: ' + (res.error || 'Unknown error'));
            if (selectEl && report && report.status) {
                selectEl.value = report.status;
            }
        }
    } catch (e) {
        console.error('Error updating status:', e);
        if (selectEl && report && report.status) {
            selectEl.value = report.status;
        }
    }
}

// Upload Repaired Photo Image directly from table column
// RULE: To upload the repaired photo, status must be Under Repair, and uploading changes status from Under Repair to Repaired (resolved)
async function uploadCrewRepairPhoto(reportId, inputEl) {
    if (!inputEl.files || !inputEl.files[0]) return;
    const file = inputEl.files[0];

    const report = allCrewReports.find(r => r.id === reportId);
    const currentStatus = (report && report.status) ? report.status.toLowerCase() : 'under_repair';

    if (currentStatus === 'assigned') {
        alert(currentAppLang === 'bn'
            ? '⚠️ মেরামতের ছবি আপলোড করতে প্রথমে স্ট্যাটাস "মেরামত চলছে" (Under Repair) হতে হবে。'
            : '⚠️ To upload the repaired photo, status must first be changed from Assigned to Under Repair.');
        inputEl.value = '';
        return;
    }

    const parent = inputEl.parentElement;
    const originalHtml = parent ? parent.innerHTML : '';
    if (parent) {
        parent.innerHTML = `<span class="inline-flex items-center gap-1.5 text-xs font-bold text-emerald-700"><i data-lucide="loader" class="w-3.5 h-3.5 animate-spin"></i> ${currentAppLang === 'bn' ? 'ছবি আপলোড ও মেরামত সম্পন্ন হচ্ছে...' : 'Uploading & Marking Repaired...'}</span>`;
        if (window.lucide) lucide.createIcons();
    }

    try {
        const formData = new FormData();
        formData.append('report_id', reportId);
        formData.append('repair_image', file);
        // CRITICAL: Uploading the repaired photo directly changes status from Under Repair to Repaired (resolved)!
        formData.append('status', 'resolved');
        formData.append('assigned_crew', `${CREW_CONFIG.userName} (${CREW_CONFIG.teamName || 'Road Repair Unit'})`);
        formData.append('assigned_crew_id', CREW_CONFIG.userId);

        const resp = await fetch('api/update_status.php', {
            method: 'POST',
            body: formData
        });
        const res = await resp.json();

        if (res.success) {
            // Also sync to Supabase Client directly for instant realtime broadcast
            if (supabaseClient) {
                supabaseClient
                    .from('damage_reports')
                    .update({ status: 'resolved' })
                    .eq('id', reportId)
                    .then(() => console.log('Direct Supabase cloud status updated to resolved'));
            }

            showCrewToast(currentAppLang === 'bn' 
                ? '✅ মেরামতের সমাপ্তির ছবি আপলোড হয়েছে এবং স্ট্যাটাস "মেরামত সম্পন্ন" (Repaired) করা হয়েছে!' 
                : '✅ Repair photo uploaded successfully! Status changed from Under Repair to Repaired.');
            await loadCrewData();
        } else {
            alert('Upload failed: ' + (res.error || 'Unknown error'));
            if (parent) parent.innerHTML = originalHtml;
            if (window.lucide) lucide.createIcons();
        }
    } catch (e) {
        console.error('Error uploading repair photo:', e);
        alert('Network error while uploading photo.');
        if (parent) parent.innerHTML = originalHtml;
        if (window.lucide) lucide.createIcons();
    }
}

// Open Repair Action Modal
function openCrewRepairModal(reportId, isReadOnly = false) {
    const report = allCrewReports.find(r => r.id === reportId);
    if (!report) return;

    const isMine = isReportAssignedToCurrentCrew(report);
    const readOnly = isReadOnly || !isMine;

    const repIdEl = document.getElementById('modal-report-id');
    if (repIdEl) repIdEl.value = report.id;

    const titleEl = document.getElementById('modal-defect-title') || document.getElementById('modal-repair-title');
    if (titleEl) titleEl.textContent = `${report.id} - ${report.road_name || 'Highway Segment'}`;

    const imgEl = document.getElementById('modal-defect-photo') || document.getElementById('modal-defect-img');
    if (imgEl) imgEl.src = report.image_url || 'uploads/potholes/rpt-1792217799588.jpg';

    const idEl = document.getElementById('modal-defect-id');
    if (idEl) idEl.textContent = report.id;

    const sevEl = document.getElementById('modal-defect-severity') || document.getElementById('modal-defect-sev');
    if (sevEl) sevEl.textContent = report.severity || 'HIGH';

    const roadEl = document.getElementById('modal-defect-road');
    if (roadEl) roadEl.textContent = report.road_name || 'Survey Coordinates';

    const coordsEl = document.getElementById('modal-defect-coords');
    if (coordsEl && report.latitude && report.longitude) {
        coordsEl.textContent = `${parseFloat(report.latitude).toFixed(5)}, ${parseFloat(report.longitude).toFixed(5)}`;
    }
    
    const statusSelect = document.getElementById('modal-status-select') || document.getElementById('modal-new-status');
    if (statusSelect) {
        statusSelect.value = report.status || 'detected';
        statusSelect.disabled = readOnly;
    }

    const notesInput = document.getElementById('modal-notes') || document.getElementById('modal-repair-notes');
    if (notesInput) {
        notesInput.value = report.repair_notes || '';
        notesInput.readOnly = readOnly;
    }

    const fileInput = document.getElementById('modal-repair-file');
    const submitBtn = document.getElementById('modal-btn-submit');
    const photoGroup = fileInput ? fileInput.closest('div') : null;

    if (readOnly) {
        if (photoGroup) photoGroup.classList.add('hidden');
        if (submitBtn) submitBtn.classList.add('hidden');
    } else {
        if (photoGroup) photoGroup.classList.remove('hidden');
        if (submitBtn) submitBtn.classList.remove('hidden');
    }

    const modal = document.getElementById('crew-repair-modal');
    if (modal) {
        modal.classList.remove('hidden');
        modal.classList.add('flex');
        lucide.createIcons();
    }
}

function closeCrewRepairModal() {
    const modal = document.getElementById('crew-repair-modal');
    if (modal) {
        modal.classList.remove('flex');
        modal.classList.add('hidden');
    }
}

// Submit Repair Modal Form
async function submitCrewRepair(e) {
    e.preventDefault();
    const reportId = document.getElementById('modal-report-id').value;
    const statusSelect = document.getElementById('modal-status-select') || document.getElementById('modal-new-status');
    const notesInput = document.getElementById('modal-notes') || document.getElementById('modal-repair-notes');
    const newStatus = statusSelect ? statusSelect.value : 'under_repair';
    const notes = notesInput ? notesInput.value : '';
    const fileInput = document.getElementById('modal-repair-file');

    // MANDATORY REPAIR PHOTO ENFORCEMENT:
    const repObj = allCrewReports.find(r => r.id === reportId);
    const hasExistingRepairImage = repObj && repObj.repair_image_url;
    const hasNewRepairImage = fileInput && fileInput.files && fileInput.files[0];
    if (newStatus === 'resolved' && !hasExistingRepairImage && !hasNewRepairImage) {
        alert(currentAppLang === 'bn' 
            ? '⚠️ মেরামতের ছবি আপলোড করা আবশ্যক! মেরামত সম্পন্ন (Repaired) করার পূর্বে অনুগ্রহ করে মেরামতের সমাপ্তির ছবি আপলোড করুন।' 
            : '⚠️ Repair Photo Required! Please upload a Repaired Photo before changing status to Repaired / Resolved.');
        return;
    }

    const formData = new FormData();
    formData.append('report_id', reportId);
    formData.append('status', newStatus);
    formData.append('repair_notes', notes);
    formData.append('assigned_crew', `${CREW_CONFIG.userName} (${CREW_CONFIG.teamName || 'Road Repair Unit'})`);
    formData.append('assigned_crew_id', CREW_CONFIG.userId);

    if (fileInput && fileInput.files[0]) {
        formData.append('repair_image', fileInput.files[0]);
    }

    try {
        const resp = await fetch('api/update_status.php', {
            method: 'POST',
            body: formData
        });
        const res = await resp.json();

        if (res.success) {
            closeCrewRepairModal();
            showCrewToast(currentAppLang === 'bn' ? 'মেরামতের তথ্য সংরক্ষিত হয়েছে' : 'Repair progress saved successfully');
            loadCrewData();
        } else {
            alert('Error: ' + (res.error || 'Could not save repair progress'));
        }
    } catch (err) {
        console.error('Submit error:', err);
    }
}

// Load Other Crews in My Upazilla & Nationwide Collaboration
async function loadPeerCrews() {
    try {
        const upz = CREW_CONFIG.upazilla || '';
        const resp = await fetch(`api/get_crews.php?upazilla=${encodeURIComponent(upz)}`);
        const res = await resp.json();
        if (res.success) {
            let list = res.data || res.crews || [];
            
            // If specific upazilla has 0 crews, load all registered highway crews so section is NEVER empty!
            if (list.length === 0) {
                const fallbackResp = await fetch('api/get_crews.php');
                const fallbackRes = await fallbackResp.json();
                if (fallbackRes.success) {
                    list = fallbackRes.data || fallbackRes.crews || [];
                }
            }

            peerCrewsData = list;
            renderPeerCrews(peerCrewsData);
        }
    } catch (e) {
        console.warn('Peer crews load error:', e);
    }
}

// Live Search Filter for Other Construction Crews
function filterPeerCrews() {
    const q = (document.getElementById('peer-crew-search')?.value || '').trim().toLowerCase();
    if (!q) {
        renderPeerCrews(peerCrewsData);
        return;
    }
    const filtered = peerCrewsData.filter(c => 
        (c.name || '').toLowerCase().includes(q) ||
        (c.team_name || '').toLowerCase().includes(q) ||
        (c.upazilla || '').toLowerCase().includes(q) ||
        (c.phone || '').toLowerCase().includes(q) ||
        (c.id || '').toLowerCase().includes(q)
    );
    renderPeerCrews(filtered);
}

function renderPeerCrews(crews) {
    const container = document.getElementById('peer-crews-list');
    if (!container) return;

    if (crews.length === 0) {
        container.innerHTML = `
            <div class="col-span-full py-6 text-center text-slate-400 text-xs">
                ${currentAppLang === 'bn' ? 'এই উপজেলায় অন্য কোন কর্মী নিবন্ধিত নেই।' : 'No other active crew units currently registered in this Upazilla.'}
            </div>
        `;
        return;
    }

    container.innerHTML = crews.map(c => {
        const isCurrent = c.id === CREW_CONFIG.userId;
        return `
            <div class="p-3.5 rounded-xl border ${isCurrent ? 'bg-amber-50/40 border-amber-300' : 'bg-slate-50 border-slate-200'} flex flex-col justify-between">
                <div>
                    <div class="flex items-center justify-between gap-2">
                        <span class="text-xs font-bold text-slate-900">${c.name}</span>
                        ${isCurrent ? `
                            <span class="text-[9px] font-extrabold uppercase px-1.5 py-0.5 rounded bg-amber-500 text-white">
                                ${currentAppLang === 'bn' ? 'আপনি' : 'You'}
                            </span>
                        ` : `
                            <span class="text-[10px] font-semibold text-emerald-600 flex items-center gap-1">
                                <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-ping"></span>
                                Active
                            </span>
                        `}
                    </div>
                    <div class="text-[11px] text-slate-500 mt-0.5">
                        ${c.team_name || 'Highway Maintenance Crew'} &bull; ${c.upazilla}
                    </div>

                    ${c.phone ? `
                        <div class="text-[11px] text-slate-600 mt-2 flex items-center gap-1.5">
                            <i data-lucide="phone" class="w-3 h-3 text-slate-400"></i>
                            <a href="tel:${c.phone}" class="hover:text-amber-700 font-mono">${c.phone}</a>
                        </div>
                    ` : ''}
                </div>

                <div class="mt-3 pt-2 border-t border-slate-200/60 flex items-center justify-between text-[11px]">
                    <span class="text-slate-400 font-mono text-[10px]">${c.id}</span>
                    ${c.active_report_ids ? `
                        <span class="text-sky-700 font-medium truncate max-w-[150px]" title="Assigned: ${c.active_report_ids}">
                            🔧 ${c.active_report_ids.split(',').length} ${currentAppLang === 'bn' ? 'টি মেরামত' : 'Defects'}
                        </span>
                    ` : `
                        <span class="text-slate-400 italic">${currentAppLang === 'bn' ? 'খালি' : 'Available'}</span>
                    `}
                </div>
            </div>
        `;
    }).join('');

    lucide.createIcons();
}

// Toast Notifications
function showCrewToast(msg) {
    const toast = document.createElement('div');
    toast.className = 'fixed bottom-5 right-5 z-50 bg-slate-900 text-white px-4 py-3 rounded-2xl shadow-2xl border border-amber-500/30 text-xs font-bold flex items-center gap-2 animate-bounce';
    toast.innerHTML = `
        <span class="w-2 h-2 rounded-full bg-amber-400"></span>
        <span>${msg}</span>
    `;
    document.body.appendChild(toast);
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transition = 'opacity 0.5s';
        setTimeout(() => toast.remove(), 500);
    }, 4000);
}

// Helpers
function formatNumber(num) {
    if (typeof formatNum === 'function') return formatNum(num);
    return num;
}

function formatDate(isoStr) {
    if (!isoStr) return 'Recent';
    try {
        const d = new Date(isoStr);
        return d.toLocaleDateString(currentAppLang === 'bn' ? 'bn-BD' : 'en-US', {
            month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
        });
    } catch (e) {
        return isoStr;
    }
}

// Logout
async function handleLogout() {
    if (!confirm(currentAppLang === 'bn' ? 'আপনি কি ড্যাশবোর্ড থেকে লগআউট করতে চান?' : 'Are you sure you want to sign out?')) return;
    try {
        await fetch('api/auth.php?action=logout');
        window.location.href = 'login.php';
    } catch (e) {
        window.location.href = 'login.php';
    }
}

// Global Callback for Language Switch (Called by setAppLanguage in i18n.js)
window.onLanguageChanged = function(lang) {
    applyCrewLanguage(lang);
};

// Bilingual Translation Engine for Construction Crew Dashboard
function applyCrewLanguage(lang) {
    currentAppLang = lang || (localStorage.getItem('sorok_lang') || 'en');

    // 1. Update Language Switcher Buttons appearance
    const btnBn = document.getElementById('lang-btn-bn');
    const btnEn = document.getElementById('lang-btn-en');
    if (currentAppLang === 'bn') {
        if (btnBn) btnBn.className = "px-3.5 py-2 rounded-lg bg-white text-amber-800 shadow-xs font-bold text-xs sm:text-sm";
        if (btnEn) btnEn.className = "px-3.5 py-2 rounded-lg text-slate-500 hover:text-slate-800 font-bold text-xs sm:text-sm cursor-pointer";
    } else {
        if (btnEn) btnEn.className = "px-3.5 py-2 rounded-lg bg-white text-sky-800 shadow-xs font-bold text-xs sm:text-sm";
        if (btnBn) btnBn.className = "px-3.5 py-2 rounded-lg text-slate-500 hover:text-slate-800 font-bold text-xs sm:text-sm cursor-pointer";
    }

    const isBn = (currentAppLang === 'bn');
    const upzName = typeof translateGeoName === 'function' ? translateGeoName(CREW_CONFIG.upazilla) : CREW_CONFIG.upazilla;
    const distName = typeof translateGeoName === 'function' ? translateGeoName(CREW_CONFIG.district) : CREW_CONFIG.district;

    // 2. Top Header Elements
    const elCrewTitle = document.getElementById('badge-crew-title');
    const elUpzHeader = document.getElementById('header-crew-upazilla');
    const elAuthNav = document.getElementById('nav-authority-link');
    const elLogout = document.getElementById('nav-logout-text');

    if (elCrewTitle) elCrewTitle.textContent = isBn ? 'নির্মাণ কর্মী দল' : 'Construction Crew';
    if (elUpzHeader) elUpzHeader.textContent = `${upzName}, ${distName}`;
    if (elAuthNav) elAuthNav.textContent = isBn ? 'কর্তৃপক্ষ ভিউ' : 'Authority View';
    if (elLogout) elLogout.textContent = isBn ? 'লগআউট' : 'Logout';

    // 3. Scope & Filter Bar Elements
    const elScopeLbl = document.getElementById('lbl-scope');
    const elMyUpzLbl = document.getElementById('txt-my-upazilla-lbl');
    const elScopeUpzName = document.getElementById('scope-upazilla-name');
    const elAllBdLbl = document.getElementById('txt-all-bd-lbl');
    const elJumpMap = document.getElementById('txt-jump-map');

    if (elScopeLbl) elScopeLbl.textContent = isBn ? 'রেকর্ড পরিসীমা:' : 'Record Scope:';
    if (elMyUpzLbl) elMyUpzLbl.textContent = isBn ? 'আমার উপজেলা:' : 'My Upazilla:';
    if (elScopeUpzName) elScopeUpzName.textContent = upzName;
    if (elAllBdLbl) elAllBdLbl.textContent = isBn ? 'সমগ্র বাংলাদেশ' : 'All Bangladesh';
    if (elJumpMap) elJumpMap.textContent = isBn ? 'লাইভ জিআইএস ম্যাপ' : 'GIS Live Map';

    // 4. KPI Cards
    const kpiAssignedTitle = document.getElementById('kpi-title-assigned');
    const kpiAssignedSub = document.getElementById('kpi-sub-assigned');
    const kpiRepairTitle = document.getElementById('kpi-title-in-repair');
    const kpiRepairSub = document.getElementById('kpi-sub-repair');
    const kpiCompTitle = document.getElementById('kpi-title-completed');
    const kpiCompSub = document.getElementById('kpi-sub-completed');
    const kpiCritTitle = document.getElementById('kpi-title-critical');
    const kpiCritSub = document.getElementById('kpi-sub-critical');

    if (kpiAssignedTitle) kpiAssignedTitle.textContent = isBn ? 'আমার অর্পিত কাজ' : 'My Assigned Tasks';
    if (kpiAssignedSub) kpiAssignedSub.textContent = isBn ? 'সক্রিয় কার্যআদেশ' : 'Active Work Orders';
    if (kpiRepairTitle) kpiRepairTitle.textContent = isBn ? "মেরামত চলছে" : 'Under Repair';
    if (kpiRepairSub) kpiRepairSub.textContent = isBn ? 'চলমান মেরামত কাজ' : 'Work In Progress';
    if (kpiCompTitle) kpiCompTitle.textContent = isBn ? "মেরামত সম্পন্ন" : 'Repaired & Resolved';
    if (kpiCompSub) kpiCompSub.textContent = isBn ? 'যানবাহন চলাচল স্বাভাবিক' : 'Traffic Restored';
    if (kpiCritTitle) kpiCritTitle.textContent = isBn ? 'সংকটাপন্ন ঝুঁকি' : 'Critical Severity';
    if (kpiCritSub) kpiCritSub.textContent = isBn ? 'জরুরি নিরাপত্তা সতর্কতা' : 'Urgent Safety Hazard';

    // 5. GIS Map Header & Controls
    const mapHeading = document.getElementById('map-heading-crew');
    const mapSub = document.getElementById('map-sub-crew');
    const crewTrackText = document.getElementById('crew-track-text');
    const crewLocateText = document.getElementById('crew-locate-text');
    const btnRecenter = document.getElementById('btn-recenter-crew');

    if (mapHeading) {
        mapHeading.innerHTML = isBn 
            ? `লাইভ জিআইএস সড়ক ঝুঁকি ম্যাপ &bull; <span class="text-amber-600 font-bold">${upzName} ফোকাস</span>`
            : `Live GIS Road Hazard Map &bull; <span class="text-amber-600 font-bold">${upzName} Focus</span>`;
    }
    if (mapSub) {
        mapSub.textContent = isBn 
            ? 'তীব্রতা অনুযায়ী রঙিন পিন। উচ্চ ঝুঁকির ত্রুটিতে পালসিং রাডার সতর্কতা।' 
            : 'Field location pins colored by severity. Pulsing radar on high-risk pavement defects.';
    }
    if (crewTrackText) {
        crewTrackText.textContent = isTrackingCrewLocation 
            ? (isBn ? 'লাইভ জিপিএস: সক্রিয়' : 'Live GPS: Active') 
            : (isBn ? 'লাইভ জিপিএস: বন্ধ' : 'Live GPS: OFF');
    }
    if (crewLocateText) crewLocateText.textContent = isBn ? 'আমার অবস্থান' : 'My Location';
    if (btnRecenter) btnRecenter.textContent = isBn ? 'উপজেলা কেন্দ্র' : 'Center Upazilla';

    // 6. Table Headers & Search
    const tableHeading = document.getElementById('table-heading-crew');
    const searchInput = document.getElementById('crew-search-input');
    const thPhoto = document.getElementById('th-photo');
    const thIdDate = document.getElementById('th-id-date');
    const thLocation = document.getElementById('th-location');
    const thSeverity = document.getElementById('th-severity');
    const thAssignedCrew = document.getElementById('th-assigned-crew');
    const thRepairPhoto = document.getElementById('th-repair-photo');
    const thStatus = document.getElementById('th-status');
    const thActions = document.getElementById('th-actions');

    if (thRepairPhoto) thRepairPhoto.textContent = isBn ? "মেরামতের ছবি আপলোড" : 'Upload Repaired Photo Image';

    if (tableHeading) tableHeading.textContent = isBn ? 'সড়ক মেরামত কার্যভার ও গর্তের রেকর্ড' : 'Road Repair Assignments & Pothole Records';
    if (searchInput) searchInput.placeholder = isBn ? 'আইডি, সড়ক, মেরামত দল দিয়ে খুঁজুন...' : 'Search by ID, Road, Crew...';
    if (thPhoto) thPhoto.textContent = isBn ? 'ছবি' : 'Photo';
    if (thIdDate) thIdDate.textContent = isBn ? 'ত্রুটির আইডি ও তারিখ' : 'Defect ID & Date';
    if (thLocation) thLocation.textContent = isBn ? 'অবস্থান ও স্থানাঙ্ক' : 'Location & Coordinates';
    if (thSeverity) thSeverity.textContent = isBn ? 'তীব্রতা ও নির্ভুলতা' : 'Severity & Conf';
    if (thAssignedCrew) thAssignedCrew.textContent = isBn ? 'দায়িত্বপ্রাপ্ত মেরামত দল' : 'Assigned Crew';
    if (thStatus) thStatus.textContent = isBn ? 'লাইফসাইকেল স্ট্যাটাস' : 'Lifecycle Status';
    if (thActions) thActions.textContent = isBn ? 'পদক্ষেপ' : 'Actions';

    // 7. Peer Crews Section
    const peerHeading = document.getElementById('other-crews-heading');
    const peerSub = document.getElementById('other-crews-sub');
    const peerSearch = document.getElementById('peer-crew-search');

    if (peerHeading) {
        peerHeading.innerHTML = isBn 
            ? `<span class="text-indigo-600 font-extrabold">${upzName}</span> উপজেলার অন্যান্য নির্মাণ দল`
            : `Other Construction Crews in <span class="text-indigo-600 font-extrabold">${upzName}</span>`;
    }
    if (peerSub) {
        peerSub.textContent = isBn 
            ? 'এই অঞ্চলে অন্যান্য সড়ক মেরামতে নিয়োজিত সহকর্মী ফিল্ড ইউনিটসমূহ।' 
            : 'Peer road maintenance units assigned to other pothole repairs in this jurisdiction.';
    }
    if (peerSearch) peerSearch.placeholder = isBn ? 'অন্যান্য মেরামত দল খুঁজুন...' : 'Search other crews...';

    // 8. Modal Elements
    const modalTitle = document.getElementById('modal-title-text');
    const modalSub = document.getElementById('modal-sub-text');
    const modalLblStatus = document.getElementById('modal-lbl-status');
    const modalLblNotes = document.getElementById('modal-lbl-notes');
    const modalLblPhoto = document.getElementById('modal-lbl-photo');
    const modalBtnCancel = document.getElementById('modal-btn-cancel');
    const modalBtnSave = document.getElementById('modal-btn-save-text');

    if (modalTitle) modalTitle.textContent = isBn ? 'সড়ক ত্রুটি মেরামতের অগ্রগতি লগ' : 'Road Defect Repair Progress Log';
    if (modalSub) modalSub.textContent = isBn ? 'কাজের অগ্রগতি স্ট্যাটাস আপডেট করুন ও ছবি দিন।' : 'Update lifecycle repair status & submit field completion proof.';
    if (modalLblStatus) modalLblStatus.textContent = isBn ? 'বর্তমান কাজের অগ্রগতি স্ট্যাটাস' : 'Current Lifecycle Status';
    if (modalLblNotes) modalLblNotes.textContent = isBn ? 'মাঠ পর্যায়ের কাজের অগ্রগতি নোট' : 'Field Work Progress Notes';
    if (modalLblPhoto) modalLblPhoto.textContent = isBn ? 'মেরামত সমাপ্তির ছবি আপলোড করুন' : 'Upload Repair Proof Photo';
    if (modalBtnCancel) modalBtnCancel.textContent = isBn ? 'বাতিল' : 'Cancel';
    if (modalBtnSave) modalBtnSave.textContent = isBn ? 'স্ট্যাটাস আপডেট সংরক্ষণ করুন' : 'Save Status Update';
    const statusSelect = document.getElementById('modal-status-select') || document.getElementById('modal-new-status');
    if (statusSelect && statusSelect.options.length >= 3) {
        statusSelect.options[0].text = isBn ? '🔍 যাচাইকৃত (কাজের অপেক্ষায়)' : '🔍 Verified';
        statusSelect.options[1].text = isBn ? '🔧 মেরামত কাজ চলমান' : '🔧 Under Repair';
        statusSelect.options[2].text = isBn ? '✅ মেরামত সম্পন্ন' : '✅ Repaired / Resolved';
    }

    // 9. Re-render dynamic components
    applyCrewFilters();
    if (peerCrewsData && peerCrewsData.length > 0) {
        renderPeerCrews(peerCrewsData);
    }
    if (typeof updateCrewNearestHazardDisplay === 'function') {
        updateCrewNearestHazardDisplay();
    }
}
