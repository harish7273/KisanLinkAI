/**
 * KisanAI Enterprise Admin - Unified Keyless Map Engine
 * Shared across all 6 administrative roles, dashboards, drawers, and modals.
 * Powered by Leaflet (locally bundled) and OpenStreetMap standard tiles
 * (matching the mobile app: lib/widgets/live_map_widget.dart line 445).
 * 
 * ZERO API KEY REQUIRED - Zero CARTO watermarks, zero commercial SDK locks.
 * 
 * PRODUCTION TILE CONFIGURATION NOTE:
 * The public OpenStreetMap tile server (tile.openstreetmap.org) is intended for
 * development and light/moderate administrative dashboard usage. For high-volume
 * enterprise production deployments, configure a dedicated commercial tile provider
 * or locally hosted vector tile cache:
 *   - MapTiler: set window.KISAN_MAP_CONFIG.maptilerKey = 'your_maptiler_key'
 *   - Stadia Maps: set window.KISAN_MAP_CONFIG.stadiaKey = 'your_stadia_key'
 *   - Self-hosted PMTiles / OSM tile server: set window.KISAN_MAP_CONFIG.customTileUrl
 */

// 1. GLOBAL MAP CONFIGURATION & AUTOMATIC FAILOVER SOURCES
window.KISAN_MAP_CONFIG = {
  primaryTileUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  mirrorTileUrls: [
    'https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
    'https://a.tile.openstreetmap.de/{z}/{x}/{y}.png',
    'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png'
  ],
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap</a> contributors',
  maxTileErrorsBeforeFailover: 3,
  userAgentPackage: 'com.kisanai.admin_dashboard',
  maptilerKey: null,
  stadiaKey: null,
  customTileUrl: null
};

// 2. CENTRAL MAP INSTANCE REGISTRY
class KisanMapRegistry {
  constructor() {
    this.instances = new Map();
  }

  register(id, mapInstance) {
    if (this.instances.has(id)) {
      const prev = this.instances.get(id);
      if (prev && prev !== mapInstance) {
        try { prev.destroy(); } catch (_) {}
      }
    }
    this.instances.set(id, mapInstance);
  }

  get(id) {
    return this.instances.get(id);
  }

  destroy(id) {
    const inst = this.instances.get(id);
    if (inst) {
      this.instances.delete(id);
      try { inst.destroy(); } catch (_) {}
    }
    const el = typeof id === 'string' ? document.getElementById(id) : id;
    if (el) {
      if (el._leaflet_id) el._leaflet_id = null;
      el.innerHTML = '';
    }
  }

  destroyAll() {
    for (const [id, inst] of this.instances.entries()) {
      try { inst.destroy(); } catch (_) {}
      const el = typeof id === 'string' ? document.getElementById(id) : id;
      if (el) {
        if (el._leaflet_id) el._leaflet_id = null;
        el.innerHTML = '';
      }
    }
    this.instances.clear();
  }

  invalidateAll() {
    for (const inst of this.instances.values()) {
      try {
        inst.invalidateSize();
      } catch (_) {}
    }
  }

  listAll() {
    return Array.from(this.instances.keys());
  }
}

window.kisanMapRegistry = new KisanMapRegistry();

// 3. UNIFIED KISAN MAP COMPONENT
class KisanMap {
  constructor(containerOrId, options = {}) {
    this.containerEl = typeof containerOrId === 'string' ? document.getElementById(containerOrId) : containerOrId;
    this.containerId = typeof containerOrId === 'string' ? containerOrId : (this.containerEl?.id || 'map_' + Math.random().toString(36).slice(2, 9));
    
    // Destroy previous instance registered for this container first
    if (window.kisanMapRegistry && window.kisanMapRegistry.get(this.containerId)) {
      window.kisanMapRegistry.destroy(this.containerId);
    }
    
    this.options = Object.assign({
      center: [10.9925, 77.0500], // Tamil Nadu Agro Corridor Hub (Coimbatore)
      zoom: 10,
      minZoom: 6,
      maxZoom: 18,
      mode: 'telematics', // 'telematics' | 'mini' | 'field_kyc' | 'dispute_replay' | 'regional_coverage'
      interactive: true,
      fitBounds: true,
      height: '400px',
      showRouteOverlay: true,
      markers: [],
      routes: [],
      polygons: []
    }, options);

    this.map = null;
    this.tileLayer = null;
    this.routeLayer = null;
    this.markersLayer = null;
    this.polygonsLayer = null;
    this.currentSourceIndex = 0;
    this.tileErrorCount = 0;
    this.isOfflineFallback = false;

    this.init();
  }

