/**
 * Leaflet GIS Interactive Map Logic - Powered by OpenStreetMap (OSM) APIs
 * Features:
 * - 100% Free OpenStreetMap Standard & Humanitarian (HOT) Tile APIs
 * - OpenStreetMap Nominatim Reverse Geocoding API (Real Street & Highway Resolution)
 * - OpenStreetMap Nominatim Forward Search API (Street & City Navigation)
 * - Interactive Pin Relocation: Drag pin or "Click on Map to Set Location"
 * - High-Accuracy Browser GPS + Network Fallback + LocalStorage Memory
 * - Non-disruptive Zoom & View Management
 */

let hazardMap = null;
let markersLayer = null;
let circlesLayer = null;
let osmSearchLayer = null;
let currentReportsData = [];
const markerInstances = {};

// In-memory cache for OpenStreetMap Nominatim API lookups
const osmAddressCache = {};

// Zoom and view management state
let hasInitialViewSet = false;
let userHasInteracted = false;

// Interactive Click-to-Pin Mode State
let isPinningLocationMode = false;

// Authority / Live Location State
let authorityMarker = null;
let authorityCircle = null;
let authorityWatchId = null;
let isTrackingAuthority = false;
let currentAuthorityLat = null;
let currentAuthorityLng = null;
let currentAuthorityAccuracy = 25;
let currentAuthoritySource = 'Default Operations Hub';
let currentAuthorityAddress = 'Resolving via OpenStreetMap...';

/**
 * 1. Initialize Leaflet Map with OpenStreetMap Tile APIs
 */
function initHazardMap(defaultLat = 22.8985, defaultLng = 89.5003, zoom = 15) {
    const mapElement = document.getElementById('hazard-map');
    if (!mapElement) return;

    if (hazardMap) {
        hazardMap.remove();
        hazardMap = null;
    }

    // Check if user previously pinned a custom location
    const savedPin = getSavedCustomPosition();
    const initialLat = savedPin ? savedPin.lat : defaultLat;
    const initialLng = savedPin ? savedPin.lng : defaultLng;

    // Initialize Map with resilient zoom parameters
    hazardMap = L.map('hazard-map', {
        zoomControl: true,
        scrollWheelZoom: true,
        touchZoom: true,
        doubleClickZoom: true,
        boxZoom: true,
        minZoom: 5,
        maxZoom: 19,
        zoomSnap: 0.5,
        zoomDelta: 1
    }).setView([initialLat, initialLng], zoom);

    hazardMap.on('zoomstart movestart', () => {
        userHasInteracted = true;
    });

    // Click handler on map for "Pin Exact Location" mode
    hazardMap.on('click', async (e) => {
        if (isPinningLocationMode) {
            const lat = e.latlng.lat;
            const lng = e.latlng.lng;
            saveCustomPosition(lat, lng);
            togglePinLocationMode(false);
            await handleLocationSuccess(lat, lng, 10, true, 'Manually Pinned Spot');
            if (typeof showToast === 'function') {
                showToast('✓ Set your live location to the clicked spot.');
            }
        }
    });

    // 2. OpenStreetMap Tile APIs (Free, Open, No API Key Required)
    const osmStandard = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors'
    }).addTo(hazardMap);

    const osmHot = L.tileLayer('https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, <a href="https://www.hotosm.org/" target="_blank">HOT</a>'
    });

    const osmCyclo = L.tileLayer('https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> & <a href="https://www.cyclosm.org/">CyclOSM</a>'
    });

    const esriSatellite = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
        maxZoom: 19,
        attribution: 'Tiles &copy; Esri &mdash; Aerial Imagery'
    });

    // Base Layer Switcher (Top Right)
    const baseLayers = {
        "🗺️ OpenStreetMap (Standard)": osmStandard,
        "🛣️ OpenStreetMap (Humanitarian / HOT)": osmHot,
        "🚲 OpenStreetMap (Roads & Highways)": osmCyclo,
        "🛰️ Satellite Aerial Reference": esriSatellite
    };
    L.control.layers(baseLayers, null, { position: 'topright' }).addTo(hazardMap);

    // 3. Layer Groups
    circlesLayer = L.layerGroup().addTo(hazardMap);
    markersLayer = L.layerGroup().addTo(hazardMap);
    osmSearchLayer = L.layerGroup().addTo(hazardMap);

    // 4. Container Resize Observer
    if (window.ResizeObserver) {
        const resizeObserver = new ResizeObserver(() => {
            if (hazardMap) {
                hazardMap.invalidateSize();
            }
        });
        resizeObserver.observe(mapElement);
    }

    setTimeout(() => {
        if (hazardMap) {
            hazardMap.invalidateSize();
        }
    }, 200);

    // 5. Connect OpenStreetMap Search Enter-key listener
    const osmSearchInput = document.getElementById('osm-street-search');
    if (osmSearchInput) {
        osmSearchInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                e.preventDefault();
                searchOsmStreet();
            }
        });
    }

    // 6. Automatically initiate Live Location Acquisition
    if (savedPin) {
        handleLocationSuccess(savedPin.lat, savedPin.lng, 15, true, 'Saved Custom Pin');
    } else {
        acquireLiveLocation(true);
    }
}

