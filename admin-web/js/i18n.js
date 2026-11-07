/**
 * KisanAI Enterprise Admin — Internationalization (i18n) Engine
 * Full trilingual translation dictionary for English, Tamil, and Hindi.
 * ZERO EMOJI POLICY.
 */

const KISAN_TRANSLATIONS = {
  en: {
    app_title: "KisanAI HQ",
    app_subtitle: "Enterprise Operations Deck",
    viewing_as: "Viewing as:",
    switch_role: "Switch Active Role",
    search_placeholder: "Search farmers, buyers, orders, vehicles (Ctrl+K)...",
    notifications: "Notifications",
    theme_light: "Light Mode",
    theme_dark: "Dark Mode",
    refresh_data: "Refresh Data",
    access_denied_title: "Access Restricted",
    access_denied_desc: "Your active role does not have authorization to view this module.",
    back_to_workspace: "Return to My Workspace",
    
    // Status badges
    status_delivered: "Delivered",
    status_transit: "In Transit",
    status_pending: "Pending",
    status_approved: "Approved",
    status_rejected: "Rejected",
    status_open: "Open",
    status_in_review: "In Review",
    status_resolved: "Resolved",

    // Roles
    role_super_admin: "Head / Super Admin",
    role_ops_manager: "Operations Manager",
    role_support_agent: "Support Agent",
    role_quality_officer: "Quality / Agronomist",
    role_finance_officer: "Finance Officer",
    role_field_officer: "Field Officer",

    // Sections & Titles
    gmv_title: "Gross Merchandise Value",
    active_fleet_title: "Active Logistics Fleet",
    cv_pass_title: "AI Quality Pass Rate",
    pending_kyc_title: "Pending KYC Audits",
    active_orders_title: "Active Orders",
    reefer_active_title: "Cold Chain Active",
    sla_compliance_title: "Support SLA On-Time",
    pending_payouts_title: "Pending Payout Amount",
    audit_chain_title: "Immutable Audit Log",
    platform_controls_title: "Platform Governance Controls",
    crop_rules_title: "AGMARK Crop & Grading Rules",
    reconciliation_title: "Daily GST & Bank Reconciliation",
    farm_map_title: "Geospatial Land & Fleet Map",
    profile_title: "Staff Account & Profile",

    // Action buttons
    action_approve: "Approve",
    action_reject: "Reject",
    action_reassign: "Reassign",
    action_track: "Track Live",
    action_export: "Export CSV",
    action_release: "Release Payout",
    action_audit: "Audit Trail",
    action_inspect: "Inspect",
    action_open_chat: "Open Chat",
    action_verify_grade: "Verify Grade"
  },

  ta: {
    app_title: "கிசான் ஏஐ HQ",
    app_subtitle: "ஒருங்கிணைந்த செயல்பாட்டு தளம்",
    viewing_as: "செயல்பாட்டு பங்கு:",
    switch_role: "பங்கு மாற்றம்",
    search_placeholder: "விவசாயிகள், ஆர்டர்கள், வாகனங்களைத் தேடுங்கள் (Ctrl+K)...",
    notifications: "அறிவிப்புகள்",
    theme_light: "பகல் பயன்முறை",
    theme_dark: "இரவு பயன்முறை",
    refresh_data: "தரவை புதுப்பி",
    access_denied_title: "அணுகல் தடைசெய்யப்பட்டுள்ளது",
    access_denied_desc: "இந்த தொகுதியைக் காண உங்கள் தற்போதைய பங்குக்கு அனுமதி இல்லை.",
    back_to_workspace: "எனது பணித்தளத்திற்கு திரும்பு",

    // Status badges
    status_delivered: "டெலிவரி செய்யப்பட்டது",
    status_transit: "போக்குவரத்தில் உள்ளது",
    status_pending: "நிலுவையில் உள்ளது",
    status_approved: "ஒப்புதல் அளிக்கப்பட்டது",
    status_rejected: "நிராகரிக்கப்பட்டது",
    status_open: "திறந்துள்ளது",
    status_in_review: "ஆய்வில் உள்ளது",
    status_resolved: "தீர்க்கப்பட்டது",

    // Roles
    role_super_admin: "தலைவர் / முதன்மை நிர்வாகி",
    role_ops_manager: "செயல்பாட்டு மேலாளர்",
    role_support_agent: "வாடிக்கையாளர் ஆதரவாளர்",
    role_quality_officer: "தரக்கட்டுப்பாடு அதிகாரி",
    role_finance_officer: "நிதி அதிகாரி",
    role_field_officer: "கள அதிகாரி",

    // Sections & Titles
    gmv_title: "மொத்த விற்பனை மதிப்பு (GMV)",
    active_fleet_title: "செயலில் உள்ள வாகனங்கள்",
    cv_pass_title: "AI தர தேர்ச்சி விகிதம்",
    pending_kyc_title: "நிலுவையில் உள்ள KYC ஆய்வுகள்",
    active_orders_title: "செயலில் உள்ள ஆர்டர்கள்",
    reefer_active_title: "குளிர்பதன போக்குவரத்து",
    sla_compliance_title: "உதவி மைய SLA துல்லியம்",
    pending_payouts_title: "நிலுவை பணப்பட்டுவாடா",
    audit_chain_title: "மாற்ற முடியாத தணிக்கை பதிவு",
    platform_controls_title: "தள ஆளுகை கட்டுப்பாடுகள்",
    crop_rules_title: "அக்மார்க் பயிர் தர நிர்ணய விதிகள்",
    reconciliation_title: "தினசரி GST & வங்கி தீர்வு",
    farm_map_title: "நிலம் & வாகன வரைபடம்",
    profile_title: "அலுவலர் சுயவிவரம்",

    // Action buttons
    action_approve: "ஒப்புதல் செய்",
    action_reject: "நிராகரி",
    action_reassign: "மாற்றி அமை",
    action_track: "நேரடி கண்காணிப்பு",
    action_export: "CSV பதிவிறக்கம்",
    action_release: "பணப்பட்டுவாடா",
    action_audit: "தணிக்கை பதிவு",
    action_inspect: "ஆய்வு செய்",
    action_open_chat: "உரையாடலைத் திற",
    action_verify_grade: "தரத்தை உறுதிசெய்"
  },

  hi: {
    app_title: "किसान एआई मुख्यालय",
    app_subtitle: "उद्यम परिचालन नियंत्रण केंद्र",
    viewing_as: "कार्यकारी पद:",
    switch_role: "भूमिका बदलें",
    search_placeholder: "किसान, खरीदार, ऑर्डर, वाहन खोजें (Ctrl+K)...",
    notifications: "सूचनाएं",
    theme_light: "लाइट मोड",
    theme_dark: "डार्क मोड",
    refresh_data: "डेटा रिफ्रेश करें",
    access_denied_title: "पहुंच प्रतिबंधित",
    access_denied_desc: "आपकी वर्तमान भूमिका को इस मॉड्यूल को देखने की अनुमति नहीं है।",
    back_to_workspace: "मेरे कार्यक्षेत्र पर लौटें",

    // Status badges
    status_delivered: "वितरित",
    status_transit: "मार्ग में है",
    status_pending: "लंबित",
    status_approved: "स्वीकृत",
    status_rejected: "अस्वीकृत",
    status_open: "खुला है",
    status_in_review: "समीक्षाधीन",
    status_resolved: "हल किया गया",

    // Roles
    role_super_admin: "प्रमुख / सुपर एडमिन",
    role_ops_manager: "परिचालन प्रबंधक",
    role_support_agent: "ग्राहक सहायता एजेंट",
    role_quality_officer: "गुणवत्ता / कृषि विशेषज्ञ",
    role_finance_officer: "वित्त अधिकारी",
    role_field_officer: "क्षेत्रीय सत्यापन अधिकारी",

    // Sections & Titles
    gmv_title: "सकल व्यापार मूल्य (GMV)",
    active_fleet_title: "सक्रिय वाहन बेड़ा",
    cv_pass_title: "एआई गुणवत्ता पास दर",
    pending_kyc_title: "लंबित केवाईसी सत्यापन",
    active_orders_title: "सक्रिय ऑर्डर",
    reefer_active_title: "कोल्ड चेन सक्रिय",
    sla_compliance_title: "सहायता एसएलए समयबद्धता",
    pending_payouts_title: "लंबित भुगतान राशि",
    audit_chain_title: "अपरिवर्तनीय ऑडिट लॉग",
    platform_controls_title: "प्लेटफ़ॉर्म नियंत्रण एवं सेटिंग्स",
    crop_rules_title: "एगमार्क फसल एवं ग्रेडिंग मानक",
    reconciliation_title: "दैनिक जीएसटी एवं बैंक समाधान",
    farm_map_title: "भूमि एवं वाहन मानचित्र",
    profile_title: "अधिकारी खाता प्रोफ़ाइल",

    // Action buttons
    action_approve: "स्वीकृत करें",
    action_reject: "अस्वीकार करें",
    action_reassign: "पुनः आवंटित करें",
    action_track: "लाइव ट्रैक",
    action_export: "सीएसवी निर्यात",
    action_release: "भुगतान जारी करें",
    action_audit: "ऑडिट लॉग",
    action_inspect: "निरीक्षण करें",
    action_open_chat: "चैट खोलें",
    action_verify_grade: "ग्रेड सत्यापित करें"
  }
};

class KisanI18n {
  constructor() {
    this.locale = localStorage.getItem('kisanai_admin_lang') || 'en';
    this.listeners = [];
  }

  getLocale() {
    return this.locale;
  }

  setLocale(lang) {
    if (!KISAN_TRANSLATIONS[lang]) return;
    this.locale = lang;
    localStorage.setItem('kisanai_admin_lang', lang);
    this.listeners.forEach(fn => fn(lang));
  }

  t(key) {
    const dict = KISAN_TRANSLATIONS[this.locale] || KISAN_TRANSLATIONS.en;
    return dict[key] || KISAN_TRANSLATIONS.en[key] || key;
  }

  subscribe(listener) {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter(fn => fn !== listener);
    };
  }
}

window.kisanI18n = new KisanI18n();
