/**
 * Crew GIS Road Hazard Map Engine (Leaflet)
 * Centered on Crew's Upazilla Jurisdiction
 * Includes Immediate Default Position Pinning, Continuous Live GPS Tracking, 
 * Proximity Radar Alerts & Auto-Bounds Fitting
 */

let crewHazardMap = null;
let crewMarkersLayer = null;
let crewCirclesLayer = null;
let crewMarkerInstances = {};

// Live Location Tracking Variables
let crewLocationMarker = null;
let crewAccuracyCircle = null;
let isTrackingCrewLocation = true;
let crewWatchId = null;
let currentCrewAddress = "Survey Crew Position";
let currentCrewCoords = null;

// Upazilla coordinate centroids for instant centering across Bangladesh
const UPAZILLA_CENTROIDS = {
    'Khan Jahan Ali': [22.8988, 89.5010],
    'Gulshan': [23.8103, 90.4125],
    'Khulna Sadar': [22.8157, 89.5681],
    'Mirpur': [23.8223, 90.3654],
    'Dhanmondi': [23.7461, 90.3742],
    'Uttara': [23.8759, 90.3795],
    'Mohammadpur': [23.7658, 90.3584],
    'Badda': [23.7806, 90.4267],
    'Motijheel': [23.7330, 90.4172],
    'Chittagong Sadar': [22.3569, 91.7832],
    'Sylhet Sadar': [24.8949, 91.8687],
    'Rajshahi Sadar': [24.3745, 88.6042]
};

function initCrewMap() {
    const mapElement = document.getElementById('crew-hazard-map');
    if (!mapElement) return;

    if (crewHazardMap) {
        crewHazardMap.remove();
        crewHazardMap = null;
    }

    // Determine initial center based on crew's upazilla (Default to Khulna / KUET where defects are)
    const defaultCenter = UPAZILLA_CENTROIDS[CREW_CONFIG.upazilla] || [22.8988, 89.5010];

    crewHazardMap = L.map('crew-hazard-map', {
        center: defaultCenter,
        zoom: 15,
        zoomControl: true,
        scrollWheelZoom: true
    });

    // Base Layers
    const osmStandard = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; OpenStreetMap contributors'
    }).addTo(crewHazardMap);

    const esriSatellite = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
        maxZoom: 19,
        attribution: 'Tiles &copy; Esri Aerial Imagery'
    });

    L.control.layers({
        "🗺️ Standard Road Map": osmStandard,
        "🛰️ Satellite Imagery": esriSatellite
    }, null, { position: 'topright' }).addTo(crewHazardMap);

    crewCirclesLayer = L.layerGroup().addTo(crewHazardMap);
    crewMarkersLayer = L.layerGroup().addTo(crewHazardMap);

    if (window.ResizeObserver) {
        new ResizeObserver(() => crewHazardMap && crewHazardMap.invalidateSize()).observe(mapElement);
    }

    // 1. Immediately place Crew Live Location Marker with ZERO delay so the map is NEVER empty
    useDefaultCrewPosition();

    // 2. Then initiate continuous real GPS live tracking if browser permits
    initCrewLiveTracking();
}

/**
 * 1. Update Map Markers & Auto-Fit Bounds
 */