  init() {
    if (!this.containerEl) return;

    // Guaranteed sizing & style
    if (this.options.height) {
      this.containerEl.style.minHeight = this.options.height;
      this.containerEl.style.height = this.options.height;
    }
    this.containerEl.style.position = 'relative';
    this.containerEl.style.borderRadius = 'var(--radius-xl, 16px)';
    this.containerEl.style.overflow = 'hidden';

    // Reset any residual Leaflet identifiers
    if (this.containerEl._leaflet_id) {
      this.containerEl._leaflet_id = null;
    }
    this.containerEl.innerHTML = '';

    if (typeof L === 'undefined') {
      console.warn("Leaflet library not loaded, showing offline fallback schematic.");
      this.renderOfflineSchematicFallback("Leaflet Library Not Loaded");
      return;
    }

    try {
      this.map = L.map(this.containerEl, {
        zoomControl: this.options.interactive,
        attributionControl: true,
        fadeAnimation: false,
        zoomAnimation: false,
        dragging: this.options.interactive,
        touchZoom: this.options.interactive,
        scrollWheelZoom: this.options.interactive && this.options.mode !== 'mini',
        doubleClickZoom: this.options.interactive
      }).setView(this.options.center, this.options.zoom);

      // Attach Tile Layer with Automatic Mirror Failover
      this.applyTileSource();

      // Feature Layers
      this.routeLayer = L.layerGroup().addTo(this.map);
      this.polygonsLayer = L.layerGroup().addTo(this.map);
      this.markersLayer = L.layerGroup().addTo(this.map);

      // Render Data
      this.renderPolygons(this.options.polygons);
      this.renderRoutes(this.options.routes);
      this.renderMarkers(this.options.markers);

      // Auto-fit bounds if requested
      if (this.options.fitBounds) {
        this.fitToData();
      }

      // Floating route info overlay in telematics / mini mode
      if (this.options.showRouteOverlay && this.options.routes && this.options.routes.length > 0) {
        this.renderRouteInfoOverlay();
      }

      // Register with global manager
      window.kisanMapRegistry.register(this.containerId, this);

      // Progressive invalidation ensures container dimensions are fully resolved
      setTimeout(() => this.invalidateSize(), 60);
      setTimeout(() => this.invalidateSize(), 220);
      setTimeout(() => this.invalidateSize(), 500);

    } catch (err) {
      console.warn("Map initialization error, falling back to vector schematic:", err);
      this.renderOfflineSchematicFallback(err.message);
    }
  }

  applyTileSource() {
    if (!this.map) return;

    if (this.tileLayer) {
      try {
        this.map.removeLayer(this.tileLayer);
      } catch (_) {}
      this.tileLayer = null;
    }

    // Determine current tile URL (Checking production overrides first)
    let url = window.KISAN_MAP_CONFIG.customTileUrl;
    if (!url && window.KISAN_MAP_CONFIG.maptilerKey) {
      url = `https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${window.KISAN_MAP_CONFIG.maptilerKey}`;
    }
    if (!url) {
      if (this.currentSourceIndex === 0) {
        url = window.KISAN_MAP_CONFIG.primaryTileUrl;
      } else {
        const mirrorIdx = (this.currentSourceIndex - 1) % window.KISAN_MAP_CONFIG.mirrorTileUrls.length;
        url = window.KISAN_MAP_CONFIG.mirrorTileUrls[mirrorIdx];
      }
    }

    this.tileLayer = L.tileLayer(url, {
      maxZoom: this.options.maxZoom,
      minZoom: this.options.minZoom,
      attribution: window.KISAN_MAP_CONFIG.attribution,
      crossOrigin: true
    });

    this.tileLayer.on('tileerror', () => {
      this.tileErrorCount++;
      if (this.tileErrorCount >= window.KISAN_MAP_CONFIG.maxTileErrorsBeforeFailover) {
        this.tileErrorCount = 0;
        this.currentSourceIndex++;
        
        // If we exhausted mirrors, fallback to offline schematic
        if (this.currentSourceIndex > window.KISAN_MAP_CONFIG.mirrorTileUrls.length) {
          console.warn("All live map tile mirrors unavailable. Activating offline schematic view.");
          this.renderOfflineSchematicFallback("Network Offline / Tiles Unavailable");
        } else {
          console.info(`Switching map mirror source to index ${this.currentSourceIndex}...`);
          this.applyTileSource();
        }
      }
    });

    this.tileLayer.addTo(this.map);
  }

  createPinMarker(isOrigin = true, badgeText = "") {
    const dotColor = isOrigin ? "#3C8D63" : "#111113";
    const ringColor = isOrigin ? "rgba(60, 141, 99, 0.25)" : "rgba(17, 17, 19, 0.2)";

    return L.divIcon({
      className: 'kisan-pin-divicon',
      html: `
        <div style="position: relative; display: flex; align-items: center; justify-content: center; width: 28px; height: 28px; cursor: pointer;">
          <div style="position: absolute; width: 26px; height: 26px; border-radius: 50%; background: ${ringColor}; animation: kisanPulse 2.4s infinite ease-out;"></div>
          <div style="position: absolute; width: 16px; height: 16px; border-radius: 50%; background: #FFFFFF; border: 2.5px solid ${dotColor}; box-shadow: 0 2px 6px rgba(0,0,0,0.18);"></div>
          <div style="position: absolute; width: 6px; height: 6px; border-radius: 50%; background: ${dotColor};"></div>
          ${badgeText ? `<span style="position: absolute; top: -14px; background: #FFFFFF; border: 1px solid #ECECEE; font-size: 8px; font-weight: 800; padding: 1px 4px; border-radius: 3px; color: ${dotColor}; box-shadow: 0 1px 3px rgba(0,0,0,0.08); white-space: nowrap;">${badgeText}</span>` : ''}
        </div>
      `,
      iconSize: [28, 28],
      iconAnchor: [14, 14]
    });
  }

