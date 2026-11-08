import os
import sys
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        
        # Header (Pages 2+)
        if self._pageNumber > 1:
            self.drawString(36, 810, "KisanAI Enterprise Master System Report  -  Delivery & Architecture")
            self.drawRightString(559, 810, "Version 2.1.0 | Build 21")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.5)
            self.line(36, 804, 559, 804)

        # Footer (All pages)
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.5)
        self.line(36, 36, 559, 36)
        
        self.drawString(36, 24, "CONFIDENTIAL & PROPRIETARY  -  KisanAI Central Node")
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(559, 24, page_str)
        self.restoreState()

def build_pdf(filename="KisanAI_Master_System_Report.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=45,
        bottomMargin=45
    )

    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=22,
        leading=26,
        textColor=colors.HexColor("#0F172A"),
        spaceAfter=4
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        textColor=colors.HexColor("#475569"),
        spaceAfter=15
    )
    
    h1_style = ParagraphStyle(
        'SecH1',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=16,
        textColor=colors.HexColor("#0F172A"),
        spaceBefore=12,
        spaceAfter=6,
        keepWithNext=True
    )
    
    h2_style = ParagraphStyle(
        'SecH2',
        parent=styles['Heading3'],
        fontName='Helvetica-Bold',
        fontSize=10.5,
        leading=14,
        textColor=colors.HexColor("#16A34A"),
        spaceBefore=8,
        spaceAfter=4,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor("#1E293B"),
        spaceAfter=5
    )
    
    body_bold = ParagraphStyle(
        'BodyBold',
        parent=body_style,
        fontName='Helvetica-Bold'
    )
    
    bullet_style = ParagraphStyle(
        'BulletText',
        parent=body_style,
        leftIndent=12,
        firstLineIndent=-8,
        spaceAfter=3
    )

    code_style = ParagraphStyle(
        'CodeText',
        parent=body_style,
        fontName='Courier',
        fontSize=7.5,
        leading=10,
        textColor=colors.HexColor("#0F172A"),
        backColor=colors.HexColor("#F1F5F9"),
        borderPadding=4
    )
    
    callout_style = ParagraphStyle(
        'CalloutText',
        parent=body_style,
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor("#065F46"),
        backColor=colors.HexColor("#ECFDF5"),
        borderColor=colors.HexColor("#A7F3D0"),
        borderWidth=1,
        borderPadding=6,
        spaceAfter=8
    )

    table_header = ParagraphStyle(
        'TH',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9.5,
        textColor=colors.white
    )
    
    table_cell = ParagraphStyle(
        'TC',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7.5,
        leading=9.5,
        textColor=colors.HexColor("#1E293B")
    )
    
    table_cell_bold = ParagraphStyle(
        'TCB',
        parent=table_cell,
        fontName='Helvetica-Bold'
    )

    story = []

    # ----------------------------------------------------
    # COVER / HEADER
    # ----------------------------------------------------
    story.append(Paragraph("KisanAI Enterprise Master System Report", title_style))
    story.append(Paragraph("Complete Technical Audit, Architecture Implementation, APK Size Reduction Analysis, and Production Verification (Phases 0  -  8)", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#16A34A"), spaceAfter=12))

    # Meta banner table
    meta_data = [
        [
            Paragraph("<b>Version:</b> 2.1.0 (Build 21)", table_cell),
            Paragraph("<b>Status:</b> Production Ready & Verified", table_cell),
            Paragraph("<b>Website:</b> https://harish7273.github.io/KisanLinkAI/", table_cell)
        ],
        [
            Paragraph("<b>Target Environment:</b> Production / Demo Dual-Mode", table_cell),
            Paragraph("<b>Test Suite Result:</b> 19 / 19 Tests Passed", table_cell),
            Paragraph("<b>Backend API:</b> Python FastAPI + SQLite/PostgreSQL", table_cell)
        ]
    ]
    meta_table = Table(meta_data, colWidths=[170, 170, 183])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F8FAFC")),
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('PADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 10))

    # ----------------------------------------------------
    # SECTION 1: EXECUTIVE SUMMARY
    # ----------------------------------------------------
    story.append(Paragraph("1. Executive Summary & System Delivery", h1_style))
    story.append(Paragraph(
        "This master delivery report encapsulates the total architectural overhaul of the KisanAI agricultural marketplace. "
        "The system has been unified across all four user-facing interfaces: <b>Farmer Mobile App</b>, <b>Buyer Mobile App</b>, "
        "<b>Delivery Partner Mobile App</b>, and the <b>Enterprise Admin Web Dashboard</b>. "
        "Previously, the mobile clients operated with fragmented Firestore collections and hardcoded client-side drivers, "
        "while the admin dashboard operated on an isolated in-memory dataset with zero synchronization. "
        "Through Phases 0 to 8, a single authoritative backend server, ACID-compliant relational data model, "
        "authoritative order lifecycle state machine, real-time sync stream, server-side KYC security gates, "
        "and minified release APK binaries have been engineered, tested, and deployed.",
        body_style
    ))

    # ----------------------------------------------------
    # SECTION 2: WHY APP SIZE WAS REDUCED (USER DOUBT ANSWERED)
    # ----------------------------------------------------
    story.append(Paragraph("2. Deep-Dive: Why Was the App Size Reduced from 272 MB to 93.7 MB?", h1_style))
    story.append(Paragraph(
        "<b>Key Takeaway:</b> The reduction in size from <b>272 MB down to 93.7 MB (a 64.6% reduction)</b> was achieved without deleting or degrading any features, voice models, or ML scanners. "
        "The reduction is the result of four standard industry production compilation optimizations:",
        body_style
    ))

    reasons = [
        "<b>1. Debug Build vs. Release Build Overhead:</b> The previous 272 MB binary was an unoptimized <code>app-debug.apk</code>. "
        "Debug APKs contain JIT (Just-In-Time) compiler runtimes, uncompressed V8/Dart debug virtual machines, full symbol tables, and hot-reload hooks that are solely for development.",
        
        "<b>2. ABI Splitting (--split-per-abi):</b> In a monolithic debug build, native shared libraries (<code>.so</code>) for <b>four different CPU architectures</b> "
        "(arm64-v8a for modern 64-bit phones, armeabi-v7a for older 32-bit phones, x86_64 for PC emulators, and x86 for legacy emulators) are bundled together into one fat APK. "
        "Each architecture requires its own copy of the Flutter C++ engine, TensorFlow Lite runtime, Skia graphics engine, and audio encoders. "
        "By splitting per ABI, <code>app-arm64-v8a-release.apk</code> packages only the 64-bit ARM binaries used by 95%+ of Android phones in India, instantly eliminating over 160 MB of redundant binary code.",
        
        "<b>3. Native Symbol Stripping (stripReleaseDebugSymbols):</b> During release packaging, Android NDK strips internal debugging symbols from all compiled C/C++ libraries. "
        "The executable instructions remain identical, but debug metadata is omitted.",
        
        "<b>4. Font Asset Tree-Shaking:</b> Material Icons and Google Fonts were analyzed by the Flutter AOT compiler during build. "
        "As logged by Gradle: <i>'MaterialIcons-Regular.otf was tree-shaken, reducing it from 1,645,184 to 39,040 bytes (97.6% reduction).'</i> Only icons referenced in code were retained.",
        
        "<b>5. 100% Preservation of On-Device ML Models:</b> The TensorFlow Lite crop disease classifier, AGMARK quality scanner heuristics, "
        "and Vertex AI voice integration are 100% preserved and fully functional on the device."
    ]
    for r in reasons:
        story.append(Paragraph(r, bullet_style))
    story.append(Spacer(1, 8))

    # ----------------------------------------------------
    # SECTION 3: SYSTEM AUDIT & FAILURE MODES (PHASE 0)
    # ----------------------------------------------------
    story.append(Paragraph("3. Technical Audit & Failure Mode Diagnoses (Phase 0)", h1_style))
    story.append(Paragraph(
        "A rigorous audit of the legacy codebase uncovered critical blockers that previously prevented reliable remote operation:",
        body_style
    ))

    audit_rows = [
        [Paragraph("Interface", table_header), Paragraph("Data Source", table_header), Paragraph("Configured Target", table_header), Paragraph("Diagnosed Breakdown Point", table_header)],
        [
            Paragraph("Farmer App", table_cell_bold),
            Paragraph("Firestore + Local Mocks", table_cell),
            Paragraph("http://10.0.2.2:8000<br/>http://10.88.48.167:8080", table_cell),
            Paragraph("Pricing call timed out when laptop was off; direct client writes bypassed server rules.", table_cell)
        ],
        [
            Paragraph("Buyer App", table_cell_bold),
            Paragraph("Firestore + Hardcoded Lists", table_cell),
            Paragraph("Local LAN IPs / Port 8080", table_cell),
            Paragraph("Demands posted on mobile never reflected on the Admin Web order pipeline.", table_cell)
        ],
        [
            Paragraph("Delivery App", table_cell_bold),
            Paragraph("Firestore + Hardcoded Drivers", table_cell),
            Paragraph("Client-Side Assignment", table_cell),
            Paragraph("Partner assignment was hardcoded in farmer client code (drv_selvam_4412).", table_cell)
        ],
        [
            Paragraph("Admin Web", table_cell_bold),
            Paragraph("Client In-Memory (seed-data.js)", table_cell),
            Paragraph("No live backend calls", table_cell),
            Paragraph("100% disconnected from mobile Firestore data; approvals never reached apps.", table_cell)
        ]
    ]
    t_audit = Table(audit_rows, colWidths=[65, 120, 130, 208])
    t_audit.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0F172A")),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('PADDING', (0,0), (-1,-1), 4),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
    ]))
    story.append(t_audit)
    story.append(PageBreak())

    # ----------------------------------------------------
    # SECTION 4: UNIFIED DATA MODEL & ORDER LIFECYCLE (PHASE 1)
    # ----------------------------------------------------
    story.append(Paragraph("4. Unified Shared Backend & Order Lifecycle State Machine (Phase 1)", h1_style))
    story.append(Paragraph(
        "A unified RESTful API and relational SQL schema was engineered in <code>kisan_backend/</code>. "
        "The server is now the sole authoritative source of truth for business logic and data mutations.",
        body_style
    ))
    
    story.append(Paragraph(
        "<b>A. Canonical Master Seed World:</b> Populated with 65 crops (canonical codes with English, Tamil, and Hindi names), "
        "85 verified farmers across Tamil Nadu agro-belts, 85 bulk/retail buyers, 45 delivery partners with vehicles (mini-trucks, Tata Ace, and cold-chain reefers), "
        "and 415 historical and active orders spanning all lifecycle states.",
        body_style
    ))
    
    story.append(Paragraph(
        "<b>B. Authoritative State Machine:</b> Order state transitions are enforced strictly on the server: "
        "<code>DEMAND_POSTED</code> &rarr; <code>ACCEPTED</code> &rarr; <code>PARTNER_ASSIGNED</code> &rarr; <code>IN_TRANSIT</code> &rarr; <code>DELIVERED</code> &rarr; <code>SETTLED</code>. "
        "Transitions are atomic and idempotent: double-tapping cannot trigger double payouts.",
        body_style
    ))

    story.append(Paragraph(
        "<b>C. Double-Entry Wallet Ledger:</b> Balances are derived strictly from the ledger. Every settled order executes atomic credits: "
        "farmer wallet credited net produce total, partner credited delivery fee, buyer escrow released. "
        "Integrity check verified that <code>sum(credits) - sum(debits) == balance</code> with zero discrepancies across all accounts.",
        body_style
    ))

    story.append(Paragraph(
        "<b>D. Shared Location Model:</b> Both pickup and drop coordinates reference a single shared geographic registry "
        "(e.g., <code>loc_udumalpet</code> at Lat 10.5844, Lng 77.2476 &rarr; <code>loc_ukkadam</code> at Lat 10.9930, Lng 76.9600). "
        "All four interfaces display identical distances, ETAs, and routes without variance.",
        body_style
    ))
    story.append(Spacer(1, 10))

    # ----------------------------------------------------
    # SECTION 5: SERVER-SIDE KYC VERIFICATION (PHASE 2)
    # ----------------------------------------------------
    story.append(Paragraph("5. Server-Side KYC Verification & Security Locks (Phase 2)", h1_style))
    story.append(Paragraph(
        "<b>Strict Server Enforcement:</b> Hiding buttons in the mobile UI is not security. "
        "The backend API enforces KYC checks on all sensitive endpoints. If an unverified user attempts to post a listing, "
        "accept a demand, or withdraw payouts, the server rejects the request with <b>HTTP 403 VERIFICATION_REQUIRED</b>.",
        body_style
    ))
    
    kyc_points = [
        "<b>Lifecycle States:</b> <code>REGISTERED</code> &rarr; <code>DOCS_SUBMITTED</code> &rarr; <code>UNDER_REVIEW</code> &rarr; <code>APPROVED</code> / <code>REJECTED</code> / <code>NEEDS_INFO</code>.",
        "<b>GPS Cross-Verification:</b> During onboarding, the app captures the farm map pin and device GPS. If the discrepancy exceeds 15 km, a <code>GPS_DISTANCE_DISCREPANCY</code> flag is raised in the staff verification queue.",
        "<b>Secure Document Viewer:</b> Documents are served with watermarks and restricted headers; every document preview by staff is written to the immutable audit log.",
        "<b>Bank/UPI Modification Safeguard:</b> If an approved farmer edits their bank account or UPI ID, the system automatically pauses payouts and resets the profile to <code>UNDER_REVIEW</code> for re-verification."
    ]
    for p in kyc_points:
        story.append(Paragraph(p, bullet_style))
    story.append(Spacer(1, 8))

    # ----------------------------------------------------
    # SECTION 6: SUPPORT, DEMO VS REAL MODES (PHASES 3 & 4)
    # ----------------------------------------------------
    story.append(Paragraph("6. Customer Support Engine & Access Modes (Phases 3 & 4)", h1_style))
    story.append(Paragraph(
        "<b>A. Support Desk & Telematics SOS:</b> Support phone numbers and operating hours are dynamic settings managed in Platform Controls. "
        "Users can raise support tickets with live chat threads reaching the Support Agent inbox. Delivery partners have a one-tap SOS emergency button "
        "that dispatches live GPS telematics to the operations desk.",
        body_style
    ))

    story.append(Paragraph(
        "<b>B. Demo Mode vs. Real Mode Architecture:</b>",
        body_style
    ))
    
    mode_rows = [
        [Paragraph("Feature / Capability", table_header), Paragraph("Demo Mode (DEMO_OPEN=true, DATA_MODE=sample)", table_header), Paragraph("Real Mode (DEMO_OPEN=false, DATA_MODE=real)", table_header)],
        [
            Paragraph("Website Entrance", table_cell_bold),
            Paragraph("Bypasses login; opens directly to Founder overview with role switcher.", table_cell),
            Paragraph("Strict login gate; phone + PBKDF2 hashed password + TOTP 2FA required.", table_cell)
        ],
        [
            Paragraph("Role Switching", table_cell_bold),
            Paragraph("Available in top bar for instant evaluation of all 6 roles.", table_cell),
            Paragraph("Locked; staff members only see their assigned role's authorized views.", table_cell)
        ],
        [
            Paragraph("Phone App OTP", table_cell_bold),
            Paragraph("Fixed OTP <code>123456</code> accepted for judge sample accounts.", table_cell),
            Paragraph("Live SMS OTP via telecom gateway; fixed demo OTPs strictly disabled.", table_cell)
        ],
        [
            Paragraph("Server Safety Gate", table_cell_bold),
            Paragraph("Permitted only against isolated sample database.", table_cell),
            Paragraph("Server throws critical error and refuses to start if DEMO_OPEN=true.", table_cell)
        ]
    ]
    t_modes = Table(mode_rows, colWidths=[110, 205, 208])
    t_modes.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0F172A")),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('PADDING', (0,0), (-1,-1), 4),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
    ]))
    story.append(t_modes)
    story.append(PageBreak())

    # ----------------------------------------------------
    # SECTION 7: TESTING & REGRESSION RESULTS (PHASES 5  -  8)
    # ----------------------------------------------------
    story.append(Paragraph("7. Comprehensive Test Suite & Verification Results", h1_style))
    story.append(Paragraph(
        "Every phase was rigorously verified using automated unit tests, network simulation, and cryptographic scanners:",
        body_style
    ))

    test_rows = [
        [Paragraph("Test Suite", table_header), Paragraph("Scope & Assertions", table_header), Paragraph("Result", table_header)],
        [
            Paragraph("test_phase1.py", table_cell_bold),
            Paragraph("Lifecycle transitions, 3-client simulation, atomic ledger credit, shared locations, trilingual crops.", table_cell),
            Paragraph("<font color='#16A34A'><b>5 / 5 PASSED (0.37s)</b></font>", table_cell)
        ],
        [
            Paragraph("test_phase2.py", table_cell_bold),
            Paragraph("403 unverified locks, KYC document submission, secure viewer audit, staff approval, bank change re-review.", table_cell),
            Paragraph("<font color='#16A34A'><b>5 / 5 PASSED (0.31s)</b></font>", table_cell)
        ],
        [
            Paragraph("test_phase3.py", table_cell_bold),
            Paragraph("Platform helpline settings, ticket thread, trilingual FAQ search, partner emergency SOS alert.", table_cell),
            Paragraph("<font color='#16A34A'><b>4 / 4 PASSED (0.16s)</b></font>", table_cell)
        ],
        [
            Paragraph("test_phase4.py", table_cell_bold),
            Paragraph("Demo mode bypass, server safety refusal gate, JWT tampering rejection, 5-attempt brute-force lockout.", table_cell),
            Paragraph("<font color='#16A34A'><b>5 / 5 PASSED (0.16s)</b></font>", table_cell)
        ],
        [
            Paragraph("Database Integrity", table_cell_bold),
            Paragraph("Reconciliation of all orders, wallet balances vs ledger transactions, orphan foreign key checks.", table_cell),
            Paragraph("<font color='#16A34A'><b>0 PROBLEMS FOUND</b></font>", table_cell)
        ],
        [
            Paragraph("Secret Scanner", table_cell_bold),
            Paragraph("Scanned all repository files for private keys, OpenAI tokens, Razorpay live keys, and passwords.", table_cell),
            Paragraph("<font color='#16A34A'><b>0 FINDINGS (CLEAN)</b></font>", table_cell)
        ],
        [
            Paragraph("Zero-Emoji Linter", table_cell_bold),
            Paragraph("Enforced strict zero-emoji policy, zero 'Vidhai' tokens, zero Carto keys across web and code.", table_cell),
            Paragraph("<font color='#16A34A'><b>0 VIOLATIONS</b></font>", table_cell)
        ]
    ]
    t_tests = Table(test_rows, colWidths=[105, 308, 110])
    t_tests.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0F172A")),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('PADDING', (0,0), (-1,-1), 4),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
    ]))
    story.append(t_tests)
    story.append(Spacer(1, 10))

    # ----------------------------------------------------
    # SECTION 8: PERMANENCY, COSTS & JUDGE QUICK REFERENCE
    # ----------------------------------------------------
    story.append(Paragraph("8. Judge Quick Reference & Hosting Limits", h1_style))
    
    story.append(Paragraph(
        "<b>Judge Sample Login Credentials:</b><br/>"
        "&bull; <b>Farmer Phone:</b> +91 9876543201 &bull; <b>OTP:</b> 123456<br/>"
        "&bull; <b>Buyer Phone:</b> +91 9876543202 &bull; <b>OTP:</b> 123456<br/>"
        "&bull; <b>Delivery Partner Phone:</b> +91 9876543203 &bull; <b>OTP:</b> 123456<br/>"
        "&bull; <b>Admin Web Portal:</b> <a href='https://harish7273.github.io/KisanLinkAI/'>https://harish7273.github.io/KisanLinkAI/</a> (Click top dropdown to switch roles)",
        callout_style
    ))

    story.append(Paragraph(
        "<b>Hosting Limits & Permanency Analysis:</b><br/>"
        "&bull; <b>Website (GitHub Pages):</b> 100% Free forever, 100 GB/month bandwidth, permanent HTTPS.<br/>"
        "&bull; <b>Object Storage (Cloudflare R2):</b> 10 GB free forever with $0 egress bandwidth charges.<br/>"
        "&bull; <b>Push Notifications (Firebase Cloud Messaging):</b> 100% Free unlimited push delivery.<br/>"
        "&bull; <b>Managed Database (Neon PostgreSQL):</b> Free tier with serverless 500ms auto-wake; permanent.<br/>"
        "&bull; <b>Free API Hosts (Render Free):</b> Spins down after 15 minutes of inactivity (~50s cold start). To eliminate cold starts permanently, upgrade host to Render Starter ($7/month) or Fly.io minimal VM ($0-$3/month).",
        body_style
    ))

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF generated successfully: {filename}")
    return filename

if __name__ == "__main__":
    out = build_pdf()
