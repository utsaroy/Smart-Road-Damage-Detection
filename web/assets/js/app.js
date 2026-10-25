/**
 * Road Hazard Authority Portal Application Logic - Multi-User System
 */

let allReports = [];
let currentFilter = {
    status: 'all',
    severity: 'all',
    user: 'all',
    search: ''
};

document.addEventListener('DOMContentLoaded', () => {
    initHazardMap();
    loadHazardsData();
    initSupabaseRealtime();

    // Search input listener
    const searchInput = document.getElementById('search-input');
    if (searchInput) {
        searchInput.addEventListener('input', (e) => {
            currentFilter.search = e.target.value.trim().toLowerCase();
            applyFilters();
        });
    }

    // Citizen / User Filter selector
    const userFilter = document.getElementById('filter-user');
    if (userFilter) {
        userFilter.addEventListener('change', (e) => {
            currentFilter.user = e.target.value;
            applyFilters();
        });
    }

    // Status filter
    const statusFilter = document.getElementById('filter-status');
    if (statusFilter) {
        statusFilter.addEventListener('change', (e) => {
            currentFilter.status = e.target.value;
            applyFilters();
        });
    }

    // Severity filter
    const severityFilter = document.getElementById('filter-severity');
    if (severityFilter) {
        severityFilter.addEventListener('change', (e) => {
            currentFilter.severity = e.target.value;
            applyFilters();
        });
    }
});

// Fetch reports from API
async function loadHazardsData() {
    try {
        const resp = await fetch('api/get_hazards.php');
        const data = await resp.json();

        if (data.success) {
            allReports = data.data;
            updateStatsUI(data.stats);
            populateUserFilter(allReports);
            applyFilters();
        } else {
            console.error('Failed to load hazards:', data.error);
        }
    } catch (err) {
        console.error('Error fetching hazards:', err);
    }
}

// Populate the Citizen / User Filter Dropdown dynamically
function populateUserFilter(reports) {
    const userSelect = document.getElementById('filter-user');
    if (!userSelect) return;

    const usersMap = {};
    reports.forEach(r => {
        const uid = r.user_id || 'anonymous';
        const uname = r.user_name || uid;
        if (!usersMap[uid]) {
            usersMap[uid] = { name: uname, count: 0 };
        }
        usersMap[uid].count++;
    });

    const currentSelection = userSelect.value;
    userSelect.innerHTML = `<option value="all">All Citizens / Users (${Object.keys(usersMap).length} contributors)</option>`;
    
    for (const [uid, u] of Object.entries(usersMap)) {
        const opt = document.createElement('option');
        opt.value = uid;
        opt.textContent = `${u.name} (${u.count})`;
        if (uid === currentSelection) opt.selected = true;
        userSelect.appendChild(opt);
    }
}

// Update Top KPI Cards
function updateStatsUI(stats) {
    if (!stats) return;
    document.getElementById('stat-total').textContent = stats.total ?? 0;
    document.getElementById('stat-high').textContent = stats.high_severity ?? 0;
    document.getElementById('stat-pending').textContent = stats.pending ?? 0;
    document.getElementById('stat-progress').textContent = stats.in_progress ?? 0;
    document.getElementById('stat-resolved').textContent = stats.resolved ?? 0;
    
    const usersEl = document.getElementById('stat-users');
    if (usersEl) {
        usersEl.textContent = stats.total_users ?? 1;
    }
}

// Filter and render
function applyFilters() {
    const filtered = allReports.filter(r => {
        // User filter
        if (currentFilter.user !== 'all' && (r.user_id || 'anonymous') !== currentFilter.user) {
            return false;
        }
        // Status filter
        if (currentFilter.status !== 'all' && r.status !== currentFilter.status) {
            return false;
        }
        // Severity filter
        if (currentFilter.severity !== 'all' && r.severity.toUpperCase() !== currentFilter.severity.toUpperCase()) {
            return false;
        }
        // Search filter
        if (currentFilter.search) {
            const s = currentFilter.search;
            const matchId = (r.id || '').toLowerCase().includes(s);
            const matchTitle = (r.title || '').toLowerCase().includes(s);
            const matchRoad = (r.road_name || '').toLowerCase().includes(s);
            const matchDist = (r.district || '').toLowerCase().includes(s);
            const matchUser = (r.user_name || '').toLowerCase().includes(s) || 
                              (r.user_id || '').toLowerCase().includes(s) ||
                              (r.device_model || '').toLowerCase().includes(s);
            if (!matchId && !matchTitle && !matchRoad && !matchDist && !matchUser) {
                return false;
            }
        }
        return true;
    });

    renderTable(filtered);
    updateMapMarkers(filtered);
    document.getElementById('filter-count').textContent = `${filtered.length} of ${allReports.length} records`;
}