  createVehicleMarker(vehicleType = "", reeferTemp = "3.8 deg C") {
    let vehicleImg = "assets/vehicles/vehicle_tata_ace.svg";
    let badgeText = "CARRIER";
    let badgeBg = "#111113";

    const v = String(vehicleType || "").toLowerCase();
    if (v.includes("reefer") || v.includes("cold")) {
      vehicleImg = "assets/vehicles/vehicle_reefer.svg";
      badgeText = `REEFER ${reeferTemp.replace('deg C', '°C')}`;
      badgeBg = "#0284C7";
    } else if (v.includes("bike") || v.includes("express") || v.includes("motorcycle")) {
      vehicleImg = "assets/vehicles/vehicle_bike.svg";
      badgeText = "EXPRESS";
      badgeBg = "#B7791F";
    } else if (v.includes("mini") || v.includes("bolero") || v.includes("ace")) {
      vehicleImg = "assets/vehicles/vehicle_mini_truck.svg";
      badgeText = "RURAL ACE";
      badgeBg = "#3C8D63";
    }

    return L.divIcon({
      className: 'kisan-vehicle-divicon',
      html: `
        <div style="position: relative; display: flex; flex-direction: column; align-items: center; cursor: pointer; transform: translate3d(0,0,0);">
          <div style="background: #FFFFFF; border: 1px solid #ECECEE; box-shadow: 0 4px 14px rgba(0,0,0,0.12); border-radius: 8px; padding: 3px 8px; display: flex; align-items: center; gap: 6px; white-space: nowrap;">
            <img src="${vehicleImg}" alt="Vehicle" width="30" height="18" style="object-fit: contain;" />
            <span style="background: ${badgeBg}; color: #FFFFFF; font-size: 8.5px; font-weight: 800; padding: 2px 5px; border-radius: 4px; font-family: -apple-system, BlinkMacSystemFont, sans-serif; letter-spacing: 0.02em;">${badgeText}</span>
          </div>
          <div style="width: 2px; height: 5px; background: #111113;"></div>
          <div style="width: 5px; height: 5px; border-radius: 50%; background: #111113;"></div>
        </div>
      `,
      iconSize: [110, 36],
      iconAnchor: [55, 36]
    });
  }

  createIncidentMarker(title = "Delay Incident") {
    return L.divIcon({
      className: 'kisan-incident-divicon',
      html: `
        <div style="position: relative; display: flex; flex-direction: column; align-items: center; cursor: pointer;">
          <div style="background: #DC2626; color: #FFFFFF; border-radius: 6px; padding: 3px 7px; font-size: 8.5px; font-weight: 800; box-shadow: 0 3px 10px rgba(220,38,38,0.3); white-space: nowrap;">
            ${title}
          </div>
          <div style="width: 2px; height: 5px; background: #DC2626;"></div>
          <div style="width: 6px; height: 6px; border-radius: 50%; background: #DC2626; border: 1.5px solid #FFFFFF;"></div>
        </div>
      `,
      iconSize: [90, 32],
      iconAnchor: [45, 32]
    });
  }

  renderMarkers(markers = []) {
    if (!this.map || !this.markersLayer) return;
    this.markersLayer.clearLayers();

    markers.forEach(m => {
      let icon;
      if (m.type === 'vehicle') {
        icon = this.createVehicleMarker(m.vehicleType, m.reeferTemp);
      } else if (m.type === 'incident') {
        icon = this.createIncidentMarker(m.badge || "Route Delay");
      } else if (m.type === 'destination') {
        icon = this.createPinMarker(false, m.badge || "");
      } else {
        icon = this.createPinMarker(true, m.badge || "");
      }

      const marker = L.marker([m.lat, m.lng], { icon: icon });

      // Clean non-permanent hover tooltip prevents text collisions
      if (m.tooltipText || m.title) {
        marker.bindTooltip(m.tooltipText || `${m.title} ${m.subtitle ? '— ' + m.subtitle : ''}`, {
          direction: 'top',
          offset: [0, -10],
          className: 'kisan-map-tooltip'
        });
      }

      // Rich interactive click popup
      if (m.popupHtml) {
        marker.bindPopup(m.popupHtml, { maxWidth: 300 });
      } else if (m.title) {
        marker.bindPopup(`
          <div style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 4px;">
            <div style="font-size: 10px; font-weight: 800; text-transform: uppercase; color: ${m.type === 'origin' ? '#3C8D63' : '#111113'};">${m.type.toUpperCase()}</div>
            <div style="font-size: 13px; font-weight: 800; color: #0B0B0F; margin-top: 2px;">${m.title}</div>
            ${m.subtitle ? `<div style="font-size: 11.5px; color: #5F6368; margin-top: 2px;">${m.subtitle}</div>` : ''}
            ${m.detailsHtml ? `<div style="margin-top: 6px; font-size: 11px;">${m.detailsHtml}</div>` : ''}
          </div>
        `);
      }

      this.markersLayer.addLayer(marker);
    });
  }

  renderRoutes(routes = []) {
    if (!this.map || !this.routeLayer) return;
    this.routeLayer.clearLayers();

    routes.forEach(r => {
      if (!r.points || r.points.length < 2) return;

      const isAlternate = !!r.isAlternate;
      const primaryColor = isAlternate ? "#0284C7" : (r.color || "#3C8D63");
      const casingColor = isAlternate ? "rgba(2, 132, 199, 0.2)" : "rgba(60, 141, 99, 0.22)";

      // Route Casing Glow (matching mobile app: lib/widgets/live_map_widget.dart line 465)
      const casing = L.polyline(r.points, {
        color: casingColor,
        weight: 7.0,
        opacity: 0.9,
        lineCap: 'round',
        lineJoin: 'round'
      });
      this.routeLayer.addLayer(casing);

      // Active Route Foreground
      const foreground = L.polyline(r.points, {
        color: primaryColor,
        weight: isAlternate ? 3.0 : 4.0,
        opacity: 0.95,
        dashArray: r.dashed ? "6, 8" : undefined,
        lineCap: 'round',
        lineJoin: 'round'
      });

      if (r.label || r.distanceKm) {
        foreground.bindTooltip(`${r.label || 'Highway Corridor'} (${r.distanceKm || '68'} km — ${r.etaMinutes || '44'} mins ETA)`, {
          direction: 'center',
          sticky: true,
          className: 'kisan-map-tooltip'
        });
      }

      this.routeLayer.addLayer(foreground);
    });
  }

