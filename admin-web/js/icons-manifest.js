/**
 * KisanAI Enterprise Admin — Central Icons & Assets Manifest
 * Single source of truth for all visual assets (SVGs, portraits, vehicles, crops).
 * ZERO EMOJI POLICY: All pictographs and glyphs are rendered via this manifest.
 */

const KISAN_ICONS = {
  // Brand Logo & Favicon
  logo: "assets/icons/kisan_logo.svg",
  favicon: "assets/icons/kisan_favicon.svg",
  hero_banner: "assets/images/hero_banner.jpg",

  // Navigation Icons
  nav_executive: "assets/icons/nav_executive.svg",
  nav_fleet: "assets/icons/nav_fleet.svg",
  nav_users: "assets/icons/nav_users.svg",
  nav_orders: "assets/icons/nav_orders.svg",
  nav_finance: "assets/icons/nav_finance.svg",
  nav_quality: "assets/icons/nav_quality.svg",
  nav_audit: "assets/icons/nav_audit.svg",
  nav_settings: "assets/icons/nav_settings.svg",
  nav_support: "assets/icons/nav_support.svg",
  nav_kyc: "assets/icons/nav_kyc.svg",
  nav_catalogue: "assets/icons/nav_catalogue.svg",
  nav_disputes: "assets/icons/nav_disputes.svg",

  // Action & Utility Icons
  icon_bell: "assets/icons/icon_bell.svg",
  icon_close: "assets/icons/icon_close.svg",
  icon_check: "assets/icons/icon_check.svg",
  icon_filter: "assets/icons/icon_filter.svg",
  icon_download: "assets/icons/icon_download.svg",
  icon_eye: "assets/icons/icon_eye.svg",
  icon_shield: "assets/icons/icon_shield.svg",
  icon_message: "assets/icons/icon_message.svg",
  icon_map_pin: "assets/icons/icon_map_pin.svg",
  icon_calendar: "assets/icons/icon_calendar.svg",
  icon_user: "assets/icons/icon_user.svg",
  icon_search: "assets/icons/icon_search.svg",

  // Role Portraits
  role_super_admin: "assets/roles/role_super_admin.svg",
  role_ops_manager: "assets/roles/role_ops_manager.svg",
  role_support_agent: "assets/roles/support_agent.svg",
  role_quality_officer: "assets/roles/role_quality_officer.svg",
  role_finance_officer: "assets/roles/role_finance_officer.svg",
  role_field_officer: "assets/roles/role_field_officer.svg",

  // Vehicles
  vehicle_reefer: "assets/vehicles/vehicle_reefer.svg",
  vehicle_tata_ace: "assets/vehicles/vehicle_tata_ace.svg",
  vehicle_mini_truck: "assets/vehicles/vehicle_mini_truck.svg",
  vehicle_bike: "assets/vehicles/vehicle_bike.svg",

  // Crops
  crop_tomato: "assets/crops/crop_tomato.svg",
  crop_banana: "assets/crops/crop_banana.svg",
  crop_onion: "assets/crops/crop_onion.svg",
  crop_potato: "assets/crops/crop_potato.svg",
};

class KisanIcons {
  static getUrl(name) {
    return KISAN_ICONS[name] || KISAN_ICONS.logo;
  }

  static render(name, size = 20, className = "") {
    const url = this.getUrl(name);
    return `<img src="${url}" alt="${name}" width="${size}" height="${size}" class="kisan-icon ${className}" loading="lazy" style="display: inline-block; vertical-align: middle;" />`;
  }

  static getRoleAvatar(roleId, size = 32) {
    let key = "role_super_admin";
    if (roleId === "ops_manager") key = "role_ops_manager";
    else if (roleId === "support_agent") key = "role_support_agent";
    else if (roleId === "quality_officer") key = "role_quality_officer";
    else if (roleId === "finance_officer") key = "role_finance_officer";
    else if (roleId === "field_officer") key = "role_field_officer";
    return `<img src="${KISAN_ICONS[key]}" alt="${roleId}" width="${size}" height="${size}" class="role-avatar-img" style="border-radius: 50%; display: inline-block; vertical-align: middle;" />`;
  }

  static getVehicleIcon(vehicleString = "", size = 38) {
    const v = String(vehicleString || "").toLowerCase();
    let key = "vehicle_tata_ace";
    if (v.includes("reefer") || v.includes("cold")) key = "vehicle_reefer";
    else if (v.includes("bike") || v.includes("motorcycle")) key = "vehicle_bike";
    else if (v.includes("mini") || v.includes("ape") || v.includes("bolero")) key = "vehicle_mini_truck";
    return `<img src="${KISAN_ICONS[key]}" alt="${vehicleString}" width="${size}" class="vehicle-marker-img" style="display: inline-block; vertical-align: middle;" />`;
  }

  static getCropIcon(cropName = "", size = 24) {
    const c = String(cropName || "").toLowerCase();
    let key = "crop_tomato";
    if (c.includes("banana")) key = "crop_banana";
    else if (c.includes("onion")) key = "crop_onion";
    else if (c.includes("potato")) key = "crop_potato";
    return `<img src="${KISAN_ICONS[key]}" alt="${cropName}" width="${size}" height="${size}" class="crop-badge-img" style="display: inline-block; vertical-align: middle; border-radius: 4px;" />`;
  }
}

window.kisanIcons = KisanIcons;