// Render data table with Multi-User Scanner Column
function renderTable(reports) {
    const tbody = document.getElementById('reports-table-body');
    if (!tbody) return;

    if (reports.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="7" class="text-center py-12 text-slate-500">
                    <div class="flex flex-col items-center justify-center gap-2">
                        <i data-lucide="inbox" class="w-8 h-8 text-slate-600"></i>
                        <span>No road hazard records found matching current criteria.</span>
                    </div>
                </td>
            </tr>
        `;
        lucide.createIcons();
        return;
    }

    tbody.innerHTML = reports.map(r => {
        const sevClass = getSeverityBadgeClass(r.severity);
        const lat = parseFloat(r.latitude).toFixed(5);
        const lng = parseFloat(r.longitude).toFixed(5);
        const uName = r.user_name || 'Citizen Contributor';
        const uId = r.user_id || 'anonymous';
        const uDevice = r.device_model || 'Android Phone';
        const avatarBg = getUserAvatarBg(uName);
        const initials = getUserInitials(uName);

        return `
            <tr class="hover:bg-slate-50 transition border-b border-slate-100 group">
                <!-- Thumbnail -->
                <td class="py-3 px-4">
                    <div class="w-14 h-14 rounded-lg bg-slate-100 overflow-hidden relative border border-slate-200 cursor-pointer" onclick="openInspectionModal('${r.id}')">
                        <img src="${r.image_url || 'uploads/potholes/rpt-1792217799588.jpg'}" 
                             alt="${r.id}" 
                             class="w-full h-full object-cover group-hover:scale-105 transition duration-200"
                             onerror="this.src='uploads/potholes/rpt-1792217799588.jpg'">
                        <span class="absolute bottom-0 right-0 bg-slate-900/80 text-[9px] px-1 font-mono text-white rounded-tl">
                            ${r.defects_count}x
                        </span>
                    </div>
                </td>

                <!-- ID & Timestamp -->
                <td class="py-3 px-4">
                    <div class="font-bold text-slate-900 text-xs hover:text-sky-700 cursor-pointer flex items-center gap-1.5" onclick="openInspectionModal('${r.id}')">
                        <span>${r.id}</span>
                    </div>
                    <div class="text-[11px] text-slate-500 mt-0.5">
                        ${formatDate(r.reported_at)}
                    </div>
                    <span class="inline-block mt-1 text-[10px] px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 font-mono border border-slate-200">
                        ${r.model_name || 'best.tflite'}
                    </span>
                </td>

                <!-- Citizen / User Scanner (Multi-User Visibility) -->
                <td class="py-3 px-4">
                    <div class="flex items-center gap-2.5">
                        <div class="w-8 h-8 rounded-full ${avatarBg} flex items-center justify-center text-[10px] font-black text-white shrink-0 shadow-2xs">
                            ${initials}
                        </div>
                        <div class="min-w-0">
                            <div class="font-bold text-slate-900 text-xs truncate max-w-[150px]" title="${uName}">
                                ${uName}
                            </div>
                            <div class="text-[10px] text-sky-700 font-mono flex items-center gap-1">
                                <span>${uId}</span>
                            </div>
                            <div class="text-[10px] text-slate-400 truncate max-w-[150px] flex items-center gap-1 mt-0.5" title="${uDevice}">
                                <i data-lucide="smartphone" class="w-3 h-3 inline"></i>
                                <span>${uDevice}</span>
                            </div>
                        </div>
                    </div>
                </td>

                <!-- Severity & Confidence -->
                <td class="py-3 px-4">
                    <span class="inline-block px-2.5 py-0.5 rounded text-xs font-bold uppercase tracking-wider ${sevClass}">
                        ${r.severity}
                    </span>
                    <div class="text-xs text-slate-600 mt-1 flex items-center gap-1">
                        <span class="font-bold text-slate-900">${r.confidence_pct || Math.round(r.confidence * 100)}%</span>
                        <span class="text-slate-400">conf.</span>
                    </div>
                </td>

                <!-- Location & GPS -->
                <td class="py-3 px-4">
                    <div class="text-xs font-medium text-slate-800 truncate max-w-[200px]" title="${r.road_name || ''}">
                        ${r.road_name || 'Survey Route Segment'}
                    </div>
                    <div class="text-[11px] text-slate-500 flex items-center gap-2 mt-1">
                        <span class="font-mono text-sky-700 font-medium">${lat}, ${lng}</span>
                        <button onclick="flyToReport('${r.id}')" title="Locate on GIS Map" class="text-sky-600 hover:text-sky-800 transition">
                            <i data-lucide="map-pin" class="w-3.5 h-3.5 inline"></i>
                        </button>
                    </div>
                </td>

                <!-- Status Selector -->
                <td class="py-3 px-4">
                    <select onchange="updateReportStatus('${r.id}', this.value)" class="bg-slate-50 border border-slate-200 rounded-lg text-xs font-medium px-2.5 py-1.5 text-slate-800 focus:outline-none focus:bg-white focus:border-sky-500 cursor-pointer">
                        <option value="reported" ${r.status === 'reported' ? 'selected' : ''}>⏳ Pending Review</option>
                        <option value="verified" ${r.status === 'verified' ? 'selected' : ''}>🔍 Verified</option>
                        <option value="assigned" ${r.status === 'assigned' ? 'selected' : ''}>👷 Assigned</option>
                        <option value="under_repair" ${r.status === 'under_repair' ? 'selected' : ''}>🛠️ Under Repair</option>
                        <option value="resolved" ${r.status === 'resolved' ? 'selected' : ''}>✅ Resolved</option>
                    </select>
                    ${r.assigned_crew ? `<div class="text-[10px] text-slate-500 mt-1 truncate max-w-[150px]">Crew: ${r.assigned_crew}</div>` : ''}
                </td>

                <!-- Actions -->
                <td class="py-3 px-4 text-right">
                    <div class="flex items-center justify-end gap-1.5">
                        <button onclick="openInspectionModal('${r.id}')" class="px-2.5 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold transition flex items-center gap-1 border border-slate-200">
                            <i data-lucide="eye" class="w-3.5 h-3.5 text-slate-500"></i>
                            <span>Inspect</span>
                        </button>
                        <button onclick="deleteReport('${r.id}')" class="p-1.5 bg-rose-50 hover:bg-rose-100 text-rose-600 rounded-lg text-xs transition border border-rose-200" title="Delete record">
                            <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }).join('');

    lucide.createIcons();
}