function updateCrewMapMarkers(reports) {
    if (!crewHazardMap || !crewMarkersLayer) return;

    crewMarkersLayer.clearLayers();
    crewCirclesLayer.clearLayers();
    crewMarkerInstances = {};

    const validLatLngs = [];

    (reports || []).forEach(report => {
        const lat = parseFloat(report.latitude);
        const lng = parseFloat(report.longitude);
        if (isNaN(lat) || isNaN(lng)) return;

        validLatLngs.push([lat, lng]);

        const sev = (report.severity || 'HIGH').toUpperCase();
        const status = (report.status || 'reported').toLowerCase();
        const isCritical = sev === 'CRITICAL' || sev === 'HIGH';
        const isMine = (report.assigned_crew_id === CREW_CONFIG.userId) || 
                       (report.assigned_crew && report.assigned_crew.toLowerCase().includes((CREW_CONFIG.userName || '').toLowerCase()));

        // Colors
        let pinColor = '#f59e0b'; // Amber / Medium
        if (status === 'resolved') pinColor = '#10b981'; // Green
        else if (status === 'under_repair') pinColor = '#0284c7'; // Sky Blue
        else if (sev === 'CRITICAL') pinColor = '#dc2626'; // Deep Red
        else if (sev === 'HIGH') pinColor = '#f43f5e'; // Rose
        else if (sev === 'LOW') pinColor = '#eab308'; // Yellow

        // Pulsing radar ring for High/Critical active defects
        if (isCritical && status !== 'resolved') {
            const circle = L.circleMarker([lat, lng], {
                radius: 20,
                color: pinColor,
                fillColor: pinColor,
                fillOpacity: 0.18,
                weight: 1.5,
                className: 'radar-ring'
            });
            crewCirclesLayer.addLayer(circle);
        }

        // Marker Icon
        const iconHtml = `
            <div style="position: relative; width: 34px; height: 34px; display: flex; align-items: center; justify-content: center;">
                <div style="
                    width: ${isMine ? '32px' : '28px'};
                    height: ${isMine ? '32px' : '28px'};
                    background-color: ${pinColor};
                    border: ${isMine ? '3px solid #1e293b' : '2.5px solid #ffffff'};
                    border-radius: 50%;
                    box-shadow: 0 4px 10px rgba(0,0,0,0.35);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    color: #ffffff;
                    font-size: 13px;
                    font-weight: bold;
                ">
                    ${isMine ? '👷' : (status === 'resolved' ? '✓' : '📍')}
                </div>
            </div>
        `;

        const customIcon = L.divIcon({
            html: iconHtml,
            className: 'crew-pin-icon',
            iconSize: [34, 34],
            iconAnchor: [17, 17],
            popupAnchor: [0, -18]
        });

        const marker = L.marker([lat, lng], { icon: customIcon });

        // Popup HTML
        const isVerified = (status === 'verified');
        const statusBadge = isVerified ? (currentAppLang === 'bn' ? 'যাচাইকৃত ও অনুমোদিত' : 'Verified & Approved') : (typeof translateStatus === 'function' ? translateStatus(status) : status.replace('_', ' '));
        const displayPhoto = (isVerified && report.repair_image_url) ? report.repair_image_url : (report.image_url || '');

        const popupHtml = `
            <div class="p-2.5 max-w-[270px] text-xs font-sans">
                <div class="flex items-center justify-between gap-2 mb-2 pb-1.5 border-b border-slate-100">
                    <span class="font-mono font-bold text-slate-800">${report.id}</span>
                    <span class="px-2 py-0.5 rounded text-[10px] font-bold ${isVerified ? 'bg-emerald-100 text-emerald-800' : ''}" style="${isVerified ? '' : `background:${pinColor}22; color:${pinColor}`}">
                        ${isVerified ? '✅ VERIFIED' : sev}
                    </span>
                </div>
                <div class="font-semibold text-slate-900 mb-1">
                    ${report.road_name || 'Survey Route Segment'}
                </div>
                <div class="text-[11px] text-slate-500 mb-2 font-mono">
                    ${lat.toFixed(5)}, ${lng.toFixed(5)}
                </div>
                ${displayPhoto ? `
                    <div class="w-full h-28 rounded-lg overflow-hidden mb-2 border ${isVerified ? 'border-emerald-500' : 'border-slate-200'} relative">
                        <img src="${displayPhoto}" class="w-full h-full object-cover">
                        ${isVerified ? `
                            <span class="absolute bottom-1 left-1 bg-emerald-600 text-white text-[9px] px-1.5 py-0.2 rounded font-bold">
                                ${currentAppLang === 'bn' ? 'মেরামতের ছবি' : 'Repaired Proof'}
                            </span>
                        ` : ''}
                    </div>
                ` : ''}
                ${isVerified ? `
                    <div class="p-2 rounded bg-emerald-50 border border-emerald-200 text-[10px] text-emerald-900 mb-2 space-y-0.5">
                        <div class="font-bold">🛡️ ${currentAppLang === 'bn' ? 'যাচাইকারী:' : 'Verified by:'} ${report.verified_by_name || 'Road Authority'}</div>
                        ${report.verified_at ? `<div>${currentAppLang === 'bn' ? 'তারিখ:' : 'Date:'} ${report.verified_at}</div>` : ''}
                    </div>
                ` : ''}
                <div class="flex items-center justify-between pt-1 text-[11px]">
                    <span class="text-slate-600 font-medium">Status: <strong>${statusBadge}</strong></span>
                    ${isMine && !isVerified ? `
                        <button onclick="openCrewRepairModal('${report.id}', false)" class="px-2 py-1 bg-amber-600 hover:bg-amber-700 text-white rounded font-bold text-[10px] transition cursor-pointer">
                            Update Status
                        </button>
                    ` : `
                        <span class="text-[10px] text-slate-400 font-bold flex items-center gap-1">
                            ${isVerified ? '✅ Closed' : '🔒 View Only'}
                        </span>
                    `}
                </div>
            </div>
        `;

        marker.bindPopup(popupHtml);
        crewMarkersLayer.addLayer(marker);
        crewMarkerInstances[report.id] = marker;
    });

    // Auto-fit bounds so all hazards AND the crew location marker are framed comfortably!
    if (validLatLngs.length > 0) {
        const bounds = L.latLngBounds(validLatLngs);
        if (currentCrewCoords) {
            bounds.extend(currentCrewCoords);
        }
        crewHazardMap.fitBounds(bounds, { padding: [45, 45], maxZoom: 16 });
    }

    // Refresh live distance to nearest hazard
    updateCrewNearestHazardDisplay();
}