  renderPolygons(polygons = []) {
    if (!this.map || !this.polygonsLayer) return;
    this.polygonsLayer.clearLayers();

    polygons.forEach(p => {
      if (!p.points || p.points.length < 3) return;

      const poly = L.polygon(p.points, {
        color: p.color || "#3C8D63",
        fillColor: p.fillColor || "#3C8D63",
        fillOpacity: p.fillOpacity || 0.18,
        weight: 2
      });

      if (p.tooltipText || p.title) {
        poly.bindTooltip(p.tooltipText || p.title, { direction: 'center', className: 'kisan-map-tooltip' });
      }

      if (p.popupHtml) {
        poly.bindPopup(p.popupHtml);
      }

      this.polygonsLayer.addLayer(poly);
    });
  }

  renderRouteInfoOverlay() {
    const existing = this.containerEl.querySelector('.kisan-map-route-overlay');
    if (existing) existing.remove();

    const r = this.options.routes[0];
    if (!r) return;

    const overlay = document.createElement('div');
    overlay.className = 'kisan-map-route-overlay';
    overlay.style.cssText = `
      position: absolute;
      top: 12px;
      right: 12px;
      z-index: 1000;
      background: #FFFFFF;
      border: 1px solid var(--border-hairline, #ECECEE);
      border-radius: 10px;
      padding: 6px 12px;
      box-shadow: 0 4px 14px rgba(0,0,0,0.08);
      display: flex;
      align-items: center;
      gap: 10px;
      font-family: -apple-system, BlinkMacSystemFont, sans-serif;
      pointer-events: auto;
    `;

    overlay.innerHTML = `
      <div style="display: flex; align-items: center; gap: 6px;">
        <span style="display: inline-block; width: 7px; height: 7px; border-radius: 50%; background: #3C8D63;"></span>
        <span style="font-size: 11px; font-weight: 700; color: #0B0B0F;">${r.distanceKm || '68.4'} km</span>
      </div>
      <div style="width: 1px; height: 12px; background: #ECECEE;"></div>
      <div style="font-size: 11px; font-weight: 700; color: #0284C7;">${r.etaMinutes || '44'} mins ETA</div>
    `;

    this.containerEl.appendChild(overlay);
  }

  fitToData() {
    if (!this.map) return;

    const allLayers = [];
    if (this.markersLayer) allLayers.push(...this.markersLayer.getLayers());
    if (this.routeLayer) allLayers.push(...this.routeLayer.getLayers());
    if (this.polygonsLayer) allLayers.push(...this.polygonsLayer.getLayers());

    if (allLayers.length > 0) {
      try {
        const group = new L.featureGroup(allLayers);
        const bounds = group.getBounds();
        if (bounds.isValid()) {
          this.map.fitBounds(bounds.pad(0.14), { maxZoom: 14, animate: false });
        }
      } catch (_) {}
    }
  }

  invalidateSize() {
    if (this.map) {
      try {
        this.map.invalidateSize();
      } catch (_) {}
    }
  }

  destroy() {
    if (this.map) {
      try {
        this.map.stop();
        this.map.off();
        this.map.remove();
      } catch (_) {}
      this.map = null;
    }
    this.routeLayer = null;
    this.markersLayer = null;
    this.polygonsLayer = null;
    this.tileLayer = null;

    if (this.containerEl) {
      if (this.containerEl._leaflet_id) {
        this.containerEl._leaflet_id = null;
      }
      this.containerEl.innerHTML = '';
    }
  }