// User Initials & Distinct Colors
function getUserInitials(name) {
    if (!name) return 'U';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
}

function getUserAvatarBg(name) {
    const colors = [
        'bg-indigo-600', 'bg-purple-600', 'bg-sky-600',
        'bg-emerald-600', 'bg-amber-600', 'bg-rose-600',
        'bg-teal-600', 'bg-violet-600', 'bg-fuchsia-600'
    ];
    let hash = 0;
    for (let i = 0; i < (name || '').length; i++) {
        hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }
    return colors[Math.abs(hash) % colors.length];
}

// Quick status change from dropdown
async function updateReportStatus(reportId, newStatus) {
    try {
        const formData = new FormData();
        formData.append('report_id', reportId);
        formData.append('status', newStatus);

        const resp = await fetch('api/update_status.php', {
            method: 'POST',
            body: formData
        });
        const res = await resp.json();
        if (res.success) {
            const rep = allReports.find(x => x.id === reportId);
            if (rep) rep.status = newStatus;
            applyFilters();
            showToast(`Status for ${reportId} updated to ${newStatus.replace('_', ' ')}`);
        } else {
            alert('Error updating status: ' + res.error);
        }
    } catch (e) {
        console.error('Update status error:', e);
    }
}

// Delete report
async function deleteReport(reportId) {
    if (!confirm(`Are you sure you want to delete report ${reportId}?`)) return;

    try {
        const formData = new FormData();
        formData.append('report_id', reportId);

        const resp = await fetch('api/delete_hazard.php', {
            method: 'POST',
            body: formData
        });
        const res = await resp.json();
        if (res.success) {
            allReports = allReports.filter(x => x.id !== reportId);
            populateUserFilter(allReports);
            applyFilters();
            showToast(`Report ${reportId} deleted.`);
        } else {
            alert('Delete failed: ' + res.error);
        }
    } catch (e) {
        console.error('Delete error:', e);
    }
}