/**
 * 2. Continuous Live Location GPS Tracking
 */
function initCrewLiveTracking() {
    if (!navigator.geolocation) {
        console.warn('Geolocation not supported by browser.');
        return;
    }

    // First attempt quick current position
    navigator.geolocation.getCurrentPosition(
        (pos) => {
            handleCrewLocationSuccess(pos.coords.latitude, pos.coords.longitude, pos.coords.accuracy || 25, false);
        },
        (err) => {
            console.warn('Initial browser geolocation prompt:', err);
        },
        { enableHighAccuracy: true, timeout: 8000, maximumAge: 10000 }
    );

    // Continuous Live Tracking
    try {
        if (crewWatchId !== null) navigator.geolocation.clearWatch(crewWatchId);
        crewWatchId = navigator.geolocation.watchPosition(
            (pos) => {
                if (isTrackingCrewLocation) {
                    handleCrewLocationSuccess(pos.coords.latitude, pos.coords.longitude, pos.coords.accuracy || 20, false);
                }
            },
            (err) => console.warn('Continuous GPS watch notification:', err),
            { enableHighAccuracy: true, timeout: 10000, maximumAge: 5000 }
        );
    } catch (e) {
        console.warn('Watch position error:', e);
    }
}

// Fallback to Upazilla Centroid or First Hazard Location
function useDefaultCrewPosition() {
    let center = UPAZILLA_CENTROIDS[CREW_CONFIG.upazilla];
    if (!center) {
        // Fallback to default KUET coordinates where active highway defects are located
        center = [22.8988, 89.5010];
    }
    handleCrewLocationSuccess(center[0], center[1], 35, true);
}