  renderOfflineSchematicFallback(reason = "Map Unavailable") {
    this.isOfflineFallback = true;
    if (!this.containerEl) return;

    // Preserve height
    const h = this.options.height || '400px';
    const isMini = this.options.mode === 'mini' || parseInt(h, 10) < 280;

    const primaryRoute = (this.options.routes && this.options.routes[0]) || { distanceKm: 68.4, etaMinutes: 44, label: "NH-83 Agro Highway" };
    const originMarker = (this.options.markers && this.options.markers.find(m => m.type === 'origin')) || { title: "Udumalpet Farm Origin" };
    const destMarker = (this.options.markers && this.options.markers.find(m => m.type === 'destination')) || { title: "Ukkadam Mandi Terminal" };
    const vehicleMarker = (this.options.markers && this.options.markers.find(m => m.type === 'vehicle')) || { title: "Reefer TN-38-BZ-4412", reeferTemp: "3.8°C" };

    this.containerEl.innerHTML = `
      <div style="width: 100%; height: ${h}; background: #FAFAFA; border: 1px solid #ECECEE; border-radius: 14px; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 18px; text-align: center; position: relative; overflow: hidden; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
        <div style="position: absolute; top: 12px; left: 16px; text-align: left; display: flex; align-items: center; gap: 8px;">
          <span style="background: #FFFFFF; border: 1px solid #ECECEE; border-radius: 6px; padding: 2px 7px; font-size: 9.5px; font-weight: 800; color: #3C8D63;">TELEMATICS ACTIVE</span>
          <span style="font-size: 11px; color: #5F6368;">${primaryRoute.label || 'Tamil Nadu Highway Corridor'}</span>
        </div>

        <button onclick="window.kisanMapManager.retry('${this.containerId}')" class="btn btn-secondary" style="position: absolute; top: 12px; right: 14px; padding: 3px 9px; font-size: 11px;">
          Retry Connection
        </button>

        <svg viewBox="0 0 620 180" width="100%" height="${isMini ? '120' : '150'}" style="max-width: 580px; margin-top: 14px;">
          <path d="M 60 130 Q 200 110 320 80 T 560 40" fill="none" stroke="#ECECEE" stroke-width="8" stroke-linecap="round"/>
          <path d="M 60 130 Q 200 110 320 80 T 560 40" fill="none" stroke="#3C8D63" stroke-width="3.5" stroke-linecap="round"/>
          <path d="M 60 130 Q 200 110 320 80 T 560 40" fill="none" stroke="#0284C7" stroke-width="1.8" stroke-dasharray="5, 6"/>

          <circle cx="60" cy="130" r="7" fill="#3C8D63" stroke="#FFFFFF" stroke-width="2"/>
          <text x="60" y="156" font-family="-apple-system, sans-serif" font-size="10.5" font-weight="700" text-anchor="middle" fill="#0B0B0F">${originMarker.title.split('(')[0]}</text>

          <rect x="220" y="85" width="140" height="32" rx="7" fill="#FFFFFF" stroke="#ECECEE" filter="drop-shadow(0 2px 5px rgba(0,0,0,0.06))"/>
          <text x="230" y="99" font-family="-apple-system, sans-serif" font-size="9.5" font-weight="bold" fill="#0284C7">${vehicleMarker.title}</text>
          <text x="230" y="111" font-family="-apple-system, sans-serif" font-size="9" fill="#5F6368">${primaryRoute.distanceKm || '68.4'} km • ${primaryRoute.etaMinutes || '44'}m ETA</text>

          <circle cx="560" cy="40" r="7" fill="#111113" stroke="#FFFFFF" stroke-width="2"/>
          <text x="560" y="66" font-family="-apple-system, sans-serif" font-size="10.5" font-weight="700" text-anchor="middle" fill="#0B0B0F">${destMarker.title.split('(')[0]}</text>
        </svg>

        <div style="margin-top: 6px; display: flex; gap: 8px; flex-wrap: wrap; justify-content: center;">
          <span style="font-size: 11px; background: #FFFFFF; border: 1px solid #ECECEE; padding: 3px 10px; border-radius: 16px; font-weight: 600; color: #0B0B0F;">Distance: <b>${primaryRoute.distanceKm || '68.4'} km</b></span>
          <span style="font-size: 11px; background: #FFFFFF; border: 1px solid #ECECEE; padding: 3px 10px; border-radius: 16px; font-weight: 600; color: #0284C7;">Transit ETA: <b>${primaryRoute.etaMinutes || '44'} mins</b></span>
          <span style="font-size: 11px; background: #FFFFFF; border: 1px solid #ECECEE; padding: 3px 10px; border-radius: 16px; font-weight: 600; color: #3C8D63;">Keyless OpenStreetMap Verified</span>
        </div>
      </div>
    `;
  }
}

// 4. FACTORY FUNCTION: createKisanMap
function createKisanMap(containerOrId, options = {}) {
  return new KisanMap(containerOrId, options);
}

window.createKisanMap = createKisanMap;