// Open detailed inspection modal (Matching Android App Interface!)
function openInspectionModal(reportId) {
    const report = allReports.find(x => x.id === reportId);
    if (!report) return;

    const modal = document.getElementById('inspection-modal');
    if (!modal) return;

    // Fill Modal Header Data
    document.getElementById('modal-report-id').textContent = report.id;
    document.getElementById('modal-title').textContent = report.title || 'Pothole Detected';
    document.getElementById('modal-status-badge').textContent = (report.status || 'reported').toUpperCase();
    
    const sevBadge = document.getElementById('modal-severity-badge');
    sevBadge.textContent = report.severity;
    sevBadge.className = `px-2.5 py-1 rounded text-xs font-bold uppercase tracking-wider ${getSeverityBadgeClass(report.severity)}`;

    // Image & Bounding Box Overlays
    const imgEl = document.getElementById('modal-image');
    imgEl.src = report.image_url || 'uploads/potholes/rpt-1792217799588.jpg';
    imgEl.onerror = () => { imgEl.src = 'uploads/potholes/rpt-1792217799588.jpg'; };

    const overlay = document.getElementById('modal-boxes-overlay');
    if (overlay) {
        overlay.innerHTML = '';
        const items = report.hazards_breakdown || [];
        if (Array.isArray(items)) {
            items.forEach((item) => {
                if (item.box && Array.isArray(item.box) && item.box.length === 4) {
                    const [ymin, xmin, ymax, xmax] = item.box;
                    const topPct = (ymin * 100).toFixed(2);
                    const leftPct = (xmin * 100).toFixed(2);
                    const widthPct = ((xmax - xmin) * 100).toFixed(2);
                    const heightPct = ((ymax - ymin) * 100).toFixed(2);

                    const boxDiv = document.createElement('div');
                    boxDiv.className = 'absolute border-2 border-rose-500 bg-rose-500/15 pointer-events-none rounded-sm transition';
                    boxDiv.style.top = `${topPct}%`;
                    boxDiv.style.left = `${leftPct}%`;
                    boxDiv.style.width = `${widthPct}%`;
                    boxDiv.style.height = `${heightPct}%`;

                    const labelSpan = document.createElement('span');
                    labelSpan.className = 'absolute -top-5 left-0 px-1.5 py-0.5 rounded bg-rose-600 text-white font-mono text-[9px] font-bold shadow-xs whitespace-nowrap';
                    labelSpan.textContent = `${item.type || 'Pothole'} ${item.confidence || ''}%`;

                    boxDiv.appendChild(labelSpan);
                    overlay.appendChild(boxDiv);
                }
            });
        }
    }

    // Citizen Contributor Info
    const uName = report.user_name || 'Citizen Contributor';
    const uId = report.user_id || 'anonymous';
    const uDevice = report.device_model || 'Android Mobile Scanner Device';

    const userNameEl = document.getElementById('modal-user-name');
    if (userNameEl) userNameEl.textContent = uName;

    const userIdEl = document.getElementById('modal-user-id');
    if (userIdEl) userIdEl.textContent = uId;

    const userDevEl = document.getElementById('modal-user-device');
    if (userDevEl) {
        userDevEl.innerHTML = `<i data-lucide="smartphone" class="w-3 h-3"></i><span>${uDevice}</span>`;
    }

    const userPhoneEl = document.getElementById('modal-user-phone');
    if (userPhoneEl) {
        userPhoneEl.textContent = report.user_phone ? `Phone: ${report.user_phone}` : '';
    }

    const userAvatarEl = document.getElementById('modal-user-avatar');
    if (userAvatarEl) {
        userAvatarEl.textContent = getUserInitials(uName);
        userAvatarEl.className = `w-9 h-9 rounded-full ${getUserAvatarBg(uName)} flex items-center justify-center text-xs font-black text-white shrink-0 shadow`;
    }

    // AI Detection Metrics
    document.getElementById('modal-conf').textContent = (report.confidence_pct || Math.round(report.confidence * 100)) + '%';
    document.getElementById('modal-sev-text').textContent = report.severity;
    document.getElementById('modal-defects').textContent = (report.defects_count || 1) + ' detected';
    document.getElementById('modal-inference').textContent = `${report.model_name || 'best.tflite'} (${report.inference_time_ms || 1575}ms inference)`;

    // Physical Measurements from Android App DamageReport
    const dmgTypeEl = document.getElementById('modal-damage-type');
    if (dmgTypeEl) dmgTypeEl.textContent = report.damage_type || 'Pothole';

    const depthEl = document.getElementById('modal-depth');
    if (depthEl) {
        depthEl.textContent = (report.estimated_depth_cm && report.estimated_depth_cm > 0) 
            ? `${report.estimated_depth_cm} cm` 
            : 'N/A';
    }

    const crackEl = document.getElementById('modal-crack-width');
    if (crackEl) {
        crackEl.textContent = (report.crack_width_mm && report.crack_width_mm > 0) 
            ? `${report.crack_width_mm} mm` 
            : 'N/A';
    }

    const areaEl = document.getElementById('modal-area');
    if (areaEl) {
        areaEl.textContent = (report.damage_area_sqm && report.damage_area_sqm > 0) 
            ? `${report.damage_area_sqm} m²` 
            : 'N/A';
    }

    // Hazards breakdown list
    const breakdownContainer = document.getElementById('modal-breakdown-list');
    breakdownContainer.innerHTML = '';

    let items = report.hazards_breakdown;
    if (typeof items === 'string') {
        try { items = JSON.parse(items); } catch (e) { items = []; }
    }
    if (!Array.isArray(items) || items.length === 0) {
        items = [{ id: 1, type: 'Pothole', surface_coverage: 4.6, confidence: Math.round(report.confidence * 100) }];
    }

    document.getElementById('modal-hazard-count').textContent = `${items.length} Items`;

    items.forEach((item, idx) => {
        const itemEl = document.createElement('div');
        itemEl.className = 'flex items-center justify-between p-2.5 rounded-lg bg-slate-50 border border-slate-200';
        itemEl.innerHTML = `
            <div class="flex items-center gap-2.5">
                <span class="w-6 h-6 rounded-full bg-rose-100 text-rose-700 border border-rose-200 text-xs font-bold flex items-center justify-center">
                    ${item.id || (idx + 1)}
                </span>
                <div>
                    <div class="text-xs font-bold text-slate-900">${item.type || 'Pothole'}</div>
                    <div class="text-[11px] text-slate-500">Surface coverage: <span class="text-slate-700 font-semibold">${item.surface_coverage || '3.5'}%</span></div>
                </div>
            </div>
            <div class="px-2 py-0.5 rounded bg-rose-50 text-rose-700 border border-rose-200 text-xs font-bold">
                ${item.confidence || 66}% Conf.
            </div>
        `;
        breakdownContainer.appendChild(itemEl);
    });

    // GPS & Location
    const lat = parseFloat(report.latitude).toFixed(5);
    const lng = parseFloat(report.longitude).toFixed(5);
    document.getElementById('modal-gps').textContent = `GPS (${lat}, ${lng})`;
    document.getElementById('modal-latlng-text').textContent = `Lat: ${lat}, Lng: ${lng}`;
    document.getElementById('modal-road-name').textContent = report.road_name || 'GPS Road Survey Coordinates';
    
    const gmapsBtn = document.getElementById('modal-gmaps-link');
    gmapsBtn.href = `https://www.google.com/maps?q=${lat},${lng}`;

    // Authority Action Form Fields
    document.getElementById('form-report-id').value = report.id;
    document.getElementById('form-status').value = report.status;
    document.getElementById('form-crew').value = report.assigned_crew || '';
    document.getElementById('form-notes').value = report.repair_notes || '';

    // Show modal
    modal.classList.remove('hidden');
    modal.classList.add('flex');
    lucide.createIcons();
}