function handleCrewLocationSuccess(lat, lng, accuracy, isSimulated = false) {
    if (!crewHazardMap) return;

    currentCrewCoords = [lat, lng];
    currentCrewAddress = `${CREW_CONFIG.upazilla || 'Operations Area'}, ${CREW_CONFIG.district || 'Khulna'}`;

    // Create Pulsing Live Location Marker
    const liveIcon = L.divIcon({
        className: 'crew-live-pin-container',
        html: `
            <div class="marker-pin-authority">
                <div class="pulse"></div>
                <div class="core" style="background:#0284c7;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polygon points="3 11 22 2 13 21 11 13 3 11"/></svg>
                </div>
            </div>
        `,
        iconSize: [38, 38],
        iconAnchor: [19, 19],
        popupAnchor: [0, -20]
    });

    if (crewLocationMarker) crewHazardMap.removeLayer(crewLocationMarker);
    if (crewAccuracyCircle) crewHazardMap.removeLayer(crewAccuracyCircle);

    // Accuracy Circle
    crewAccuracyCircle = L.circle([lat, lng], {
        radius: Math.max(accuracy, 25),
        color: '#0284c7',
        fillColor: '#38bdf8',
        fillOpacity: 0.16,
        weight: 1.5,
        dashArray: '4, 6'
    }).addTo(crewHazardMap);

    const nearest = findNearestHazard(lat, lng);
    let nearestInfo = "Scanning road hazards...";
    if (nearest) {
        const distFormatted = nearest.distanceMeters < 1000 
            ? `${Math.round(nearest.distanceMeters)}m` 
            : `${(nearest.distanceMeters / 1000).toFixed(2)}km`;
        nearestInfo = `<strong>${distFormatted}</strong> away &bull; <span class="text-sky-700 font-bold">${nearest.report.id}</span> (${nearest.report.severity})`;
    }

    const popupContent = `
        <div class="p-3 bg-slate-900 text-white rounded-xl text-xs space-y-2 border border-sky-500/30 shadow-2xl min-w-[220px]">
            <div class="flex items-center gap-2 text-sky-400 font-bold text-sm">
                <span class="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-ping"></span>
                <span>${currentAppLang === 'bn' ? 'আমার লাইভ অবস্থান' : 'Crew Live Location'}</span>
            </div>
            <div class="text-slate-200 font-medium">
                ${CREW_CONFIG.userName} &bull; ${CREW_CONFIG.upazilla}
            </div>
            <div class="text-[11px] text-slate-400 font-mono">
                ${lat.toFixed(5)}, ${lng.toFixed(5)} &bull; &plusmn;${Math.round(accuracy)}m
            </div>
            <div class="mt-2 pt-2 border-t border-slate-800 text-[11px] text-slate-300">
                <span class="text-slate-400 block mb-0.5">${currentAppLang === 'bn' ? 'নিকটবর্তী সড়ক ঝুঁকি:' : 'Nearest Road Defect:'}</span>
                ${nearestInfo}
            </div>
            <div class="text-[10px] text-slate-400 italic pt-1">
                Tip: You can drag this blue pin along the highway.
            </div>
        </div>
    `;

    crewLocationMarker = L.marker([lat, lng], { 
        icon: liveIcon, 
        zIndexOffset: 3000,
        draggable: true 
    })
    .addTo(crewHazardMap)
    .bindPopup(popupContent);

    crewLocationMarker.on('dragend', function (e) {
        const newPos = e.target.getLatLng();
        handleCrewLocationSuccess(newPos.lat, newPos.lng, 15, false);
    });

    updateCrewNearestHazardDisplay();
}

/**
 * 3. Calculate Distance & Nearest Hazard
 */
function calculateDistanceMeters(lat1, lon1, lat2, lon2) {
    const R = 6371e3; // Earth radius in meters
    const phi1 = lat1 * Math.PI / 180;
    const phi2 = lat2 * Math.PI / 180;
    const deltaPhi = (lat2 - lat1) * Math.PI / 180;
    const deltaLambda = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
              Math.cos(phi1) * Math.cos(phi2) *
              Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
}

function findNearestHazard(lat, lng) {
    const list = window.allCrewReports || [];
    if (list.length === 0) return null;

    let nearest = null;
    let minDistance = Infinity;

    list.forEach(r => {
        const rLat = parseFloat(r.latitude);
        const rLng = parseFloat(r.longitude);
        if (isNaN(rLat) || isNaN(rLng)) return;

        const dist = calculateDistanceMeters(lat, lng, rLat, rLng);
        if (dist < minDistance) {
            minDistance = dist;
            nearest = { report: r, distanceMeters: dist };
        }
    });

    return nearest;
}