/**
 * Custom Position LocalStorage Helpers
 */
function getSavedCustomPosition() {
    try {
        const raw = localStorage.getItem('authority_pinned_pos');
        if (raw) {
            const p = JSON.parse(raw);
            if (p && !isNaN(p.lat) && !isNaN(p.lng)) return p;
        }
    } catch (e) {}
    return null;
}

function saveCustomPosition(lat, lng) {
    try {
        localStorage.setItem('authority_pinned_pos', JSON.stringify({ lat, lng, time: Date.now() }));
    } catch (e) {}
}

/**
 * Toggle "Click on Map to Set Location" mode
 */
function togglePinLocationMode(forceState = null) {
    const mapElement = document.getElementById('hazard-map');
    const btn = document.getElementById('btn-pin-authority');
    const btnText = document.getElementById('btn-pin-authority-text');
    const statusBox = document.getElementById('authority-location-chip');

    if (forceState !== null) {
        isPinningLocationMode = forceState;
    } else {
        isPinningLocationMode = !isPinningLocationMode;
    }

    if (isPinningLocationMode) {
        if (mapElement) mapElement.style.cursor = 'crosshair';
        if (btn) {
            btn.className = "px-3.5 py-1.5 rounded-xl bg-amber-500 text-xs font-bold text-slate-950 transition flex items-center gap-1.5 border-2 border-white shadow-lg shadow-amber-500/50 animate-pulse";
        }
        if (btnText) btnText.textContent = "Click on Map Now...";

        if (statusBox) {
            statusBox.classList.remove('hidden');
            statusBox.classList.add('flex');
            statusBox.innerHTML = `
                <span class="w-2.5 h-2.5 rounded-full bg-amber-400 animate-ping"></span>
                <span class="font-bold text-amber-200">Interactive Pinning Active:</span>
                <span class="text-white">Click anywhere on the map or your exact street to place your live location.</span>
                <button onclick="togglePinLocationMode(false)" class="ml-2 px-2 py-0.5 rounded bg-slate-800 text-[10px] text-slate-300 border border-slate-700">Cancel</button>
            `;
        }
    } else {
        if (mapElement) mapElement.style.cursor = '';
        if (btn) {
            btn.className = "px-3.5 py-1.5 rounded-xl bg-amber-600/90 hover:bg-amber-500 text-xs font-bold text-white transition flex items-center gap-1.5 shadow-lg shadow-amber-600/20";
        }
        if (btnText) btnText.textContent = "Pin Exact Location";
        updateNearestHazardDisplay();
    }
}

/**
 * Set authority location directly from an OpenStreetMap search result
 */
async function setAuthorityFromOsm(lat, lng, addressLabel) {
    saveCustomPosition(lat, lng);
    currentAuthorityAddress = addressLabel;
    await handleLocationSuccess(lat, lng, 15, true, 'OpenStreetMap Landmark');
    if (hazardMap) {
        hazardMap.flyTo([lat, lng], 16, { animate: true, duration: 0.8 });
    }
    if (typeof showToast === 'function') {
        showToast('✓ Set your location to ' + addressLabel);
    }
}

