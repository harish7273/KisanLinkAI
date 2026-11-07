/**
 * KisanAI Enterprise Admin — Central Role & Permissions Store
 * Single source of truth for Role-Based Access Control (RBAC),
 * route guards, permission enforcement, and role switching.
 * ZERO EMOJI POLICY: All avatars and icons use clean SVG asset keys.
 */

const ROLE_SWITCHER_CONFIG = {
  // Mode: "open" (demo/testing: anyone can switch), "head-only" (only super_admin), "off" (production login only)
  MODE: "open", 
  DEFAULT_ROLE: "super_admin",
  STORAGE_KEY: "kisanai_admin_role",
};

const ROLES_DEFINITION = {
  super_admin: {
    id: "super_admin",
    nameEn: "Head / Super Admin",
    nameTa: "தலைவர் / முதன்மை நிர்வாகி",
    nameHi: "प्रमुख / सुपर एडमिन",
    avatar: "role_super_admin",
    route: "#/admin/executive",
    descriptionEn: "Full company governance, executive KPIs, GMV, staff management & audit trail.",
    descriptionTa: "முழு நிறுவன ஆளுகை, உயர்நிலை அளவீடுகள், விற்பனைத் தொகை மற்றும் தணிக்கை பதிவு.",
    descriptionHi: "पूर्ण कंपनी शासन, कार्यकारी केपीआई, सकल बिक्री, कर्मचारी एवं ऑडिट लॉग।",
    permissions: [
      "view_executive", "view_operations", "view_support", "view_quality", 
      "view_finance", "view_field_kyc", "manage_staff", "view_audit_logs", 
      "export_reports", "system_settings", "reassign_partner", "approve_payout", 
      "approve_kyc", "override_grade", "resolve_dispute"
    ],
    allowedRoutes: [
      "#/admin/executive", "#/admin/operations", "#/admin/support", 
      "#/admin/quality", "#/admin/finance", "#/admin/field-kyc", 
      "#/admin/users", "#/admin/orders", "#/admin/disputes", 
      "#/admin/audit", "#/admin/settings", "#/admin/profile"
    ],
    navItems: [
      { id: "nav-executive", label: "Executive Overview", route: "#/admin/executive", icon: "nav_executive" },
      { id: "nav-operations", label: "Live Fleet & Dispatch", route: "#/admin/operations", icon: "nav_fleet" },
      { id: "nav-users", label: "Users & Staff Directory", route: "#/admin/users", icon: "nav_users" },
      { id: "nav-orders", label: "Orders & Lifecycle", route: "#/admin/orders", icon: "nav_orders" },
      { id: "nav-finance", label: "Treasury & Finance", route: "#/admin/finance", icon: "nav_finance" },
      { id: "nav-quality", label: "Quality Oversight", route: "#/admin/quality", icon: "nav_quality" },
      { id: "nav-audit", label: "Immutable Audit Log", route: "#/admin/audit", icon: "nav_audit" },
      { id: "nav-settings", label: "Platform Controls", route: "#/admin/settings", icon: "nav_settings" },
    ]
  },

  ops_manager: {
    id: "ops_manager",
    nameEn: "Operations Manager",
    nameTa: "செயல்பாட்டு மேலாளர்",
    nameHi: "परिचालन प्रबंधक",
    avatar: "role_ops_manager",
    route: "#/admin/operations",
    descriptionEn: "Live logistics dispatch, reefer fleet monitoring, route delays & partner reassignment.",
    descriptionTa: "நேரடி போக்குவரத்து மேலாண்மை, குளிர்பதன வாகனம், வழித்தட தாமதம் & ஓட்டுநர் ஒதுக்கீடு.",
    descriptionHi: "लाइव लॉजिस्टिक्स डिस्पैच, रीफर फ्लीट मॉनिटरिंग, रूट देरी एवं वाहन आवंटन।",
    permissions: [
      "view_operations", "reassign_partner", "view_orders", "view_disputes", 
      "resolve_dispute", "view_live_telematics"
    ],
    allowedRoutes: [
      "#/admin/operations", "#/admin/orders", "#/admin/disputes", "#/admin/profile"
    ],
    navItems: [
      { id: "nav-operations", label: "Dispatch Deck & Map", route: "#/admin/operations", icon: "nav_fleet" },
      { id: "nav-orders", label: "Order Pipeline", route: "#/admin/orders", icon: "nav_orders" },
      { id: "nav-disputes", label: "Delivery Disputes", route: "#/admin/disputes", icon: "nav_disputes" },
    ]
  },

  support_agent: {
    id: "support_agent",
    nameEn: "Support Agent",
    nameTa: "வாடிக்கையாளர் ஆதரவாளர்",
    nameHi: "ग्राहक सहायता एजेंट",
    avatar: "role_support_agent",
    route: "#/admin/support",
    descriptionEn: "User ticket inbox, SLA clocks, customer order lookup & real-time dispute chat.",
    descriptionTa: "பயனர் உதவி டிக்கெட்டுகள், வாடிக்கையாளர் தேடல் & சர்ச்சை தீர்வு அரட்டை.",
    descriptionHi: "उपयोगकर्ता टिकट, एसएलए टाइमर, ऑर्डर पूछताछ एवं समाधान चैट।",
    permissions: [
      "view_support", "view_tickets", "reply_tickets", "lookup_users", 
      "view_orders", "view_disputes", "resolve_dispute"
    ],
    allowedRoutes: [
      "#/admin/support", "#/admin/orders", "#/admin/disputes", "#/admin/profile"
    ],
    navItems: [
      { id: "nav-support", label: "Support Inbox & SLA", route: "#/admin/support", icon: "nav_support" },
      { id: "nav-orders", label: "Order History Lookup", route: "#/admin/orders", icon: "nav_orders" },
      { id: "nav-disputes", label: "Dispute Queue", route: "#/admin/disputes", icon: "nav_disputes" },
    ]
  },

  quality_officer: {
    id: "quality_officer",
    nameEn: "Quality / Agronomist",
    nameTa: "தரக்கட்டுப்பாடு / வேளாண் அதிகாரி",
    nameHi: "गुणवत्ता / कृषि विशेषज्ञ",
    avatar: "role_quality_officer",
    route: "#/admin/quality",
    descriptionEn: "AI scanner verification (HITL), AGMARK standards, defect calibration & crop catalogue.",
    descriptionTa: "AI தரக்கட்டுப்பாடு சரிபார்ப்பு, அக்மார்க் தர நிர்ணயம் & பயிர் பட்டியல் மேலாண்மை.",
    descriptionHi: "एआई स्कैनर निरीक्षण, एगमार्क मानक, दोष दर एवं फसल सूची प्रबंधन।",
    permissions: [
      "view_quality", "override_grade", "manage_catalogue", "export_training_set"
    ],
    allowedRoutes: [
      "#/admin/quality", "#/admin/profile"
    ],
    navItems: [
      { id: "nav-quality", label: "Scanner Oversight (HITL)", route: "#/admin/quality", icon: "nav_quality" },
      { id: "nav-catalogue", label: "Crop & Grading Rules", route: "#/admin/quality?tab=catalogue", icon: "nav_catalogue" },
    ]
  },

  finance_officer: {
    id: "finance_officer",
    nameEn: "Finance Officer",
    nameTa: "நிதி அதிகாரி",
    nameHi: "वित्त अधिकारी",
    avatar: "role_finance_officer",
    route: "#/admin/finance",
    descriptionEn: "Wallet payouts ledger, bank/UPI UTR confirmation, delivery splits & GST reconciliation.",
    descriptionTa: "பணப்பரிவர்த்தனை தீர்வு, வங்கி UTR பதிவு, கமிஷன் பிரிப்பு & GST அறிக்கை.",
    descriptionHi: "वॉलेट भुगतान निपटान, बैंक/यूपीआई यूटीआर, डिलीवरी शुल्क एवं जीएसटी रिपोर्ट।",
    permissions: [
      "view_finance", "approve_payout", "export_gst_csv", "view_ledger"
    ],
    allowedRoutes: [
      "#/admin/finance", "#/admin/profile"
    ],
    navItems: [
      { id: "nav-finance", label: "Wallet & Payouts Ledger", route: "#/admin/finance", icon: "nav_finance" },
      { id: "nav-settlements", label: "Reconciliation & GST", route: "#/admin/finance?tab=reconciliation", icon: "nav_finance" },
    ]
  },

  field_officer: {
    id: "field_officer",
    nameEn: "Field Verification Officer",
    nameTa: "கள சரிபார்ப்பு அதிகாரி",
    nameHi: "क्षेत्रीय सत्यापन अधिकारी",
    avatar: "role_field_officer",
    route: "#/admin/field-kyc",
    descriptionEn: "Ground KYC audit, Land Patta deeds inspection, vehicle RC & farm geotagging.",
    descriptionTa: "நேரடி KYC சரிபார்ப்பு, பட்டா ஆவண ஆய்வு, வாகன பதிவு & நில வரைபட குறியீடு.",
    descriptionHi: "जमीनी केवाईसी सत्यापन, भूमि पट्टा दस्तावेज, वाहन आरसी एवं जियो-टैगिंग।",
    permissions: [
      "view_field_kyc", "approve_kyc", "reject_kyc", "verify_vehicle"
    ],
    allowedRoutes: [
      "#/admin/field-kyc", "#/admin/profile"
    ],
    navItems: [
      { id: "nav-field-kyc", label: "KYC Verification Desk", route: "#/admin/field-kyc", icon: "nav_kyc" },
      { id: "nav-field-map", label: "Farm & Vehicle Map", route: "#/admin/field-kyc?tab=map", icon: "nav_fleet" },
    ]
  }
};