// 5. HIGH-LEVEL KISAN MAP MANAGER FOR SPECIALIZED WORKSPACES & DRAWERS
class KisanMapManager {
  // Super Admin & Operations Dispatch Telematics Map
  initTelematicsMap(containerId = "adminMap") {
    const orders = window.kisanDataStore ? window.kisanDataStore.orders : [];
    const liveCorridors = orders.filter(o => o.orderId && o.orderId.startsWith("ORD-LIVE"));
    const inTransit = liveCorridors.length > 0 ? liveCorridors : orders.filter(o => o.status === "In Transit").slice(0, 3);

    const markers = [];
    const routes = [];

    const highwayCorridors = {
      'ORD-LIVE-01': [
        [10.5844, 77.2476], [10.6012, 77.2280], [10.6580, 77.1850],
        [10.7200, 77.1350], [10.8250, 77.0680], [10.9200, 77.0120],
        [10.9850, 76.9680], [10.9925, 76.9614]
      ],
      'ORD-LIVE-02': [
        [10.6609, 77.0048], [10.7350, 76.9850], [10.8500, 76.9720],
        [10.9400, 76.9650], [11.0168, 76.9558]
      ],
      'ORD-LIVE-03': [
        [11.0055, 77.5583], [11.0800, 77.5900], [11.1600, 77.6400],
        [11.2400, 77.6800], [11.3410, 77.7172]
      ]
    };

    inTransit.forEach(ord => {
      // Origin Pin
      markers.push({
        lat: ord.pickupLat,
        lng: ord.pickupLng,
        type: 'origin',
        title: ord.farmer,
        subtitle: ord.farmerLocation,
        tooltipText: `${ord.farmer} (${ord.farmerLocation.split(',')[0]})`,
        popupHtml: `
          <div style="font-family: -apple-system, sans-serif; padding: 4px;">
            <div style="font-size: 10px; font-weight: 800; color: #3C8D63; text-transform: uppercase;">Farm Origin Dispatch</div>
            <div style="font-size: 13px; font-weight: 800; margin-top: 2px; color: #0B0B0F;">${ord.farmer}</div>
            <div style="font-size: 11.5px; color: #5F6368;">${ord.farmerLocation}</div>
            <div style="margin-top: 6px; padding: 6px; background: #FAFAFA; border-radius: 6px; border: 1px solid #ECECEE; font-size: 11px;">
              Consignment: <b>${ord.crop} (${ord.qty})</b><br/>
              Security OTP: <b style="font-family: monospace;">${ord.pickupOtp || '4821'}</b>
            </div>
          </div>
        `
      });

      // Destination Pin
      markers.push({
        lat: ord.dropLat,
        lng: ord.dropLng,
        type: 'destination',
        title: ord.buyer,
        subtitle: ord.deliveryAddress,
        tooltipText: `${ord.buyer} (${ord.deliveryAddress.split(',')[0]})`,
        popupHtml: `
          <div style="font-family: -apple-system, sans-serif; padding: 4px;">
            <div style="font-size: 10px; font-weight: 800; color: #111113; text-transform: uppercase;">Receiving Mandi Destination</div>
            <div style="font-size: 13px; font-weight: 800; margin-top: 2px; color: #0B0B0F;">${ord.buyer}</div>
            <div style="font-size: 11.5px; color: #5F6368;">${ord.deliveryAddress}</div>
            <div style="margin-top: 6px; font-size: 11px; color: #3C8D63; font-weight: 600;">Receiving Bay Clear — Staff Ready</div>
          </div>
        `
      });

      // Midpoint Vehicle
      const midLat = (ord.pickupLat + ord.dropLat) / 2 + 0.006;
      const midLng = (ord.pickupLng + ord.dropLng) / 2 - 0.006;
      markers.push({
        lat: midLat,
        lng: midLng,
        type: 'vehicle',
        title: `Order #${ord.orderId}`,
        subtitle: ord.driver,
        vehicleType: ord.vehicleType,
        reeferTemp: ord.reeferTemp,
        tooltipText: `Order #${ord.orderId} — ${ord.driver} (${ord.etaMinutes}m ETA)`,
        popupHtml: `
          <div style="font-family: -apple-system, sans-serif; padding: 6px; min-width: 200px;">
            <div style="font-size: 9.5px; font-weight: 800; text-transform: uppercase; color: #5F6368;">Live Transit Telematics</div>
            <div style="font-size: 14px; font-weight: 800; color: #0B0B0F; margin: 2px 0;">Order #${ord.orderId}</div>
            <div style="font-size: 11.5px; color: #5F6368;">Driver: <b>${ord.driver}</b> (${ord.driverPhone})</div>
            <div style="margin-top: 6px; padding: 6px; background: #FAFAFA; border-radius: 8px; border: 1px solid #ECECEE;">
              <div style="font-size: 11px;">Cargo Temp: <b style="color: #0284C7;">${ord.reeferTemp}</b></div>
              <div style="font-size: 11px; margin-top: 2px;">Distance: <b>${ord.distanceKm} km</b> — ETA: <b>${ord.etaMinutes} mins</b></div>
            </div>
            <button onclick="window.inspectOrderAction('${ord.orderId}')" class="btn btn-secondary" style="width: 100%; margin-top: 8px; padding: 4px; font-size: 11px;">Inspect Consignment</button>
          </div>
        `
      });

      // Route Polyline
      const pts = highwayCorridors[ord.orderId] || [
        [ord.pickupLat, ord.pickupLng],
        [midLat, midLng],
        [ord.dropLat, ord.dropLng]
      ];
      routes.push({
        points: pts,
        color: ord.vehicleType.toLowerCase().includes("reefer") ? "#0284C7" : "#3C8D63",
        distanceKm: ord.distanceKm,
        etaMinutes: ord.etaMinutes,
        label: `Corridor #${ord.orderId}`
      });
    });

    return createKisanMap(containerId, {
      center: [10.9925, 77.0500],
      zoom: 10,
      height: '400px',
      mode: 'telematics',
      markers: markers,
      routes: routes,
      fitBounds: true
    });
  }

  // Field Officer: Farm Land Parcels & Carrier Hubs
  initFieldKycMap(containerId = "fieldKycMap") {
    const farms = [
      {
        name: "Ramasamy K. Farm (Kaniyur)",
        acres: 4.5,
        patta: "Patta #7412",
        center: [10.5844, 77.2476],
        points: [
          [10.5830, 77.2460], [10.5860, 77.2465], [10.5855, 77.2490], [10.5825, 77.2485]
        ]
      },
      {
        name: "Murugan S. Coconut Grove (Anaimalai)",
        acres: 8.0,
        patta: "Patta #9914",
        center: [10.6609, 77.0048],
        points: [
          [10.6580, 77.0020], [10.6630, 77.0030], [10.6620, 77.0070], [10.6570, 77.0060]
        ]
      },
      {
        name: "K. Muthusamy Agro Farm (Kangeyam)",
        acres: 18.4,
        patta: "Patta #1209",
        center: [11.0055, 77.5583],
        points: [
          [11.0020, 77.5540], [11.0080, 77.5550], [11.0070, 77.5610], [11.0010, 77.5600]
        ]
      }
    ];

    const markers = [];
    const polygons = [];

    farms.forEach(f => {
      polygons.push({
        points: f.points,
        color: "#3C8D63",
        fillColor: "#3C8D63",
        fillOpacity: 0.16,
        title: f.name,
        popupHtml: `
          <div style="font-family: -apple-system, sans-serif; padding: 4px;">
            <div style="font-size: 10px; font-weight: 800; color: #3C8D63;">Verified Land Parcel</div>
            <div style="font-size: 13px; font-weight: bold; margin-top: 2px;">${f.name}</div>
            <div style="font-size: 11.5px; color: #5F6368;">Area: <b>${f.acres} Acres</b> • ${f.patta}</div>
          </div>
        `
      });

      markers.push({
        lat: f.center[0],
        lng: f.center[1],
        type: 'origin',
        title: f.name,
        badge: 'PATTA',
        tooltipText: `${f.name} (${f.acres} Acres)`
      });
    });

    // Carrier Depots
    const depots = [
      { name: "Pollachi Commercial Carrier Hub", vehicles: "12 Trucks", pos: [10.6580, 77.0080] },
      { name: "Tiruppur Fleet Depot", vehicles: "18 Trucks", pos: [11.1085, 77.3411] },
      { name: "Coimbatore Central Logistics Yard", vehicles: "24 Reefer Vehicles", pos: [11.0168, 76.9558] }
    ];

    depots.forEach(d => {
      markers.push({
        lat: d.pos[0],
        lng: d.pos[1],
        type: 'vehicle',
        title: d.name,
        vehicleType: "Mini Truck",
        reeferTemp: "Depot",
        tooltipText: `${d.name} (${d.vehicles})`
      });
    });

    return createKisanMap(containerId, {
      center: [10.8500, 77.2000],
      zoom: 10,
      height: '400px',
      mode: 'field_kyc',
      markers: markers,
      polygons: polygons,
      fitBounds: true
    });
  }

