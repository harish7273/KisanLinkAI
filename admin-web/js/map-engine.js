/**
 * KisanAI Enterprise Admin — Keyless Map & Telematics Routing Engine
 * Powered by Leaflet (locally bundled) and OpenStreetMap standard tiles
 * (matching the mobile app: lib/widgets/live_map_widget.dart).
 * ZERO API KEY REQUIRED — No CARTO watermarks, no external keys.
 */

class KisanMapEngine {
  constructor(containerId = "adminMap") {
    this.containerId = containerId;
    this.map = null;
    this.routeLayer = null;
    this.markersLayer = null;
    this.polygonsLayer = null;
    this.activeTileLayer = null;
  }

  destroy() {
    if (this.map) {
      try {
        this.map.remove();
      } catch (_) {}
      this.map = null;
      this.routeLayer = null;
      this.markersLayer = null;
      this.polygonsLayer = null;
      this.activeTileLayer = null;
    }
    ['adminMap', 'fieldKycMap'].forEach(id => {
      const el = document.getElementById(id);
      if (el) {
        if (el._leaflet_id) el._leaflet_id = null;
        el.innerHTML = '';
      }
    });
  }

  init(containerId = "adminMap", center = [10.9925, 77.0500], zoom = 10, mode = "telematics") {
    this.containerId = containerId;
    const el = document.getElementById(this.containerId);
    if (!el) return;

    this.destroy();

    // Clean any residual Leaflet markers / ID on container
    el._leaflet_id = null;
    el.innerHTML = '';
    el.style.minHeight = "400px";
    el.style.height = "400px";

    // Check if Leaflet (L) is defined
    if (typeof L === 'undefined') {
      console.warn("Leaflet script not available, rendering fallback canvas.");
      this.renderOfflineCanvasFallback(el, mode);
      return;
    }

    try {
      this.map = L.map(el, {
        zoomControl: true,
        attributionControl: true,
        fadeAnimation: true
      }).setView(center, zoom);

      // Apply standard OpenStreetMap tiles matching mobile app
      this.applyStandardOsmTiles();

      this.routeLayer = L.layerGroup().addTo(this.map);
      this.markersLayer = L.layerGroup().addTo(this.map);
      this.polygonsLayer = L.layerGroup().addTo(this.map);

      if (mode === "field_kyc") {
        this.renderFieldKycGeospatial();
      } else {
        this.renderActiveRoutes();
      }

      // Progressive invalidation ensures container is sized properly
      setTimeout(() => { if (this.map) this.map.invalidateSize(); }, 50);
      setTimeout(() => { if (this.map) this.map.invalidateSize(); }, 200);
      setTimeout(() => { if (this.map) this.map.invalidateSize(); }, 500);

    } catch (err) {
      console.warn("Leaflet map initialization fallback:", err);
      this.renderOfflineCanvasFallback(el, mode);
    }
  }

  applyStandardOsmTiles() {
    if (!this.map) return;

    const primaryUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    const fallbackUrl = 'https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png';

    this.activeTileLayer = L.tileLayer(primaryUrl, {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      errorTileUrl: ''
    });

    let switched = false;
    this.activeTileLayer.on('tileerror', () => {
      if (!switched && this.activeTileLayer) {
        switched = true;
        this.activeTileLayer.setUrl(fallbackUrl);
      }
    });

    this.activeTileLayer.addTo(this.map);
  }