const STAFF_PROFILES = {
  super_admin: {
    name: "Directorate Officer",
    title: "KisanAI Central Node",
    dept: "Central Governance & Directorate",
    email: "directorate@kisanai.in",
    phone: "+91 94421 00001",
    empId: "EMP-HQ-001",
    sessionStarted: "Today, 08:30 AM",
    accessLevel: "Tier 1 — Full System Administration"
  },
  ops_manager: {
    name: "Karthikeyan P.",
    title: "Logistics & Fleet Command",
    dept: "Operations & Telematics Dispatch",
    email: "karthik.ops@kisanai.in",
    phone: "+91 98944 88201",
    empId: "EMP-OPS-042",
    sessionStarted: "Today, 09:15 AM",
    accessLevel: "Tier 2 — Dispatch & Route Operations"
  },
  support_agent: {
    name: "Divya Balan",
    title: "Senior Escalation Specialist",
    dept: "Customer Experience & Dispute Desk",
    email: "divya.support@kisanai.in",
    phone: "+91 97861 33412",
    empId: "EMP-SUP-108",
    sessionStarted: "Today, 09:45 AM",
    accessLevel: "Tier 3 — Customer Resolution & Tickets"
  },
  quality_officer: {
    name: "Dr. Priya Sundaram",
    title: "Chief Agronomist & CV Specialist",
    dept: "Agronomy & Computer Vision Lab",
    email: "dr.priya@kisanai.in",
    phone: "+91 94430 77124",
    empId: "EMP-AGR-019",
    sessionStarted: "Today, 08:50 AM",
    accessLevel: "Tier 2 — AGMARK Standards & HITL"
  },
  finance_officer: {
    name: "Venkatesh Raman",
    title: "Head of Treasury & Settlement",
    dept: "Treasury & Escrow Settlements",
    email: "venkat.finance@kisanai.in",
    phone: "+91 98422 66500",
    empId: "EMP-FIN-007",
    sessionStarted: "Today, 10:00 AM",
    accessLevel: "Tier 2 — Payouts & GST Ledger"
  },
  field_officer: {
    name: "Anitha Muthukumar",
    title: "Senior Field Verification Officer",
    dept: "Ground Inspection & Land Audit",
    email: "anitha.kyc@kisanai.in",
    phone: "+91 96555 44219",
    empId: "EMP-FLD-053",
    sessionStarted: "Today, 08:00 AM",
    accessLevel: "Tier 3 — Ground KYC & Land Patta"
  }
};