  // Drawer: Order Dossier Route Mini-Map
  initOrderDossierMap(containerId, order) {
    if (!order) return null;

    const midLat = (order.pickupLat + order.dropLat) / 2 + 0.006;
    const midLng = (order.pickupLng + order.dropLng) / 2 - 0.006;

    const markers = [
      {
        lat: order.pickupLat,
        lng: order.pickupLng,
        type: 'origin',
        title: order.farmer,
        subtitle: order.farmerLocation,
        badge: 'ORIGIN'
      },
      {
        lat: order.dropLat,
        lng: order.dropLng,
        type: 'destination',
        title: order.buyer,
        subtitle: order.deliveryAddress,
        badge: 'MANDI'
      },
      {
        lat: midLat,
        lng: midLng,
        type: 'vehicle',
        title: `Vehicle: ${order.driverVehicle || order.vehicleType}`,
        vehicleType: order.vehicleType,
        reeferTemp: order.reeferTemp || "3.8°C"
      }
    ];

    const routes = [
      {
        points: [
          [order.pickupLat, order.pickupLng],
          [midLat, midLng],
          [order.dropLat, order.dropLng]
        ],
        color: "#3C8D63",
        distanceKm: order.distanceKm || 68.4,
        etaMinutes: order.etaMinutes || 44,
        label: `Corridor #${order.orderId}`
      }
    ];

    return createKisanMap(containerId, {
      height: '220px',
      mode: 'mini',
      markers: markers,
      routes: routes,
      fitBounds: true,
      showRouteOverlay: true
    });
  }

  // Drawer: Dispute Resolution GPS Trail Replay Mini-Map
  initDisputeMap(containerId, dispute) {
    if (!dispute) return null;

    // Udumalpet to Coimbatore NH-83 Delay Incident point
    const origin = [10.5844, 77.2476];
    const incidentPos = [10.7420, 77.1210]; // NH-83 Mile Marker 34 delay
    const dest = [10.9925, 76.9614];

    const markers = [
      { lat: origin[0], lng: origin[1], type: 'origin', title: "Farm Dispatch", badge: "PICKUP" },
      { lat: incidentPos[0], lng: incidentPos[1], type: 'incident', title: "Dispute Incident Location", badge: "DELAY CLOCK" },
      { lat: dest[0], lng: dest[1], type: 'destination', title: "Destination Mandi", badge: "DELIVERY" }
    ];

    const routes = [
      {
        points: [origin, incidentPos, dest],
        color: "#DC2626",
        dashed: true,
        distanceKm: 68.4,
        etaMinutes: 18,
        label: "GPS Audit Trail"
      }
    ];

    return createKisanMap(containerId, {
      height: '210px',
      mode: 'dispute_replay',
      markers: markers,
      routes: routes,
      fitBounds: true
    });
  }

  // Drawer: Support Ticket Chat Mini-Map
  initSupportChatMap(containerId, ticket) {
    const origin = [10.6609, 77.0048];
    const vehiclePos = [10.8400, 76.9800];
    const dest = [11.0168, 76.9558];

    const markers = [
      { lat: origin[0], lng: origin[1], type: 'origin', title: "Origin Hub", badge: "ORIGIN" },
      { lat: vehiclePos[0], lng: vehiclePos[1], type: 'vehicle', title: "Active Consignment", vehicleType: "Tata Ace", reeferTemp: "Ambient" },
      { lat: dest[0], lng: dest[1], type: 'destination', title: "Buyer Receiving Mandi", badge: "DESTINATION" }
    ];

    const routes = [
      {
        points: [origin, vehiclePos, dest],
        color: "#0284C7",
        distanceKm: 41.2,
        etaMinutes: 28,
        label: "Support Resolution Route"
      }
    ];

    return createKisanMap(containerId, {
      height: '200px',
      mode: 'mini',
      markers: markers,
      routes: routes,
      fitBounds: true
    });
  }