  createVehicleMarker(vehicleType = "", reeferTemp = "3.8°C") {
    let vehicleImg = "assets/vehicles/vehicle_tata_ace.svg";
    let badgeText = "CARRIER";
    let badgeBg = "#111113";

    const v = String(vehicleType || "").toLowerCase();
    if (v.includes("reefer") || v.includes("cold")) {
      vehicleImg = "assets/vehicles/vehicle_reefer.svg";
      badgeText = `REEFER ${reeferTemp}`;
      badgeBg = "#0284C7";
    } else if (v.includes("bike") || v.includes("motorcycle")) {
      vehicleImg = "assets/vehicles/vehicle_bike.svg";
      badgeText = "EXPRESS";
      badgeBg = "#B7791F";
    } else if (v.includes("mini") || v.includes("bolero")) {
      vehicleImg = "assets/vehicles/vehicle_mini_truck.svg";
      badgeText = "RURAL ACE";
      badgeBg = "#3C8D63";
    }

    return L.divIcon({
      className: 'kisan-vehicle-divicon',
      html: `
        <div style="position: relative; display: flex; flex-direction: column; align-items: center; cursor: pointer;">
          <div style="background: #FFFFFF; border: 1px solid #ECECEE; box-shadow: 0 4px 14px rgba(0,0,0,0.1); border-radius: 10px; padding: 4px 8px; display: flex; align-items: center; gap: 6px; white-space: nowrap;">
            <img src="${vehicleImg}" alt="Vehicle" width="34" height="20" style="object-fit: contain;" />
            <span style="background: ${badgeBg}; color: #FFFFFF; font-size: 8.5px; font-weight: 800; padding: 2px 6px; border-radius: 4px; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">${badgeText}</span>
          </div>
          <div style="width: 2px; height: 6px; background: #111113;"></div>
          <div style="width: 5px; height: 5px; border-radius: 50%; background: #111113;"></div>
        </div>
      `,
      iconSize: [120, 42],
      iconAnchor: [60, 42]
    });
  }

  createPinMarker(isOrigin = true) {
    const dotColor = isOrigin ? "#3C8D63" : "#111113";
    const ringColor = isOrigin ? "rgba(60, 141, 99, 0.2)" : "rgba(17, 17, 19, 0.2)";

    return L.divIcon({
      className: 'kisan-pin-divicon',
      html: `
        <div style="position: relative; display: flex; align-items: center; justify-content: center; width: 24px; height: 24px; cursor: pointer;">
          <div style="position: absolute; width: 22px; height: 22px; border-radius: 50%; background: ${ringColor};"></div>
          <div style="position: absolute; width: 14px; height: 14px; border-radius: 50%; background: #FFFFFF; border: 2px solid ${dotColor}; box-shadow: 0 2px 6px rgba(0,0,0,0.15);"></div>
          <div style="position: absolute; width: 6px; height: 6px; border-radius: 50%; background: ${dotColor};"></div>
        </div>
      `,
      iconSize: [24, 24],
      iconAnchor: [12, 12]
    });
  }