class KisanRoleStore {
  constructor() {
    this.currentRole = this._loadInitialRole();
    this.listeners = [];
  }

  _loadInitialRole() {
    const saved = localStorage.getItem(ROLE_SWITCHER_CONFIG.STORAGE_KEY);
    if (saved && ROLES_DEFINITION[saved]) {
      return saved;
    }
    const hash = window.location.hash;
    if (hash) {
      for (const [roleKey, roleDef] of Object.entries(ROLES_DEFINITION)) {
        if (roleDef.route === hash) {
          localStorage.setItem(ROLE_SWITCHER_CONFIG.STORAGE_KEY, roleKey);
          return roleKey;
        }
      }
    }
    return ROLE_SWITCHER_CONFIG.DEFAULT_ROLE;
  }

  getRole() {
    return this.currentRole;
  }

  getRoleDef(roleId = this.currentRole) {
    return ROLES_DEFINITION[roleId] || ROLES_DEFINITION.super_admin;
  }

  getStaffProfile(roleId = this.currentRole) {
    return STAFF_PROFILES[roleId] || STAFF_PROFILES.super_admin;
  }

  getAllRoles() {
    return Object.values(ROLES_DEFINITION);
  }

  hasPermission(permission) {
    const roleDef = this.getRoleDef();
    return roleDef.permissions.includes(permission);
  }