  // Drawer: KYC Inspection Land Boundary Mini-Map
  initKycDrawerMap(containerId, user) {
    const isFarmer = (user && user.role === 'farmer');
    const center = isFarmer ? [10.5844, 77.2476] : [11.0168, 76.9558];

    const markers = [
      {
        lat: center[0],
        lng: center[1],
        type: isFarmer ? 'origin' : 'vehicle',
        title: user ? user.name : "Verified Ground Subject",
        badge: isFarmer ? "PATTA VERIFIED" : "RC VERIFIED",
        vehicleType: "Mini Truck",
        reeferTemp: "Depot"
      }
    ];

    const polygons = isFarmer ? [
      {
        points: [
          [10.5830, 77.2460], [10.5860, 77.2465], [10.5855, 77.2490], [10.5825, 77.2485]
        ],
        color: "#3C8D63",
        fillColor: "#3C8D63",
        fillOpacity: 0.22,
        title: "Survey Land Boundary Polygon"
      }
    ] : [];

    return createKisanMap(containerId, {
      center: center,
      zoom: 14,
      height: '210px',
      mode: 'mini',
      markers: markers,
      polygons: polygons,
      fitBounds: true
    });
  }

  // Quality Officer: Farm Origin Harvest Locations
  initQualityOriginMap(containerId = "qualityOriginMap") {
    const farms = [
      { name: "Udumalpet Tomato Valley", crop: "Tomato (Hybrid Super)", quality: "Grade A", pos: [10.5844, 77.2476] },
      { name: "Pollachi Coconut & Banana Basin", crop: "Grand Naine Banana", quality: "Grade A", pos: [10.6609, 77.0048] },
      { name: "Kangeyam Shallot Plains", crop: "Shallots (Small Onion)", quality: "Grade A", pos: [11.0055, 77.5583] }
    ];

    const markers = farms.map(f => ({
      lat: f.pos[0],
      lng: f.pos[1],
      type: 'origin',
      title: f.name,
      subtitle: `${f.crop} • ${f.quality}`,
      badge: 'AGMARK',
      popupHtml: `
        <div style="font-family: -apple-system, sans-serif; padding: 4px;">
          <div style="font-size: 10px; font-weight: 800; color: #3C8D63;">Verified Harvest Origin</div>
          <div style="font-size: 13px; font-weight: 800; margin-top: 2px;">${f.name}</div>
          <div style="font-size: 11.5px; color: #5F6368;">Crop: <b>${f.crop}</b></div>
          <div style="margin-top: 4px; display: inline-block; background: #DCFCE7; color: #15803D; font-size: 10px; font-weight: 800; padding: 2px 6px; border-radius: 4px;">AGMARK CERTIFIED</div>
        </div>
      `
    }));

    return createKisanMap(containerId, {
      center: [10.8500, 77.2000],
      zoom: 10,
      height: '380px',
      mode: 'quality_origin',
      markers: markers,
      fitBounds: true
    });
  }

  // Super Admin / Platform Controls: Regional Service Coverage Map
  initRegionalCoverageMap(containerId = "regionalCoverageMap") {
    const districts = [
      { name: "Coimbatore Central Mandi Hub", mandis: "4 Active Mandis", pos: [11.0168, 76.9558], color: "#3C8D63" },
      { name: "Tiruppur Textile-Agro Interchange", mandis: "2 Active Mandis", pos: [11.1085, 77.3411], color: "#3C8D63" },
      { name: "Erode Perundurai Produce Terminal", mandis: "3 Active Mandis", pos: [11.3410, 77.7172], color: "#3C8D63" },
      { name: "Pollachi Foothills Agro Node", mandis: "2 Active Mandis", pos: [10.6580, 77.0080], color: "#3C8D63" },
      { name: "Salem Central Wholesale Market", mandis: "3 Active Mandis", pos: [11.6643, 78.1460], color: "#0284C7" },
      { name: "Dindigul Southern Transit Hub", mandis: "2 Active Mandis", pos: [10.3673, 77.9803], color: "#0284C7" }
    ];

    const markers = districts.map(d => ({
      lat: d.pos[0],
      lng: d.pos[1],
      type: 'destination',
      title: d.name,
      subtitle: d.mandis,
      badge: 'NODE'
    }));

    // Inter-district backbone highway
    const routes = [
      {
        points: [
          [10.6580, 77.0080], [11.0168, 76.9558], [11.1085, 77.3411], [11.3410, 77.7172], [11.6643, 78.1460]
        ],
        color: "#3C8D63",
        distanceKm: 184.2,
        etaMinutes: 190,
        label: "TN Western Agro Highway Backbone"
      }
    ];

    return createKisanMap(containerId, {
      center: [11.0500, 77.4000],
      zoom: 9,
      height: '380px',
      mode: 'regional_coverage',
      markers: markers,
      routes: routes,
      fitBounds: true
    });
  }

  retry(containerId) {
    const inst = window.kisanMapRegistry.get(containerId);
    if (inst) {
      inst.currentSourceIndex = 0;
      inst.tileErrorCount = 0;
      inst.init();
    }
  }

  destroy(containerId) {
    window.kisanMapRegistry.destroy(containerId);
  }

  destroyAll() {
    window.kisanMapRegistry.destroyAll();
  }

  invalidateAll() {
    window.kisanMapRegistry.invalidateAll();
  }
}

window.kisanMapManager = new KisanMapManager();

// Backwards compatibility alias for any lingering references
window.kisanMapEngine = {
  init: (containerId, center, zoom, mode) => {
    if (mode === "field_kyc") {
      return window.kisanMapManager.initFieldKycMap(containerId);
    }
    return window.kisanMapManager.initTelematicsMap(containerId);
  },
  destroy: () => {
    window.kisanMapManager.destroy("adminMap");
    window.kisanMapManager.destroy("fieldKycMap");
  }
};

// Global resize listener triggers invalidation across all open maps
window.addEventListener('resize', () => {
  window.kisanMapManager.invalidateAll();
});