  renderActiveRoutes() {
    if (!this.map || !this.routeLayer || !this.markersLayer) return;
    this.routeLayer.clearLayers();
    this.markersLayer.clearLayers();

    const orders = window.kisanDataStore ? window.kisanDataStore.orders : [];
    
    // Select the 3 active live highway telematics corridors (avoiding overlapping duplicate destinations)
    let inTransit = orders.filter(o => o.orderId && o.orderId.startsWith("ORD-LIVE"));
    if (inTransit.length === 0) {
      inTransit = orders.filter(o => o.status === "In Transit").slice(0, 3);
    }

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

    for (const ord of inTransit) {
      // 1. Origin Pin Marker (Clean pin + hover tooltip)
      const originMarker = L.marker([ord.pickupLat, ord.pickupLng], {
        icon: this.createPinMarker(true)
      });
      originMarker.bindTooltip(`${ord.farmer} (${ord.farmerLocation.split(',')[0]})`, {
        direction: 'top',
        offset: [0, -12],
        className: 'kisan-map-tooltip'
      });
      originMarker.bindPopup(`
        <div style="padding: 6px; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
          <div style="font-size: 10px; font-weight: 800; color: #3C8D63; text-transform: uppercase;">Farm Origin Dispatch</div>
          <div style="font-size: 13px; font-weight: bold; margin-top: 2px; color: #0B0B0F;">${ord.farmer}</div>
          <div style="font-size: 11.5px; color: #5F6368;">${ord.farmerLocation}</div>
          <div style="margin-top: 6px; padding: 6px; background: #FAFAFA; border-radius: 6px; border: 1px solid #ECECEE; font-size: 11px;">
            Consignment: <b>${ord.crop} (${ord.qty})</b><br/>
            Security OTP: <b style="font-family: monospace;">${ord.pickupOtp || '4821'}</b>
          </div>
        </div>
      `);

      // 2. Destination Pin Marker (Clean pin + hover tooltip)
      const destMarker = L.marker([ord.dropLat, ord.dropLng], {
        icon: this.createPinMarker(false)
      });
      destMarker.bindTooltip(`${ord.buyer} (${ord.deliveryAddress.split(',')[0]})`, {
        direction: 'top',
        offset: [0, -12],
        className: 'kisan-map-tooltip'
      });
      destMarker.bindPopup(`
        <div style="padding: 6px; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
          <div style="font-size: 10px; font-weight: 800; color: #111113; text-transform: uppercase;">Receiving Mandi Destination</div>
          <div style="font-size: 13px; font-weight: bold; margin-top: 2px; color: #0B0B0F;">${ord.buyer}</div>
          <div style="font-size: 11.5px; color: #5F6368;">${ord.deliveryAddress}</div>
          <div style="margin-top: 6px; font-size: 11px; color: #3C8D63; font-weight: 600;">Receiving Bay Clear - Staff Ready</div>
        </div>
      `);

      // 3. Midpoint Live Vehicle Marker
      const midLat = (ord.pickupLat + ord.dropLat) / 2 + 0.006;
      const midLng = (ord.pickupLng + ord.dropLng) / 2 - 0.006;
      const vehicleMarker = L.marker([midLat, midLng], {
        icon: this.createVehicleMarker(ord.vehicleType, ord.reeferTemp)
      });
      vehicleMarker.bindTooltip(`Order #${ord.orderId} - ${ord.driver} (${ord.etaMinutes}m ETA)`, {
        direction: 'top',
        offset: [0, -22],
        className: 'kisan-map-tooltip'
      });
      vehicleMarker.bindPopup(`
        <div style="padding: 8px; font-family: -apple-system, BlinkMacSystemFont, sans-serif; min-width: 210px;">
          <div style="font-size: 9.5px; font-weight: 800; text-transform: uppercase; color: #5F6368;">Live Transit Telematics</div>
          <div style="font-size: 14px; font-weight: 800; color: #0B0B0F; margin: 2px 0;">Order #${ord.orderId}</div>
          <div style="font-size: 11.5px; color: #5F6368;">Driver: <b>${ord.driver}</b> (${ord.driverPhone})</div>
          <div style="margin-top: 6px; padding: 6px; background: #FAFAFA; border-radius: 8px; border: 1px solid #ECECEE;">
            <div style="font-size: 11px;">Cargo Temperature: <b style="color: #0284C7;">${ord.reeferTemp}</b></div>
            <div style="font-size: 11px; margin-top: 2px;">Distance: <b>${ord.distanceKm} km</b> - ETA: <b>${ord.etaMinutes} mins</b></div>
          </div>
          <button onclick="window.inspectOrderAction('${ord.orderId}')" class="btn btn-secondary" style="width: 100%; margin-top: 8px; padding: 4px; font-size: 11px;">Inspect Consignment</button>
        </div>
      `);

      this.markersLayer.addLayer(originMarker);
      this.markersLayer.addLayer(destMarker);
      this.markersLayer.addLayer(vehicleMarker);

      // 4. Draw Highway Polyline
      const routeColor = ord.vehicleType.toLowerCase().includes("reefer") ? "#0284C7" : "#111113";
      const corridorCoords = highwayCorridors[ord.orderId] || [
        [ord.pickupLat, ord.pickupLng],
        [midLat, midLng],
        [ord.dropLat, ord.dropLng]
      ];
      const polyline = L.polyline(corridorCoords, {
        color: routeColor,
        weight: 3.5,
        opacity: 0.9,
        lineJoin: 'round'
      });
      this.routeLayer.addLayer(polyline);
    }

    // Auto-fit bounds so all active highway corridors, vehicles, and waypoints are perfectly framed
    if (this.markersLayer && this.markersLayer.getLayers().length > 0) {
      try {
        const group = new L.featureGroup(this.markersLayer.getLayers());
        this.map.fitBounds(group.getBounds().pad(0.12), { maxZoom: 11 });
      } catch (_) {}
    }
  }