  isRouteAllowed(route) {
    const roleDef = this.getRoleDef();
    const base = route.split('?')[0];
    return roleDef.allowedRoutes.some(r => base.startsWith(r));
  }

  switchRole(newRoleId, reason = "User selected from dropdown") {
    if (!ROLES_DEFINITION[newRoleId]) {
      console.error(`Invalid role: ${newRoleId}`);
      return false;
    }

    if (ROLE_SWITCHER_CONFIG.MODE === "off") {
      alert("Role switcher is disabled in production mode.");
      return false;
    }
    if (ROLE_SWITCHER_CONFIG.MODE === "head-only" && this.currentRole !== "super_admin") {
      alert("Only Super Admin / Head is permitted to switch view contexts.");
      return false;
    }

    const previousRole = this.currentRole;
    this.currentRole = newRoleId;

    localStorage.setItem(ROLE_SWITCHER_CONFIG.STORAGE_KEY, newRoleId);
    this._logRoleSwitchAudit(previousRole, newRoleId, reason);

    const targetRoute = ROLES_DEFINITION[newRoleId].route;
    window.location.hash = targetRoute;

    this.listeners.forEach(fn => fn(newRoleId, previousRole));
    return true;
  }

  _logRoleSwitchAudit(fromRole, toRole, reason) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      action: "SWITCH_ROLE",
      actor: "STAFF_SESSION",
      fromRole: fromRole,
      toRole: toRole,
      details: reason,
    };
    try {
      const logs = JSON.parse(localStorage.getItem('kisanai_audit_logs') || '[]');
      logs.unshift(logEntry);
      localStorage.setItem('kisanai_audit_logs', JSON.stringify(logs.slice(0, 100)));
    } catch (_) {}
  }

  subscribe(listener) {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter(fn => fn !== listener);
    };
  }
}

window.kisanRoleStore = new KisanRoleStore();