/**
 * =============================================================================
 * OpenStreetMap Nominatim Reverse Geocoding API
 * Resolves exact street name, road, and neighborhood from OpenStreetMap
 * =============================================================================
 */
async function fetchOsmAddress(lat, lng) {
    const key = `${lat.toFixed(4)},${lng.toFixed(4)}`;
    if (osmAddressCache[key]) {
        return osmAddressCache[key];
    }

    try {
        const url = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${lat}&lon=${lng}`;
        const response = await fetch(url, {
            headers: { 'Accept': 'application/json' }
        });
        if (!response.ok) return null;

        const data = await response.json();
        if (data && data.address) {
            const addr = data.address;
            const road = addr.road || addr.highway || addr.street || addr.neighbourhood || addr.suburb || '';
            const area = addr.suburb || addr.city_district || addr.county || addr.town || addr.city || '';
            const state = addr.state_district || addr.state || '';

            const parts = [road, area, state].filter(Boolean);
            const formatted = parts.length > 0 ? parts.join(', ') : (data.display_name?.split(',').slice(0, 3).join(',') || 'OpenStreetMap Verified Road');

            osmAddressCache[key] = formatted;
            return formatted;
        }
    } catch (e) {
        console.warn('OpenStreetMap Nominatim reverse geocoding warning:', e);
    }
    return null;
}

/**
 * =============================================================================
 * OpenStreetMap Nominatim Search API
 * Forward-geocodes road, highway, or city queries in Bangladesh
 * =============================================================================
 */
async function searchOsmStreet() {
    const input = document.getElementById('osm-street-search');
    const statusBox = document.getElementById('osm-search-status');
    if (!input || !input.value.trim()) return;

    const query = input.value.trim();
    if (statusBox) {
        statusBox.classList.remove('hidden');
        statusBox.innerHTML = `<span class="text-indigo-400">Searching OpenStreetMap for "${query}"...</span>`;
    }

    try {
        const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&countrycodes=bd&limit=5`;
        const resp = await fetch(url);
        const results = await resp.json();

        if (results && results.length > 0) {
            const topMatch = results[0];
            const lat = parseFloat(topMatch.lat);
            const lon = parseFloat(topMatch.lon);

            userHasInteracted = true;
            hazardMap.flyTo([lat, lon], 16, { animate: true, duration: 1.0 });

            // Render search highlight pin with 1-click "Set as My Live Location" button
            if (osmSearchLayer) osmSearchLayer.clearLayers();
            const searchIcon = L.divIcon({
                className: 'custom-search-marker',
                html: `
                    <div style="
                        width: 32px; height: 32px; border-radius: 50%; 
                        background: #4f46e5; border: 3px solid #ffffff; 
                        box-shadow: 0 4px 14px rgba(79, 70, 229, 0.7);
                        display: flex; align-items: center; justify-content: center; color: white;
                    ">
                        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
                    </div>
                `,
                iconSize: [32, 32],
                iconAnchor: [16, 16],
                popupAnchor: [0, -18]
            });

            const escapedName = (topMatch.display_name || '').replace(/'/g, "\\'");
            const searchMarker = L.marker([lat, lon], { icon: searchIcon })
                .bindPopup(`
                    <div class="p-3 bg-white text-slate-800 rounded-xl text-xs space-y-2 max-w-[260px] border border-slate-100 shadow-md">
                        <span class="text-sky-700 font-bold block text-sm">OpenStreetMap Match</span>
                        <p class="text-slate-600">${topMatch.display_name}</p>
                        <div class="pt-1">
                            <button onclick="setAuthorityFromOsm(${lat}, ${lon}, '${escapedName}')" class="w-full py-1.5 px-3 rounded-lg bg-sky-600 hover:bg-sky-500 text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-sm transition">
                                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polygon points="3 11 22 2 13 21 11 13 3 11"/></svg>
                                <span>Set as My Live Location</span>
                            </button>
                        </div>
                    </div>
                `)
                .addTo(osmSearchLayer);

            setTimeout(() => searchMarker.openPopup(), 1050);

            if (statusBox) {
                statusBox.innerHTML = `<span class="text-emerald-400 font-bold">✓ OpenStreetMap: Found ${topMatch.name || query}</span>`;
            }
        } else {
            if (statusBox) {
                statusBox.innerHTML = `<span class="text-amber-400">No matching streets found on OpenStreetMap in Bangladesh.</span>`;
            }
        }
    } catch (err) {
        if (statusBox) {
            statusBox.innerHTML = `<span class="text-rose-400">OpenStreetMap API error: ${err.message}</span>`;
        }
    }
}

/**
 * Severity Color Helper
 */
function getSeverityColor(severity, isResolved = false) {
    if (isResolved) return '#10b981';
    switch ((severity || '').toUpperCase()) {
        case 'CRITICAL': return '#dc2626';
        case 'HIGH':     return '#f43f5e';
        case 'MEDIUM':   return '#f97316';
        case 'LOW':      return '#eab308';
        default:         return '#6366f1';
    }
}

/**
 * Custom Pin Marker Icons
 */
function createCustomPin(severity, isResolved = false) {
    const color = getSeverityColor(severity, isResolved);
    const isUrgent = !isResolved && (severity.toUpperCase() === 'HIGH' || severity.toUpperCase() === 'CRITICAL');

    if (isUrgent) {
        return L.divIcon({
            className: 'custom-leaflet-marker',
            html: `
                <div class="marker-pin-critical">
                    <div class="pulse" style="background: ${color}66;"></div>
                    <div class="core" style="background: ${color};"></div>
                </div>
            `,
            iconSize: [34, 34],
            iconAnchor: [17, 17],
            popupAnchor: [0, -18]
        });
    }

    return L.divIcon({
        className: 'custom-leaflet-marker',
        html: `
            <div style="
                width: 22px;
                height: 22px;
                border-radius: 50%;
                background: ${color};
                border: 3px solid #ffffff;
                box-shadow: 0 4px 10px rgba(0,0,0,0.6);
            "></div>
        `,
        iconSize: [22, 22],
        iconAnchor: [11, 11],
        popupAnchor: [0, -14]
    });
}

/**
 * 2. Render Pothole Markers & Hazard Circles on the Map
 */
function updateMapMarkers(reports) {
    if (!hazardMap || !markersLayer || !circlesLayer) return;

    markersLayer.clearLayers();
    circlesLayer.clearLayers();
    currentReportsData = reports;

    const bounds = [];

    reports.forEach(report => {
        const lat = parseFloat(report.latitude);
        const lng = parseFloat(report.longitude);
        if (isNaN(lat) || isNaN(lng)) return;

        bounds.push([lat, lng]);

        const isResolved = report.status === 'resolved';
        const color = getSeverityColor(report.severity, isResolved);

        const radiusMeters = report.severity === 'CRITICAL' ? 35 : (report.severity === 'HIGH' ? 25 : 18);
        const circle = L.circle([lat, lng], {
            radius: radiusMeters,
            color: color,
            fillColor: color,
            fillOpacity: isResolved ? 0.15 : 0.28,
            weight: 2,
            dashArray: isResolved ? '4, 4' : null
        });
        circlesLayer.addLayer(circle);

        const pinIcon = createCustomPin(report.severity, isResolved);
        const marker = L.marker([lat, lng], { icon: pinIcon });
        const osmDirectUrl = `https://www.openstreetmap.org/?mlat=${lat}&mlon=${lng}#map=18/${lat}/${lng}`;

        const popupHtml = `
            <div class="w-68 overflow-hidden rounded-xl bg-white text-slate-800 text-xs shadow-md border border-slate-100">
                <div class="relative h-28 bg-slate-100 overflow-hidden">
                    <img src="${report.image_url || 'uploads/potholes/rpt-1792217799588.jpg'}" 
                         alt="Pothole" 
                         class="w-full h-full object-cover"
                         onerror="this.src='uploads/potholes/rpt-1792217799588.jpg'">
                    <span class="absolute top-2 right-2 px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider ${getSeverityBadgeClass(report.severity)}">
                        ${report.severity}
                    </span>
                    <span class="absolute bottom-2 left-2 px-2 py-0.5 rounded bg-slate-900/80 backdrop-blur text-[10px] text-white font-mono">
                        ${report.confidence_pct || Math.round(report.confidence * 100)}% Conf.
                    </span>
                </div>
                <div class="p-3 space-y-2">
                    <div class="flex items-center justify-between">
                        <span class="font-bold text-slate-900">${report.id}</span>
                        <span class="capitalize text-[10px] px-1.5 py-0.5 rounded bg-slate-100 text-slate-700 border border-slate-200">
                            ${typeof translateStatus === 'function' ? translateStatus(report.status) : (report.status || 'reported').replace('_', ' ')}
                        </span>
                    </div>
                    <p class="text-slate-600 font-medium" id="osm-road-${report.id}">${report.road_name || 'OpenStreetMap Road Survey Location'}</p>
                    <div class="flex items-center justify-between text-[11px] text-slate-500 pt-2 border-t border-slate-100">
                        <a href="${osmDirectUrl}" target="_blank" class="text-sky-600 hover:text-sky-700 font-semibold flex items-center gap-1">
                            <span>OpenStreetMap</span>
                            <span>↗</span>
                        </a>
                        <button onclick="openInspectionModal('${report.id}')" class="text-sky-700 hover:text-sky-900 font-bold underline cursor-pointer">
                            ${typeof t === 'function' ? t('popup_inspect') : 'Inspect &rarr;'}
                        </button>
                    </div>
                </div>
            </div>
        `;

        marker.bindPopup(popupHtml, { maxWidth: 290 });

        marker.on('popupopen', async () => {
            const roadEl = document.getElementById(`osm-road-${report.id}`);
            if (roadEl) {
                const osmResolved = await fetchOsmAddress(lat, lng);
                if (osmResolved) {
                    roadEl.textContent = osmResolved;
                }
            }
        });

        markersLayer.addLayer(marker);
        markerInstances[report.id] = marker;
    });

    if (!hasInitialViewSet && !userHasInteracted && !getSavedCustomPosition()) {
        if (bounds.length > 0) {
            fitAllHazardsOnMap(false);
            hasInitialViewSet = true;
        }
    }

    if (currentAuthorityLat && currentAuthorityLng) {
        updateNearestHazardDisplay();
    }
}

/**
 * 3. Fit All Hazards on Map
 */
function fitAllHazardsOnMap(animate = true) {
    if (!hazardMap || !currentReportsData || currentReportsData.length === 0) {
        if (authorityMarker) {
            hazardMap.setView(authorityMarker.getLatLng(), 15);
        }
        return;
    }

    const bounds = [];
    currentReportsData.forEach(r => {
        const lat = parseFloat(r.latitude);
        const lng = parseFloat(r.longitude);
        if (!isNaN(lat) && !isNaN(lng)) {
            bounds.push([lat, lng]);
        }
    });

    if (bounds.length === 0) return;

    if (bounds.length === 1) {
        if (animate) {
            hazardMap.flyTo(bounds[0], 16, { animate: true, duration: 0.8 });
        } else {
            hazardMap.setView(bounds[0], 16);
        }
    } else {
        hazardMap.fitBounds(bounds, {
            padding: [50, 50],
            maxZoom: 16,
            animate: animate
        });
    }
}

/**
 * 4. Fly directly to a specific report
 */
function flyToReport(reportId) {
    const marker = markerInstances[reportId];
    if (marker && hazardMap) {
        const latLng = marker.getLatLng();
        userHasInteracted = true;
        hazardMap.flyTo(latLng, 17, { animate: true, duration: 0.8 });
        setTimeout(() => {
            marker.openPopup();
        }, 850);
    }
}

function flyToUpazillaLocation(lat, lng, upazillaName) {
    if (!hazardMap || !lat || !lng) return;
    userHasInteracted = true;
    hazardMap.flyTo([lat, lng], 14.5, { animate: true, duration: 1.0 });
    const mapSection = document.getElementById('hazard-map');
    if (mapSection) {
        mapSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
    if (typeof showToast === 'function') {
        showToast('📍 Focused GIS Map on ' + upazillaName + ' Upazilla cluster.');
    }
}

function getSeverityBadgeClass(severity) {
    switch ((severity || '').toUpperCase()) {
        case 'CRITICAL': return 'bg-rose-50 text-rose-700 border border-rose-200';
        case 'HIGH':     return 'bg-rose-50 text-rose-600 border border-rose-200';
        case 'MEDIUM':   return 'bg-amber-50 text-amber-700 border border-amber-200';
        case 'LOW':      return 'bg-yellow-50 text-yellow-800 border border-yellow-200';
        default:         return 'bg-slate-100 text-slate-700 border border-slate-200';
    }
}

/**
 * =============================================================================
 * Authority Live Location Engine (Device GPS + Wi-Fi Triangulation + Network Fallback)
 * =============================================================================
 */

function locateAuthorityOnMap(shouldFollow = true) {
    acquireLiveLocation(shouldFollow);
}

async function acquireLiveLocation(shouldCenter = true) {
    const btn = document.getElementById('btn-locate-authority');
    if (btn) {
        btn.innerHTML = `<i data-lucide="loader" class="w-3.5 h-3.5 animate-spin"></i><span>Acquiring Live GPS...</span>`;
        if (window.lucide) lucide.createIcons();
    }

    // Check if browser context is secure for GPS
    const isSecure = window.isSecureContext || location.hostname === 'localhost' || location.hostname === '127.0.0.1';

    // Phase 1: High Accuracy Browser GPS with 12s timeout
    if (navigator.geolocation && isSecure) {
        navigator.geolocation.getCurrentPosition(
            async (pos) => {
                saveCustomPosition(pos.coords.latitude, pos.coords.longitude);
                await handleLocationSuccess(pos.coords.latitude, pos.coords.longitude, pos.coords.accuracy || 20, shouldCenter, 'Device Hardware GPS');
            },
            (err) => {
                console.warn('High accuracy GPS timed out, trying Phase 2 (Wi-Fi):', err.message);
                navigator.geolocation.getCurrentPosition(
                    async (pos2) => {
                        saveCustomPosition(pos2.coords.latitude, pos2.coords.longitude);
                        await handleLocationSuccess(pos2.coords.latitude, pos2.coords.longitude, pos2.coords.accuracy || 50, shouldCenter, 'Network Location (Wi-Fi)');
                    },
                    (err2) => {
                        console.warn('Browser geolocation failed:', err2.message);
                        handleFallbackLocation(shouldCenter);
                    },
                    { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 }
                );
            },
            { enableHighAccuracy: true, timeout: 12000, maximumAge: 5000 }
        );
    } else {
        handleFallbackLocation(shouldCenter);
    }
}

async function handleFallbackLocation(shouldCenter = true) {
    // 1. Check if user already pinned a location
    const savedPin = getSavedCustomPosition();
    if (savedPin) {
        await handleLocationSuccess(savedPin.lat, savedPin.lng, 15, shouldCenter, 'Saved Custom Pin');
        return;
    }

    // 2. Fallback to KUET Campus / Khulna Division default center (22.8996, 89.5024)
    await handleLocationSuccess(22.8996, 89.5024, 100, shouldCenter, 'KUET Campus Area');
}

async function handleLocationSuccess(lat, lng, accuracy, shouldCenter, sourceName) {
    currentAuthorityLat = lat;
    currentAuthorityLng = lng;
    currentAuthorityAccuracy = accuracy;
    currentAuthoritySource = sourceName;

    // Resolve street address from OpenStreetMap Nominatim API
    const osmStreet = await fetchOsmAddress(lat, lng);
    currentAuthorityAddress = osmStreet || `${lat.toFixed(5)}, ${lng.toFixed(5)}`;

    renderAuthorityPosition(lat, lng, accuracy, shouldCenter, sourceName);

    const btn = document.getElementById('btn-locate-authority');
    if (btn) {
        btn.innerHTML = `<i data-lucide="navigation-2" class="w-3.5 h-3.5 text-sky-400"></i><span>My Location Active</span>`;
        btn.className = "px-3.5 py-1.5 rounded-xl bg-sky-950/80 hover:bg-sky-900/80 text-xs font-semibold text-sky-300 transition flex items-center gap-1.5 border border-sky-600 shadow-lg shadow-sky-900/20";
        if (window.lucide) lucide.createIcons();
    }
}

function renderAuthorityPosition(lat, lng, accuracy = 25, shouldCenter = false, sourceName = 'Live Location') {
    if (!hazardMap) return;

    const authorityIcon = L.divIcon({
        className: 'custom-authority-marker',
        html: `
            <div class="marker-pin-authority">
                <div class="pulse"></div>
                <div class="core">
                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polygon points="3 11 22 2 13 21 11 13 3 11"/></svg>
                </div>
            </div>
        `,
        iconSize: [38, 38],
        iconAnchor: [19, 19],
        popupAnchor: [0, -20]
    });

    if (authorityMarker) hazardMap.removeLayer(authorityMarker);
    if (authorityCircle) hazardMap.removeLayer(authorityCircle);

    // Accuracy Circle
    authorityCircle = L.circle([lat, lng], {
        radius: Math.max(accuracy, 20),
        color: '#0284c7',
        fillColor: '#38bdf8',
        fillOpacity: 0.15,
        weight: 1.5,
        dashArray: '4, 6'
    }).addTo(hazardMap);

    const nearest = findNearestPothole(lat, lng);
    let nearestInfo = "No nearby road hazards recorded.";
    if (nearest) {
        const distFormatted = nearest.distanceMeters < 1000 
            ? `${Math.round(nearest.distanceMeters)} meters` 
            : `${(nearest.distanceMeters / 1000).toFixed(2)} km`;
        nearestInfo = `<strong>${distFormatted}</strong> away &bull; <span class="text-indigo-400 font-bold">${nearest.report.id}</span> (${nearest.report.severity})`;
    }

    const osmDirectUrl = `https://www.openstreetmap.org/?mlat=${lat}&mlon=${lng}#map=17/${lat}/${lng}`;

    const popupContent = `
        <div class="p-3 bg-slate-900 text-white rounded-xl text-xs space-y-2 border border-sky-500/30 shadow-2xl min-w-[240px]">
            <div class="flex items-center gap-2 text-sky-400 font-bold text-sm">
                <span class="w-2.5 h-2.5 rounded-full bg-sky-400 animate-ping"></span>
                <span>My Live Location</span>
            </div>
            <div class="text-slate-200 font-medium">
                ${currentAuthorityAddress}
            </div>
            <div class="text-[11px] text-slate-400">
                Source: <span class="text-white">${sourceName}</span> &bull; &plusmn;${Math.round(accuracy)}m
            </div>
            <div class="mt-2 pt-2 border-t border-slate-800 text-[11px] text-slate-300">
                <span class="text-slate-400 block mb-0.5">Nearest Detected Hazard:</span>
                ${nearestInfo}
            </div>
            <div class="pt-1.5 flex items-center justify-between border-t border-slate-800 text-[11px]">
                <span class="text-amber-400 font-medium">💡 Drag pin to relocate</span>
                <a href="${osmDirectUrl}" target="_blank" class="text-sky-400 hover:text-sky-300 underline font-semibold">
                    OpenStreetMap ↗
                </a>
            </div>
        </div>
    `;

    authorityMarker = L.marker([lat, lng], { 
        icon: authorityIcon, 
        zIndexOffset: 3000,
        draggable: true 
    })
    .addTo(hazardMap)
    .bindTooltip(`📍 ${currentAuthorityAddress.split(',')[0]} (Drag to move)`, { 
        permanent: true, 
        direction: "top", 
        className: "authority-map-tooltip",
        offset: [0, -18]
    })
    .bindPopup(popupContent, { maxWidth: 320 });

    // Drag support to freely place pin exactly on user's road/building
    authorityMarker.on('dragend', async function(e) {
        const newPos = e.target.getLatLng();
        saveCustomPosition(newPos.lat, newPos.lng);
        currentAuthorityLat = newPos.lat;
        currentAuthorityLng = newPos.lng;
        const osmNew = await fetchOsmAddress(newPos.lat, newPos.lng);
        currentAuthorityAddress = osmNew || `${newPos.lat.toFixed(5)}, ${newPos.lng.toFixed(5)}`;
        renderAuthorityPosition(newPos.lat, newPos.lng, 10, false, 'Custom Pinned Location');
        if (typeof showToast === 'function') {
            showToast('✓ Updated location to: ' + currentAuthorityAddress);
        }
    });

    updateNearestHazardDisplay();

    if (shouldCenter) {
        userHasInteracted = true;
        hazardMap.flyTo([lat, lng], 16, { animate: true, duration: 0.8 });
    }
}

function updateNearestHazardDisplay() {
    if (!currentAuthorityLat || !currentAuthorityLng) return;

    const nearest = findNearestPothole(currentAuthorityLat, currentAuthorityLng);
    const statusBox = document.getElementById('authority-location-chip');
    if (!statusBox) return;

    let nearestText = typeof t === "function" ? t("map_scanning_hazards") : "Scanning road hazards...";
    if (nearest) {
        const distFormatted = nearest.distanceMeters < 1000 
            ? `${Math.round(nearest.distanceMeters)}m` 
            : `${(nearest.distanceMeters / 1000).toFixed(2)}km`;
        nearestText = `${typeof t === "function" ? t("map_nearest") : "Nearest:"} <strong class="text-indigo-300">${nearest.report.id}</strong> (${distFormatted})`;
    }

    statusBox.classList.remove('hidden');
    statusBox.classList.add('flex');
    statusBox.innerHTML = `
        <span class="w-2.5 h-2.5 rounded-full bg-sky-500 animate-pulse"></span>
        <span class="truncate">${typeof t === "function" ? t("map_live_position") : "Live Position:"} <strong class="text-slate-900">${currentAuthorityAddress}</strong> &bull; ${nearestText}</span>
    `;
}

function toggleAuthorityLiveTracking() {
    const trackBtn = document.getElementById('btn-track-authority');
    if (!navigator.geolocation) {
        alert('Browser Geolocation is not supported on this platform.');
        return;
    }

    if (isTrackingAuthority) {
        if (authorityWatchId !== null) {
            navigator.geolocation.clearWatch(authorityWatchId);
            authorityWatchId = null;
        }
        isTrackingAuthority = false;
        if (trackBtn) {
            trackBtn.innerHTML = `<i data-lucide="radio" class="w-3.5 h-3.5"></i><span>Live Tracking: OFF</span>`;
            trackBtn.className = "px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-slate-300 transition flex items-center gap-1.5 border border-slate-700";
            if (window.lucide) lucide.createIcons();
        }
    } else {
        isTrackingAuthority = true;
        if (trackBtn) {
            trackBtn.innerHTML = `<i data-lucide="radio" class="w-3.5 h-3.5 text-emerald-400 animate-pulse"></i><span>Live Tracking: ON</span>`;
            trackBtn.className = "px-3 py-1.5 rounded-xl bg-emerald-950/80 hover:bg-emerald-900/80 text-xs font-semibold text-emerald-300 transition flex items-center gap-1.5 border border-emerald-600 shadow-lg shadow-emerald-900/20";
            if (window.lucide) lucide.createIcons();
        }
        authorityWatchId = navigator.geolocation.watchPosition(
            (pos) => {
                saveCustomPosition(pos.coords.latitude, pos.coords.longitude);
                handleLocationSuccess(pos.coords.latitude, pos.coords.longitude, pos.coords.accuracy || 20, false, 'Continuous Live GPS');
            },
            (err) => console.warn('WatchPosition error:', err),
            { enableHighAccuracy: true, timeout: 8000, maximumAge: 2000 }
        );
    }
}

function calculateDistanceMeters(lat1, lon1, lat2, lon2) {
    const R = 6371e3;
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

function findNearestPothole(authLat, authLng) {
    if (!currentReportsData || currentReportsData.length === 0) return null;

    let nearestReport = null;
    let minDistance = Infinity;

    currentReportsData.forEach(r => {
        const rLat = parseFloat(r.latitude);
        const rLng = parseFloat(r.longitude);
        if (isNaN(rLat) || isNaN(rLng)) return;

        const dist = calculateDistanceMeters(authLat, authLng, rLat, rLng);
        if (dist < minDistance) {
            minDistance = dist;
            nearestReport = r;
        }
    });

    return nearestReport ? { report: nearestReport, distanceMeters: minDistance } : null;
}