  renderFieldKycGeospatial() {
    if (!this.map || !this.markersLayer || !this.polygonsLayer) return;
    this.markersLayer.clearLayers();
    this.polygonsLayer.clearLayers();

    // Farmer Land Parcels with Boundary Polygons
    const farms = [
      {
        name: "Ramasamy K. Farm (Kaniyur)",
        acres: 4.5,
        patta: "Patta #7412",
        center: [10.5844, 77.2476],
        polygon: [
          [10.5830, 77.2460], [10.5860, 77.2465], [10.5855, 77.2490], [10.5825, 77.2485]
        ]
      },
      {
        name: "Murugan S. Coconut Grove (Anaimalai)",
        acres: 8.0,
        patta: "Patta #9914",
        center: [10.6609, 77.0048],
        polygon: [
          [10.6580, 77.0020], [10.6630, 77.0030], [10.6620, 77.0070], [10.6570, 77.0060]
        ]
      },
      {
        name: "K. Muthusamy Agro Farm (Kangeyam)",
        acres: 18.4,
        patta: "Patta #1209",
        center: [11.0055, 77.5583],
        polygon: [
          [11.0020, 77.5540], [11.0080, 77.5550], [11.0070, 77.5610], [11.0010, 77.5600]
        ]
      }
    ];

    farms.forEach(f => {
      const poly = L.polygon(f.polygon, {
        color: "#3C8D63",
        fillColor: "#3C8D63",
        fillOpacity: 0.15,
        weight: 2
      }).bindPopup(`
        <div style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 4px;">
          <div style="font-size: 10px; font-weight: 800; color: #3C8D63;">Verified Agricultural Land Parcel</div>
          <div style="font-size: 13px; font-weight: bold; margin-top: 2px;">${f.name}</div>
          <div style="font-size: 11.5px; color: #5F6368;">Area: <b>${f.acres} Acres</b> • ${f.patta}</div>
        </div>
      `);
      this.polygonsLayer.addLayer(poly);

      const pin = L.marker(f.center, { icon: this.createPinMarker(true) });
      pin.bindTooltip(`${f.name} (${f.acres} Acres)`, { direction: 'top', offset: [0, -10] });
      this.markersLayer.addLayer(pin);
    });

    // Commercial Vehicle Depots
    const depots = [
      { name: "Pollachi Commercial Carrier Hub", vehicles: "12 Trucks", pos: [10.6580, 77.0080] },
      { name: "Tiruppur Fleet Depot", vehicles: "18 Trucks", pos: [11.1085, 77.3411] },
      { name: "Coimbatore Central Logistics Yard", vehicles: "24 Reefer Vehicles", pos: [11.0168, 76.9558] }
    ];

    depots.forEach(d => {
      const marker = L.marker(d.pos, {
        icon: this.createVehicleMarker("Mini Truck", "Hub Active")
      });
      marker.bindTooltip(`${d.name} (${d.vehicles})`, { direction: 'top', offset: [0, -20] });
      this.markersLayer.addLayer(marker);
    });
  }