function closeInspectionModal() {
    const modal = document.getElementById('inspection-modal');
    if (!modal) return;
    modal.classList.add('hidden');
    modal.classList.remove('flex');
}

// Handle Authority Form Submission
async function handleAuthorityFormSubmit(e) {
    e.preventDefault();
    const form = e.target;
    const formData = new FormData(form);

    try {
        const resp = await fetch('api/update_status.php', {
            method: 'POST',
            body: formData
        });
        const res = await resp.json();
        if (res.success) {
            showToast('Hazard authority action saved successfully!');
            closeInspectionModal();
            loadHazardsData();
        } else {
            alert('Update error: ' + res.error);
        }
    } catch (err) {
        console.error('Error submitting authority action:', err);
    }
}

// Export Table to CSV (Includes Citizen User info)
function exportToCSV() {
    if (allReports.length === 0) return alert('No data to export.');

    let csv = 'Report_ID,Title,User_Name,User_ID,Device_Model,Severity,Status,Latitude,Longitude,Confidence_Pct,Defects_Count,Road_Name,Reported_At,Assigned_Crew\n';
    allReports.forEach(r => {
        csv += `"${r.id}","${(r.title||'').replace(/"/g, '""')}","${(r.user_name||'').replace(/"/g, '""')}","${(r.user_id||'').replace(/"/g, '""')}","${(r.device_model||'').replace(/"/g, '""')}","${r.severity}","${r.status}",${r.latitude},${r.longitude},${r.confidence_pct || (r.confidence*100)},${r.defects_count},"${(r.road_name||'').replace(/"/g, '""')}","${r.reported_at}","${(r.assigned_crew||'').replace(/"/g, '""')}"\n`;
    });

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `pothole_reports_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
}

// Helpers
function formatDate(dt) {
    if (!dt) return 'Just now';
    const d = new Date(dt);
    if (isNaN(d.getTime())) return dt;
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function showToast(msg) {
    const toast = document.createElement('div');
    toast.className = 'fixed bottom-5 right-5 z-50 bg-indigo-600 text-white text-xs font-semibold px-4 py-3 rounded-xl shadow-2xl flex items-center gap-2 animate-bounce';
    toast.innerHTML = `<i data-lucide="check-circle-2" class="w-4 h-4"></i> <span>${msg}</span>`;
    document.body.appendChild(toast);
    lucide.createIcons();
    setTimeout(() => {
        toast.remove();
    }, 3500);
}


// Supabase Cloud Real-time Live Synchronization
const SUPABASE_CONFIG = {
    url: 'https://dytilqslhxmlhrwselam.supabase.co',
    key: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR5dGlscXNsaHhtbGhyd3NlbGFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5NDE5MDIsImV4cCI6MjEwODUxNzkwMn0.NHMeba85rqFXLO7UAnLqAT_j9J50Y-mwqRVpiVV59Uk'
};

let supabaseClient = null;

function initSupabaseRealtime() {
    if (window.supabase) {
        try {
            supabaseClient = window.supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.key);
            supabaseClient
                .channel('public:damage_reports')
                .on('postgres_changes', { event: '*', schema: 'public', table: 'damage_reports' }, (payload) => {
                    console.log('Realtime database event from mobile sync:', payload);
                    if (payload.eventType === 'INSERT') {
                        showToast(`📡 Live Capture: ${payload.new.reported_by || 'Citizen'} uploaded ${payload.new.damage_type || 'a road defect'}`);
                    } else if (payload.eventType === 'UPDATE') {
                        showToast(`📝 Defect ${payload.new.id} status updated to ${payload.new.status}`);
                    }
                    loadHazardsData();
                })
                .subscribe((status) => {
                    console.log('Supabase Realtime Channel Status:', status);
                });
        } catch (e) {
            console.warn('Supabase realtime init error:', e);
        }
    }
}