function updateCrewNearestHazardDisplay() {
    const chip = document.getElementById('crew-location-chip');
    if (!chip) return;

    if (!currentCrewCoords) {
        chip.classList.add('hidden');
        return;
    }

    const nearest = findNearestHazard(currentCrewCoords[0], currentCrewCoords[1]);
    let nearestText = currentAppLang === 'bn' ? 'কোন ঝুঁকি সনাক্ত হয়নি' : 'No defects detected nearby';
    
    if (nearest) {
        const distFormatted = nearest.distanceMeters < 1000 
            ? `${Math.round(nearest.distanceMeters)}m` 
            : `${(nearest.distanceMeters / 1000).toFixed(2)} km`;
        
        nearestText = currentAppLang === 'bn'
            ? `নিকটবর্তী ত্রুটি: <strong class="text-rose-600 font-mono">${nearest.report.id}</strong> (${distFormatted} দূরে &bull; ${translateDefectSeverity(nearest.report.severity)})`
            : `Nearest Pothole: <strong class="text-rose-600 font-mono">${nearest.report.id}</strong> (${distFormatted} away &bull; ${nearest.report.severity})`;
    }

    chip.classList.remove('hidden');
    chip.classList.add('flex');
    chip.innerHTML = `
        <span class="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse shrink-0"></span>
        <span class="truncate">
            <strong>${currentAppLang === 'bn' ? 'লাইভ জিপিএস অবস্থান:' : 'Live Crew GPS:'}</strong> ${currentCrewAddress} (${currentCrewCoords[0].toFixed(5)}, ${currentCrewCoords[1].toFixed(5)}) &bull; ${nearestText}
        </span>
    `;
}

/**
 * 4. User Controls: Locate Me, Center Upazilla, Toggle Tracking
 */
function locateCrewPosition() {
    if (!crewHazardMap) return;
    if (currentCrewCoords) {
        crewHazardMap.flyTo(currentCrewCoords, 17, { animate: true, duration: 0.8 });
        if (crewLocationMarker) crewLocationMarker.openPopup();
    } else {
        useDefaultCrewPosition();
        initCrewLiveTracking();
    }
}

function centerCrewUpazillaMap() {
    if (!crewHazardMap) return;
    const center = UPAZILLA_CENTROIDS[CREW_CONFIG.upazilla] || [22.8988, 89.5010];
    crewHazardMap.flyTo(center, 15, { animate: true, duration: 0.8 });
}

function toggleCrewLiveTracking() {
    const btn = document.getElementById('crew-track-btn');
    const textEl = document.getElementById('crew-track-text');

    if (isTrackingCrewLocation) {
        isTrackingCrewLocation = false;
        if (btn) {
            btn.className = "px-3 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-500 text-xs font-bold flex items-center gap-1.5 transition cursor-pointer border border-slate-200";
            if (textEl) textEl.textContent = "Live GPS: OFF";
        }
        if (crewWatchId !== null) {
            navigator.geolocation.clearWatch(crewWatchId);
            crewWatchId = null;
        }
    } else {
        isTrackingCrewLocation = true;
        if (btn) {
            btn.className = "px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold flex items-center gap-1.5 transition cursor-pointer shadow-xs";
            if (textEl) textEl.textContent = "Live GPS: Active";
        }
        initCrewLiveTracking();
    }
}

/**
 * 5. Fly directly to a specific report on table click (Live Map Navigation)
 */
function flyToCrewReport(reportId) {
    if (!crewHazardMap) return;

    let marker = crewMarkerInstances[reportId];
    let latLng = null;

    if (marker) {
        latLng = marker.getLatLng();
    } else {
        const rep = (window.allCrewReports || []).find(x => x.id === reportId);
        if (rep && rep.latitude && rep.longitude) {
            latLng = [parseFloat(rep.latitude), parseFloat(rep.longitude)];
        }
    }

    if (latLng) {
        const mapSection = document.getElementById('crew-gis-section');
        if (mapSection) {
            const headerHeight = document.querySelector('header')?.offsetHeight || 100;
            const elementPosition = mapSection.getBoundingClientRect().top;
            const offsetPosition = elementPosition + window.pageYOffset - headerHeight - 16;
            window.scrollTo({
                top: offsetPosition,
                behavior: 'smooth'
            });
        }

        crewHazardMap.flyTo(latLng, 17.5, { animate: true, duration: 0.9 });

        setTimeout(() => {
            if (marker) marker.openPopup();
            lucide.createIcons();
        }, 950);
    }
}
