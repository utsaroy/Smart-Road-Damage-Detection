
let currentOpenReportId = null;

// Callback triggered whenever the language switch occurs
function onLanguageChanged(lang) {
    if (window.latestStatsData) {
        updateStatsUI(window.latestStatsData);
    }
    populateUserFilter(allReports);
    updateAllGeoDropdowns();
    updateGeoActiveBadge();
    applyFilters();
    loadUpazillaAnalytics();
    if (currentOpenReportId) {
        openInspectionModal(currentOpenReportId);
    }
    if (typeof updateMapMarkers === 'function') {
        updateMapMarkers(allReports);
    }
}
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
    updateAllGeoDropdowns();
    loadUpazillaAnalytics();

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
            window.latestStatsData = data.stats;
            updateStatsUI(data.stats);
            populateUserFilter(allReports);
            applyFilters();
            loadUpazillaAnalytics();
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
    const allUsersLabel = currentAppLang === 'bn' 
        ? `${t('filter_all_users_prefix')} (${formatNumber(Object.keys(usersMap).length)} ${t('filter_contributors')})`
        : `All Citizens / Users (${Object.keys(usersMap).length} contributors)`;
    userSelect.innerHTML = `<option value="all">${allUsersLabel}</option>`;
    
    for (const [uid, u] of Object.entries(usersMap)) {
        const opt = document.createElement('option');
        opt.value = uid;
        opt.textContent = `${u.name} (${formatNumber(u.count)})`;
        if (uid === currentSelection) opt.selected = true;
        userSelect.appendChild(opt);
    }
}