  renderOfflineCanvasFallback(containerEl, mode = "telematics") {
    containerEl.innerHTML = `
      <div style="width: 100%; height: 400px; background: #FAFAFA; border: 1px solid #ECECEE; border-radius: 16px; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 24px; text-align: center; position: relative; overflow: hidden;">
        <div style="position: absolute; top: 16px; left: 20px; text-align: left;">
          <span style="background: #FFFFFF; border: 1px solid #ECECEE; border-radius: 6px; padding: 3px 8px; font-size: 10px; font-weight: 700; color: #3C8D63;">REAL-TIME TELEMATICS ACTIVE</span>
          <div style="font-size: 14px; font-weight: 800; color: #0B0B0F; margin-top: 4px;">Tamil Nadu Agro-Logistics Highway Corridor</div>
        </div>

        <svg viewBox="0 0 700 220" width="100%" height="220" style="max-width: 680px; margin-top: 20px;">
          <path d="M 60 160 Q 220 140 350 100 T 640 50" fill="none" stroke="#111113" stroke-width="3" stroke-linecap="round"/>
          <path d="M 60 160 Q 220 140 350 100 T 640 50" fill="none" stroke="#0284C7" stroke-width="2" stroke-dasharray="6, 8"/>
          
          <circle cx="60" cy="160" r="7" fill="#3C8D63" stroke="#FFFFFF" stroke-width="2"/>
          <text x="60" y="185" font-family="-apple-system, sans-serif" font-size="11" font-weight="bold" text-anchor="middle" fill="#0B0B0F">Udumalpet Farm</text>

          <rect x="220" y="115" width="130" height="32" rx="8" fill="#FFFFFF" stroke="#ECECEE" filter="drop-shadow(0 2px 6px rgba(0,0,0,0.08))"/>
          <text x="230" y="130" font-family="-apple-system, sans-serif" font-size="10" font-weight="bold" fill="#0284C7">REEFER TN-38-BZ-4412</text>
          <text x="230" y="142" font-family="-apple-system, sans-serif" font-size="9" fill="#5F6368">Temp 3.8°C • 44m ETA</text>

          <circle cx="350" cy="100" r="7" fill="#111113" stroke="#FFFFFF" stroke-width="2"/>
          <text x="350" y="85" font-family="-apple-system, sans-serif" font-size="11" font-weight="bold" text-anchor="middle" fill="#0B0B0F">Ukkadam Wholesale Mandi</text>

          <circle cx="120" cy="60" r="6" fill="#3C8D63" stroke="#FFFFFF" stroke-width="2"/>
          <text x="120" y="46" font-family="-apple-system, sans-serif" font-size="10" font-weight="bold" text-anchor="middle" fill="#0B0B0F">Pollachi Foothills</text>
          
          <path d="M 120 60 L 350 100" fill="none" stroke="#B7791F" stroke-width="2" stroke-dasharray="4, 4"/>
          
          <circle cx="480" cy="130" r="6" fill="#3C8D63" stroke="#FFFFFF" stroke-width="2"/>
          <text x="480" y="150" font-family="-apple-system, sans-serif" font-size="10" font-weight="bold" text-anchor="middle" fill="#0B0B0F">Tiruppur Hub</text>
          <circle cx="640" cy="50" r="7" fill="#111113" stroke="#FFFFFF" stroke-width="2"/>
          <text x="640" y="36" font-family="-apple-system, sans-serif" font-size="11" font-weight="bold" text-anchor="middle" fill="#0B0B0F">Erode Central Mandi</text>
        </svg>

        <div style="margin-top: 10px; display: flex; gap: 10px; flex-wrap: wrap; justify-content: center;">
          <span style="font-size: 11px; background: #FFFFFF; border: 1px solid #ECECEE; padding: 4px 12px; border-radius: 20px; font-weight: 600; color: #0B0B0F;">NH-83: Udumalpet to Ukkadam (68.4 km)</span>
          <span style="font-size: 11px; background: #FFFFFF; border: 1px solid #ECECEE; padding: 4px 12px; border-radius: 20px; font-weight: 600; color: #0284C7;">Cold Chain Active (3.8°C Target)</span>
          <span style="font-size: 11px; background: #FFFFFF; border: 1px solid #ECECEE; padding: 4px 12px; border-radius: 20px; font-weight: 600; color: #3C8D63;">OpenStreetMap Keyless</span>
        </div>
      </div>
    `;
  }
}

window.kisanMapEngine = new KisanMapEngine();