// Update Top KPI Cards
function updateStatsUI(stats) {
    if (!stats) return;
    document.getElementById('stat-total').textContent = formatNumber(stats.total ?? 0);
    document.getElementById('stat-high').textContent = formatNumber(stats.high_severity ?? 0);
    document.getElementById('stat-pending').textContent = formatNumber(stats.pending ?? 0);
    document.getElementById('stat-progress').textContent = formatNumber(stats.in_progress ?? 0);
    document.getElementById('stat-resolved').textContent = formatNumber(stats.resolved ?? 0);
    
    const usersEl = document.getElementById('stat-users');
    if (usersEl) {
        usersEl.textContent = formatNumber(stats.total_users ?? 1);
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
            const matchUpa = (r.upazilla || '').toLowerCase().includes(s);
            if (!matchId && !matchTitle && !matchRoad && !matchDist && !matchUser && !matchUpa) {
                return false;
            }
        }
        // Geographic filters
        if (currentGeoFilters.division !== 'all' && (r.division || '').toLowerCase() !== currentGeoFilters.division.toLowerCase()) {
            return false;
        }
        if (currentGeoFilters.district !== 'all' && (r.district || '').toLowerCase() !== currentGeoFilters.district.toLowerCase()) {
            return false;
        }
        if (currentGeoFilters.upazilla !== 'all' && (r.upazilla || '').toLowerCase() !== currentGeoFilters.upazilla.toLowerCase()) {
            return false;
        }
        return true;
    });

    renderTable(filtered);
    updateMapMarkers(filtered);
    document.getElementById('filter-count').textContent = currentAppLang === 'bn' ? `${formatNumber(filtered.length)} / ${formatNumber(allReports.length)} ${t('records_count_suffix')}` : `${filtered.length} of ${allReports.length} records`;
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
                        <span>${t('table_empty_records')}</span>
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
        const uName = r.user_name || (currentAppLang === 'bn' ? 'নাগরিক অবদানকারী' : 'Citizen Contributor');
        const uId = r.user_id || 'anonymous';
        const uDevice = r.device_model || (currentAppLang === 'bn' ? 'অ্যান্ড্রয়েড ফোন' : 'Android Phone');
        const avatarBg = getUserAvatarBg(uName);
        const initials = getUserInitials(uName);
        const sevText = translateSeverity(r.severity);
        const upazillaText = translateGeoName(r.upazilla || 'Khan Jahan Ali');
        const districtText = translateGeoName(r.district || 'Khulna');
        const confPct = r.confidence_pct || Math.round(r.confidence * 100);

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
                            ${formatNumber(r.defects_count)}x
                        </span>
                    </div>
                </td>

                <!-- ID & Timestamp -->
                <td class="py-3 px-4">
                    <div class="font-bold text-slate-900 text-xs hover:text-sky-700 cursor-pointer flex items-center gap-1.5" onclick="openInspectionModal('${r.id}')">
                        <span>${r.id}</span>
                    </div>
                    <div class="text-[11px] text-slate-500 mt-0.5">
                        ${formatAppDate(r.reported_at)}
                    </div>
                </td>

                <!-- Citizen / User Scanner (Multi-User Visibility) -->
                <td class="py-3 px-4">
                    <div class="flex items-center gap-2.5">
                        <div class="w-8 h-8 rounded-full ${avatarBg} flex items-center justify-center text-[10px] font-black text-white shrink-0 shadow-2xs">
                            ${initials}
                        </div>
                        <div class="min-w-0">
                            <div class="font-bold text-slate-900 text-xs truncate max-w-[180px]" title="${uName}">
                                ${uName}
                            </div>
                            <div class="text-[10px] text-sky-700 font-mono flex items-center gap-1 mt-0.5">
                                <span>${uId}</span>
                            </div>
                        </div>
                    </div>
                </td>

                <!-- Severity & Confidence -->
                <td class="py-3 px-4">
                    <span class="inline-block px-2.5 py-0.5 rounded text-xs font-bold uppercase tracking-wider ${sevClass}">
                        ${sevText}
                    </span>
                    <div class="text-xs text-slate-600 mt-1 flex items-center gap-1">
                        <span class="font-bold text-slate-900">${formatNumber(confPct)}%</span>
                        <span class="text-slate-400">${t('conf_suffix')}</span>
                    </div>
                </td>

                <!-- Location & GPS -->
                <td class="py-3 px-4">
                    <div class="flex items-center gap-1.5 mb-1">
                        <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold bg-sky-50 text-sky-700 border border-sky-200">
                            <i data-lucide="map-pin" class="w-3 h-3 text-sky-600"></i>
                            <span>${upazillaText}, ${districtText}</span>
                        </span>
                    </div>
                    <div class="text-xs font-medium text-slate-800 truncate max-w-[200px]" title="${r.road_name || ''}">
                        ${(!r.road_name || r.road_name === 'Location unavailable') 
                            ? (currentAppLang === 'bn' ? `${upazillaText} সড়ক সেগমেন্ট` : `${r.upazilla || 'Survey'} Route Segment`) 
                            : r.road_name}
                    </div>
                    <div class="text-[11px] text-slate-500 flex items-center gap-2 mt-1">
                        <span class="font-mono text-sky-700 font-medium">${lat}, ${lng}</span>
                        <button onclick="flyToReport('${r.id}')" title="${currentAppLang === 'bn' ? 'ম্যাপে দেখুন' : 'Locate on GIS Map'}" class="text-sky-600 hover:text-sky-800 transition cursor-pointer">
                            <i data-lucide="map-pin" class="w-3.5 h-3.5 inline"></i>
                        </button>
                    </div>
                </td>

                <!-- Status Selector -->
                <td class="py-3 px-4">
                    <select onchange="updateReportStatus('${r.id}', this.value)" class="bg-slate-50 border border-slate-200 rounded-lg text-xs font-medium px-2.5 py-1.5 text-slate-800 focus:outline-none focus:bg-white focus:border-sky-500 cursor-pointer">
                        <option value="reported" ${r.status === 'reported' ? 'selected' : ''}>${t('status_reported')}</option>
                        <option value="verified" ${r.status === 'verified' ? 'selected' : ''}>${t('status_verified')}</option>
                        <option value="assigned" ${r.status === 'assigned' ? 'selected' : ''}>${t('status_assigned')}</option>
                        <option value="under_repair" ${r.status === 'under_repair' ? 'selected' : ''}>${t('status_under_repair')}</option>
                        <option value="resolved" ${r.status === 'resolved' ? 'selected' : ''}>${t('status_resolved')}</option>
                    </select>
                    ${r.assigned_crew ? `<div class="text-[10px] text-slate-500 mt-1 truncate max-w-[150px]">${t('crew_label')} ${r.assigned_crew}</div>` : ''}
                </td>

                <!-- Actions -->
                <td class="py-3 px-4 text-right">
                    <div class="flex items-center justify-end gap-1.5">
                        <button onclick="openInspectionModal('${r.id}')" class="px-2.5 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold transition flex items-center gap-1 border border-slate-200 cursor-pointer">
                            <i data-lucide="eye" class="w-3.5 h-3.5 text-slate-500"></i>
                            <span>${t('btn_inspect')}</span>
                        </button>
                        <button onclick="deleteReport('${r.id}')" class="p-1.5 bg-rose-50 hover:bg-rose-100 text-rose-600 rounded-lg text-xs transition border border-rose-200 cursor-pointer" title="Delete record">
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
    currentOpenReportId = reportId;
    const report = allReports.find(x => x.id === reportId);
    if (!report) return;

    const modal = document.getElementById('inspection-modal');
    if (!modal) return;

    // Fill Modal Header Data
    document.getElementById('modal-report-id').textContent = report.id;
    document.getElementById('modal-title').textContent = report.title || t('modal_details_title');
    document.getElementById('modal-status-badge').textContent = translateStatus(report.status);
    
    const sevBadge = document.getElementById('modal-severity-badge');
    sevBadge.textContent = translateSeverity(report.severity);
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
    document.getElementById('modal-conf').textContent = formatNumber(report.confidence_pct || Math.round(report.confidence * 100)) + '%';
    document.getElementById('modal-sev-text').textContent = translateSeverity(report.severity);
    document.getElementById('modal-defects').textContent = `${formatNumber(report.defects_count || 1)} ${t('modal_detected_suffix')}`;
    document.getElementById('modal-inference').textContent = `${report.model_name || 'best.tflite'} (${formatNumber(report.inference_time_ms || 1575)}ms ${t('modal_inference_suffix')})`;

    // Physical Measurements from Android App DamageReport
    const dmgTypeEl = document.getElementById('modal-damage-type');
    if (dmgTypeEl) dmgTypeEl.textContent = translateDefectType(report.damage_type || 'Pothole');

    const depthEl = document.getElementById('modal-depth');
    if (depthEl) {
        depthEl.textContent = (report.estimated_depth_cm && report.estimated_depth_cm > 0) 
            ? `${formatNumber(report.estimated_depth_cm)} cm` 
            : '--';
    }

    const crackEl = document.getElementById('modal-crack-width');
    if (crackEl) {
        crackEl.textContent = (report.crack_width_mm && report.crack_width_mm > 0) 
            ? `${formatNumber(report.crack_width_mm)} mm` 
            : '--';
    }

    const areaEl = document.getElementById('modal-area');
    if (areaEl) {
        areaEl.textContent = (report.damage_area_sqm && report.damage_area_sqm > 0) 
            ? `${formatNumber(report.damage_area_sqm)} m²` 
            : '--';
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

    document.getElementById('modal-hazard-count').textContent = `${formatNumber(items.length)} ${t('modal_items_suffix')}`;

    items.forEach((item, idx) => {
        const itemEl = document.createElement('div');
        itemEl.className = 'flex items-center justify-between p-2.5 rounded-lg bg-slate-50 border border-slate-200';
        itemEl.innerHTML = `
            <div class="flex items-center gap-2.5">
                <span class="w-6 h-6 rounded-full bg-rose-100 text-rose-700 border border-rose-200 text-xs font-bold flex items-center justify-center">
                    ${formatNumber(item.id || (idx + 1))}
                </span>
                <div>
                    <div class="text-xs font-bold text-slate-900">${translateDefectType(item.type || 'Pothole')}</div>
                    <div class="text-[11px] text-slate-500">${t('modal_surface_coverage')} <span class="text-slate-700 font-semibold">${formatNumber(item.surface_coverage || '3.5')}%</span></div>
                </div>
            </div>
            <div class="px-2 py-0.5 rounded bg-rose-50 text-rose-700 border border-rose-200 text-xs font-bold">
                ${formatNumber(item.confidence || 66)}% ${t('modal_conf_short')}
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
    currentOpenReportId = null;
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


// =========================================================================
// UPAZILLA-WISE POTHOLE DENSITY RATIO & GEOGRAPHIC ANALYTICS SYSTEM
// =========================================================================

let geoHierarchy = {
    'Khulna': {},
    'Dhaka': {},
    'Chattogram': {},
    'Rajshahi': {},
    'Barishal': {},
    'Sylhet': {},
    'Rangpur': {},
    'Mymensingh': {}
};
let currentGeoFilters = {
    division: 'all',
    district: 'all',
    upazilla: 'all',
    search: ''
};
let currentGeoRankingData = [];
let currentParticularStat = null;
let upazillaSearchTimeout = null;

/**
 * Fetch and render Upazilla-wise Pothole Density Ratio Analytics
 */
async function loadUpazillaAnalytics() {
    try {
        const queryParams = new URLSearchParams({
            division: currentGeoFilters.division,
            district: currentGeoFilters.district,
            upazilla: currentGeoFilters.upazilla,
            search: currentGeoFilters.search
        });

        const resp = await fetch('api/upazilla_analytics.php?' + queryParams.toString());
        const data = await resp.json();

        if (!data.success) {
            console.error('Upazilla analytics error:', data.error);
            return;
        }

        geoHierarchy = data.hierarchy;
        currentGeoRankingData = data.ranking || [];
        currentParticularStat = data.particular_stat || null;

        // Populate / update all geographic selectors in the active language
        updateAllGeoDropdowns();

        // Update Total Stats Pills
        const upaCountEl = document.getElementById('stat-geo-upazillas-count');
        if (upaCountEl) {
            upaCountEl.textContent = data.totals ? data.totals.total_upazillas_affected : currentGeoRankingData.length;
        }
        const hazardCountEl = document.getElementById('stat-geo-hazards-count');
        if (hazardCountEl) {
            hazardCountEl.textContent = data.totals ? data.totals.in_scope : 0;
        }

        // Update Active Scope Badge
        updateGeoActiveBadge();

        // Update Table Heading based on Searching vs Descending Standings
        const tableHeading = document.getElementById('geo-table-heading');
        const isSearching = !!(currentGeoFilters.search && currentGeoFilters.search.trim().length > 0);

        if (tableHeading) {
            if (isSearching) {
                tableHeading.textContent = currentAppLang === 'bn'
                    ? `"${currentGeoFilters.search}" এর ফলাফল (${formatNumber(currentGeoRankingData.length)}টি উপজেলা পাওয়া গেছে)`
                    : `Search Results for "${currentGeoFilters.search}" (${currentGeoRankingData.length} Upazilla${currentGeoRankingData.length === 1 ? '' : 's'} found)`;
            } else if (currentGeoFilters.upazilla !== 'all') {
                tableHeading.textContent = currentAppLang === 'bn'
                    ? `${translateGeoName(currentGeoFilters.upazilla)} উপজেলা স্ট্যান্ডিংস`
                    : `Standings: ${currentGeoFilters.upazilla} Upazilla`;
            } else if (currentGeoFilters.district !== 'all') {
                tableHeading.textContent = currentAppLang === 'bn'
                    ? `${translateGeoName(currentGeoFilters.district)} জেলা স্ট্যান্ডিংস (সর্বোচ্চ থেকে সর্বনিম্ন)`
                    : `Upazilla Standings: ${currentGeoFilters.district} District (Descending Order)`;
            } else if (currentGeoFilters.division !== 'all') {
                tableHeading.textContent = currentAppLang === 'bn'
                    ? `${translateGeoName(currentGeoFilters.division)} বিভাগ স্ট্যান্ডিংস (সর্বোচ্চ থেকে সর্বনিম্ন)`
                    : `Upazilla Standings: ${currentGeoFilters.division} Division (Descending Order)`;
            } else {
                tableHeading.textContent = t('table_density_heading');
            }
        }

        // Render Upazilla Standings / Search Table
        renderUpazillaLeaderboard(currentGeoRankingData, data.totals ? data.totals.countrywide : 1);

        // While searching, show ONLY the searching table results - HIDE the particular card
        // Only show particular card when NOT searching AND when an upazilla with actual hazards is selected
        const particularCard = document.getElementById('particular-upazilla-card');
        if (isSearching || currentGeoFilters.upazilla === 'all' || !currentParticularStat || currentParticularStat.total_hazards === 0) {
            if (particularCard) particularCard.classList.add('hidden');
        } else {
            renderParticularUpazillaCard(currentParticularStat);
        }

        // Refresh icons
        if (window.lucide) lucide.createIcons();

    } catch (err) {
        console.error('Failed to load Upazilla analytics:', err);
    }
}

/**
 * Update the active scope badge
 */
function updateGeoActiveBadge() {
    const badge = document.getElementById('geo-active-badge');
    if (!badge) return;

    if (currentGeoFilters.upazilla !== 'all') {
        badge.innerHTML = `<span class="text-sky-700 font-bold">${currentGeoFilters.upazilla} Upazilla</span> &bull; ${currentGeoFilters.district} &bull; ${currentGeoFilters.division} Division`;
    } else if (currentGeoFilters.district !== 'all') {
        badge.innerHTML = `<span class="text-sky-700 font-bold">${currentGeoFilters.district} District</span> &bull; ${currentGeoFilters.division} Division &bull; Descending Order`;
    } else if (currentGeoFilters.division !== 'all') {
        badge.innerHTML = `<span class="text-sky-700 font-bold">${currentGeoFilters.division} Division</span> &bull; All Districts &bull; Descending Order`;
    } else {
        badge.textContent = 'All Bangladesh • Descending Order';
    }
}

/**
 * Update all geographic dropdowns (Division, District, Upazilla) in the active language
 */
function updateAllGeoDropdowns() {
    populateDivisionDropdown();
    populateDistrictDropdown();
    populateUpazillaDropdown();
}

/**
 * Populate Division Dropdown in the active language
 */
function populateDivisionDropdown() {
    const divSelect = document.getElementById('geo-division-select');
    if (!divSelect || !geoHierarchy) return;

    const currentSelection = currentGeoFilters.division || 'all';
    const divisions = Object.keys(geoHierarchy);

    divSelect.innerHTML = `<option value="all">${t('geo_all_divisions')}</option>`;
    divisions.forEach(divName => {
        const opt = document.createElement('option');
        opt.value = divName;
        opt.textContent = `${translateGeoName(divName)} ${t('division_suffix')}`;
        if (divName === currentSelection) opt.selected = true;
        divSelect.appendChild(opt);
    });
}

/**
 * Populate District Dropdown based on selected division in the active language
 */
function populateDistrictDropdown() {
    const distSelect = document.getElementById('geo-district-select');
    if (!distSelect) return;

    const currentSelection = currentGeoFilters.district || 'all';
    distSelect.innerHTML = `<option value="all">${t('geo_all_districts')}</option>`;

    const selectedDiv = currentGeoFilters.division;
    if (selectedDiv !== 'all' && geoHierarchy && geoHierarchy[selectedDiv]) {
        const districts = Object.keys(geoHierarchy[selectedDiv]);
        districts.forEach(d => {
            const opt = document.createElement('option');
            opt.value = d;
            opt.textContent = `${translateGeoName(d)} ${t('district_suffix')}`;
            if (d === currentSelection) opt.selected = true;
            distSelect.appendChild(opt);
        });
    }
}

/**
 * Populate Upazilla Dropdown based on selected district in the active language
 */
function populateUpazillaDropdown() {
    const upaSelect = document.getElementById('geo-upazilla-select');
    if (!upaSelect) return;

    const currentSelection = currentGeoFilters.upazilla || 'all';
    upaSelect.innerHTML = `<option value="all">${t('geo_all_upazillas')}</option>`;

    const selectedDiv = currentGeoFilters.division;
    const selectedDist = currentGeoFilters.district;
    if (selectedDiv !== 'all' && selectedDist !== 'all' && geoHierarchy && geoHierarchy[selectedDiv] && geoHierarchy[selectedDiv][selectedDist]) {
        const upazillas = geoHierarchy[selectedDiv][selectedDist];
        upazillas.forEach(u => {
            const opt = document.createElement('option');
            opt.value = u;
            opt.textContent = `${translateGeoName(u)} ${t('upazilla_suffix')}`;
            if (u === currentSelection) opt.selected = true;
            upaSelect.appendChild(opt);
        });
    }
}

/**
 * Handle Division Change -> Update District Selector
 */
function onDivisionChange() {
    const divSelect = document.getElementById('geo-division-select');
    currentGeoFilters.division = divSelect ? divSelect.value : 'all';
    currentGeoFilters.district = 'all';
    currentGeoFilters.upazilla = 'all';

    populateDistrictDropdown();
    populateUpazillaDropdown();

    applyFilters();
    loadUpazillaAnalytics();
}

/**
 * Handle District Change -> Update Upazilla Selector
 */
function onDistrictChange() {
    const distSelect = document.getElementById('geo-district-select');
    currentGeoFilters.district = distSelect ? distSelect.value : 'all';
    currentGeoFilters.upazilla = 'all';

    populateUpazillaDropdown();

    applyFilters();
    loadUpazillaAnalytics();
}

/**
 * Handle Upazilla Selection
 */
function onUpazillaChange() {
    const upaSelect = document.getElementById('geo-upazilla-select');
    currentGeoFilters.upazilla = upaSelect.value;

    applyFilters();
    loadUpazillaAnalytics();
}

/**
 * Quick Upazilla Search Input (Live debounced filter)
 */
function onUpazillaSearchInput() {
    clearTimeout(upazillaSearchTimeout);
    const searchVal = document.getElementById('geo-upazilla-search').value.trim();
    upazillaSearchTimeout = setTimeout(() => {
        currentGeoFilters.search = searchVal;
        loadUpazillaAnalytics();
    }, 250);
}

/**
 * Reset all geographic filters
 */
function resetGeoFilters() {
    currentGeoFilters.division = 'all';
    currentGeoFilters.district = 'all';
    currentGeoFilters.upazilla = 'all';
    currentGeoFilters.search = '';

    const divSelect = document.getElementById('geo-division-select');
    if (divSelect) divSelect.value = 'all';

    const distSelect = document.getElementById('geo-district-select');
    if (distSelect) distSelect.innerHTML = `<option value="all">${t('geo_all_districts')}</option>`;

    const upaSelect = document.getElementById('geo-upazilla-select');
    if (upaSelect) upaSelect.innerHTML = `<option value="all">${t('geo_all_upazillas')}</option>`;

    const searchInput = document.getElementById('geo-upazilla-search');
    if (searchInput) searchInput.value = '';

    applyFilters();
    loadUpazillaAnalytics();
    if (typeof showToast === 'function') {
        showToast('✓ Geographic filters reset to all Bangladesh.');
    }
}

/**
 * Render Upazilla Density Leaderboard (Ranked in Descending Order)
 */
function renderUpazillaLeaderboard(ranking, countrywideTotal) {
    const tbody = document.getElementById('upazilla-density-body');
    if (!tbody) return;

    if (!ranking || ranking.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="8" class="text-center py-8 text-slate-400">
                    <div class="flex flex-col items-center justify-center gap-1.5">
                        <i data-lucide="map-pin-off" class="w-6 h-6 text-slate-300"></i>
                        <span>${t('table_empty_upazilla')}</span>
                    </div>
                </td>
            </tr>
        `;
        if (window.lucide) lucide.createIcons();
        return;
    }

    tbody.innerHTML = ranking.map(item => {
        // Density progress bar color
        let barColor = 'bg-rose-500';
        let badgeClass = 'bg-rose-50 text-rose-700 border-rose-200';
        if (item.total_hazards === 0) {
            barColor = 'bg-slate-200';
            badgeClass = 'bg-emerald-50 text-emerald-700 border-emerald-200';
        } else if (item.density_percentage >= 30) {
            barColor = 'bg-rose-600';
            badgeClass = 'bg-rose-100 text-rose-700 border-rose-200';
        } else if (item.density_percentage >= 15) {
            barColor = 'bg-orange-500';
            badgeClass = 'bg-orange-100 text-orange-700 border-orange-200';
        } else if (item.density_percentage >= 5) {
            barColor = 'bg-amber-500';
            badgeClass = 'bg-amber-100 text-amber-700 border-amber-200';
        } else {
            barColor = 'bg-emerald-500';
            badgeClass = 'bg-emerald-100 text-emerald-700 border-emerald-200';
        }

        // Rank Badge
        const rankFormatted = formatNumber(item.rank);
        let rankBadge = `<span class="w-6 h-6 rounded-full bg-slate-100 text-slate-700 font-black text-xs inline-flex items-center justify-center border border-slate-200">#${rankFormatted}</span>`;
        if (item.rank === 1) {
            rankBadge = `<span class="w-6 h-6 rounded-full bg-rose-600 text-white font-black text-xs inline-flex items-center justify-center shadow-xs">#${rankFormatted}</span>`;
        } else if (item.rank === 2) {
            rankBadge = `<span class="w-6 h-6 rounded-full bg-orange-500 text-white font-black text-xs inline-flex items-center justify-center">#${rankFormatted}</span>`;
        } else if (item.rank === 3) {
            rankBadge = `<span class="w-6 h-6 rounded-full bg-amber-500 text-white font-black text-xs inline-flex items-center justify-center">#${rankFormatted}</span>`;
        }

        const upaName = `${translateGeoName(item.upazilla)} ${t('upazilla_suffix')}`;
        const distName = `${translateGeoName(item.district)} ${t('district_suffix')}`;
        const divName = `${translateGeoName(item.division)} ${t('division_suffix')}`;
        const gradeText = translateGrade(item.density_grade);
        const urgencyText = translateUrgency(item.urgency);

        return `
            <tr class="hover:bg-slate-50/80 transition border-b border-slate-100 group">
                <!-- Rank -->
                <td class="py-3 px-3.5 text-center font-bold">
                    ${rankBadge}
                </td>

                <!-- Upazilla Name -->
                <td class="py-3 px-3.5">
                    <div class="font-black text-slate-900 text-xs flex items-center gap-1.5 cursor-pointer hover:text-sky-700 transition" 
                         onclick="selectParticularUpazilla('${item.upazilla}', '${item.district}', '${item.division}')">
                        <i data-lucide="map-pin" class="w-3.5 h-3.5 text-rose-500 shrink-0"></i>
                        <span>${upaName}</span>
                    </div>
                </td>

                <!-- District & Division -->
                <td class="py-3 px-3.5 text-xs text-slate-600">
                    <div class="font-semibold text-slate-800">${distName}</div>
                    <div class="text-[10px] text-slate-400">${divName}</div>
                </td>

                <!-- Potholes Count -->
                <td class="py-3 px-3.5 text-center">
                    <div class="inline-flex items-baseline gap-1 bg-slate-100 px-2.5 py-1 rounded-lg border border-slate-200">
                        <span class="text-sm font-black text-slate-900">${formatNumber(item.total_hazards)}</span>
                        <span class="text-[10px] text-slate-400 font-medium">${t('defects_unit')}</span>
                    </div>
                </td>

                <!-- Density Ratio Percentage & Progress Bar -->
                <td class="py-3 px-3.5 ${item.total_hazards === 0 ? 'text-center' : ''}">
                    ${item.total_hazards === 0 
                        ? `<div class="text-base font-black text-slate-400 tracking-tight flex items-center justify-center">0%</div>`
                        : `<div>
                            <div class="flex items-center justify-between text-xs mb-1">
                                <span class="font-black text-slate-900 text-sm">${formatNumber(item.density_percentage)}%</span>
                                <span class="text-[10px] font-bold px-1.5 py-0.2 rounded border ${badgeClass}">${gradeText}</span>
                            </div>
                            <div class="w-full bg-slate-100 h-2 rounded-full overflow-hidden border border-slate-200/80">
                                <div class="${barColor} h-full rounded-full transition-all duration-500" style="width: ${Math.max(6, item.density_relative_pct)}%"></div>
                            </div>
                        </div>`
                    }
                </td>

                <!-- Severity Profile -->
                <td class="py-3 px-3.5 text-center">
                    ${item.total_hazards === 0 
                        ? `<span class="px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-200 text-[10px] font-bold">${t('all_clear_count')}</span>`
                        : `<div class="inline-flex items-center gap-1 text-[10px] font-bold">
                            ${item.critical_count > 0 ? `<span class="px-1.5 py-0.5 rounded bg-rose-50 text-rose-700 border border-rose-200" title="Critical">${formatNumber(item.critical_count)} ${currentAppLang === 'bn' ? 'মারাত্মক' : 'Crit'}</span>` : ''}
                            ${item.high_count > 0 ? `<span class="px-1.5 py-0.5 rounded bg-orange-50 text-orange-700 border border-orange-200" title="High">${formatNumber(item.high_count)} ${currentAppLang === 'bn' ? 'উচ্চ' : 'High'}</span>` : ''}
                            ${item.medium_count > 0 ? `<span class="px-1.5 py-0.5 rounded bg-amber-50 text-amber-700 border border-amber-200" title="Medium">${formatNumber(item.medium_count)} ${currentAppLang === 'bn' ? 'মাঝারি' : 'Med'}</span>` : ''}
                            ${item.low_count > 0 ? `<span class="px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 border border-slate-200" title="Low">${formatNumber(item.low_count)} ${currentAppLang === 'bn' ? 'সাধারণ' : 'Low'}</span>` : ''}
                        </div>`
                    }
                </td>

                <!-- Repair Urgency -->
                <td class="py-3 px-3.5 text-xs text-slate-700">
                    <div class="font-bold truncate max-w-[160px]" title="${urgencyText}">${urgencyText}</div>
                    <div class="text-[10px] text-slate-400">${formatNumber(item.pending_count)} ${t('pending_inspection_unit')}</div>
                </td>

                <!-- Actions -->
                <td class="py-3 px-3.5 text-right">
                    <div class="inline-flex items-center gap-1.5">
                        <button type="button" onclick="focusUpazilla(${item.centroid_lat}, ${item.centroid_lng}, '${item.upazilla}')" 
                                class="px-2.5 py-1 rounded-md text-[11px] font-bold bg-sky-50 text-sky-700 hover:bg-sky-100 border border-sky-200 transition flex items-center gap-1 shadow-2xs cursor-pointer"
                                title="${t('btn_map')}">
                            <i data-lucide="navigation" class="w-3 h-3"></i>
                            <span>${t('btn_map')}</span>
                        </button>
                        <button type="button" onclick="filterTableToUpazilla('${item.upazilla}')" 
                                class="px-2.5 py-1 rounded-md text-[11px] font-semibold bg-slate-100 text-slate-700 hover:bg-slate-200 border border-slate-200 transition flex items-center gap-1 cursor-pointer"
                                title="${t('btn_records')}">
                            <i data-lucide="list-filter" class="w-3 h-3"></i>
                            <span>${t('btn_records')}</span>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }).join('');

    if (window.lucide) lucide.createIcons();
}

/**
 * Render Particular Upazilla Highlight Card
 */
function renderParticularUpazillaCard(stat) {
    const card = document.getElementById('particular-upazilla-card');
    if (!card) return;

    if (!stat) {
        card.classList.add('hidden');
        return;
    }

    card.classList.remove('hidden');

    document.getElementById('particular-name').textContent = `${translateGeoName(stat.upazilla)} ${t('upazilla_suffix')}`;
    document.getElementById('particular-region').textContent = `${translateGeoName(stat.district)} ${t('district_suffix')}, ${translateGeoName(stat.division)} ${t('division_suffix')}`;
    document.getElementById('particular-density-ratio').textContent = `${formatNumber(stat.density_percentage)}%`;
    document.getElementById('particular-total').textContent = formatNumber(stat.total_hazards);

    const badgeGrade = document.getElementById('particular-badge-grade');

    if (stat.total_hazards === 0) {
        document.getElementById('particular-severity-sub').textContent = t('card_all_clear');
        document.getElementById('particular-status').textContent = t('card_zero_pending');
        document.getElementById('particular-urgency').textContent = t('card_safe_pavement');
        document.getElementById('particular-roads').textContent = t('card_no_active_defects');
        if (badgeGrade) {
            badgeGrade.textContent = t('card_badge_zero');
            badgeGrade.className = 'px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-emerald-100 text-emerald-800 border border-emerald-300';
        }
    } else {
        document.getElementById('particular-severity-sub').textContent = `${formatNumber(stat.critical_count)} ${t('card_critical')} • ${formatNumber(stat.high_count)} ${t('card_high')} • ${formatNumber(stat.medium_count)} ${t('card_medium')}`;
        document.getElementById('particular-status').textContent = `${formatNumber(stat.pending_count)} ${t('card_pending_rev')}`;
        document.getElementById('particular-urgency').textContent = translateUrgency(stat.urgency);

        const roadsStr = stat.sample_roads && stat.sample_roads.length > 0 
            ? stat.sample_roads.join(', ') 
            : (currentAppLang === 'bn' ? 'সক্রিয় সড়ক নেটওয়ার্ক রুট' : 'Active Pavement Route Coordinates');
        document.getElementById('particular-roads').textContent = roadsStr;

        const crewSub = document.getElementById('particular-crew-sub');
        if (crewSub) crewSub.textContent = `${formatNumber(stat.in_progress_count || 0)} ${t('card_active_crews')}`;

        const actionSub = document.getElementById('particular-action-sub');
        if (actionSub) actionSub.textContent = `${translateUrgency(stat.urgency) || t('card_action_guideline')}`;

        if (badgeGrade) {
            badgeGrade.textContent = translateGrade(stat.density_grade);
            if (stat.density_percentage >= 30) {
                badgeGrade.className = 'px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-rose-100 text-rose-700 border border-rose-200';
            } else if (stat.density_percentage >= 15) {
                badgeGrade.className = 'px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-orange-100 text-orange-700 border border-orange-200';
            } else if (stat.density_percentage >= 5) {
                badgeGrade.className = 'px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-amber-100 text-amber-700 border border-amber-200';
            } else {
                badgeGrade.className = 'px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-emerald-100 text-emerald-800 border border-emerald-300';
            }
        }
    }

    if (window.lucide) lucide.createIcons();
}

/**
 * Select a specific upazilla from the table or card
 */
function selectParticularUpazilla(upazilla, district, division) {
    currentGeoFilters.division = division;
    currentGeoFilters.district = district;
    currentGeoFilters.upazilla = upazilla;

    const divSelect = document.getElementById('geo-division-select');
    if (divSelect) divSelect.value = division;
    onDivisionChange();

    setTimeout(() => {
        const distSelect = document.getElementById('geo-district-select');
        if (distSelect) distSelect.value = district;
        onDistrictChange();

        setTimeout(() => {
            const upaSelect = document.getElementById('geo-upazilla-select');
            if (upaSelect) upaSelect.value = upazilla;
            onUpazillaChange();
        }, 80);
    }, 80);
}

/**
 * Focus map on the particular upazilla
 */
function focusParticularOnMap() {
    if (!currentParticularStat) return;
    focusUpazilla(currentParticularStat.centroid_lat, currentParticularStat.centroid_lng, currentParticularStat.upazilla);
}

/**
 * Filter records table to the particular upazilla
 */
function filterTableToParticular() {
    if (!currentParticularStat) return;
    filterTableToUpazilla(currentParticularStat.upazilla);
}

/**
 * Fly map to an Upazilla and scroll smoothly to map
 */
function focusUpazilla(lat, lng, upazillaName) {
    if (typeof flyToUpazillaLocation === 'function') {
        flyToUpazillaLocation(lat, lng, upazillaName);
    } else if (hazardMap && lat && lng) {
        hazardMap.flyTo([lat, lng], 14.5, { animate: true, duration: 1.0 });
        const mapEl = document.getElementById('hazard-map');
        if (mapEl) mapEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
}

/**
 * Filter data table to an upazilla and scroll to table
 */
function filterTableToUpazilla(upazillaName) {
    const searchInput = document.getElementById('search-input');
    if (searchInput) {
        searchInput.value = upazillaName;
        currentFilter.search = upazillaName.toLowerCase();
        applyFilters();
    }
    const tableSection = document.getElementById('reports-table-body');
    if (tableSection) {
        tableSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
    if (typeof showToast === 'function') {
        showToast(`Filtered database records to: ${upazillaName} Upazilla`);
    }
}
