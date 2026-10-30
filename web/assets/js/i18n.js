/**
 * SorokSurokkha Bilingual (English / বাংলা) i18n Translation Engine
 */

const APP_TRANSLATIONS = {
    en: {
        app_title: "SorokSurokkha",
        authority_badge: "Road Authority",
        app_subtitle: "Hazard Monitoring & Pothole Repair Management",
        nav_dashboard: "Dashboard",
        footer_text: "SorokSurokkha • Road Hazard & Pothole Authority Management Portal",

        // KPI Metric Cards
        kpi_total_hazards: "Total Hazards",
        kpi_detected: "detected",
        kpi_critical_high: "Critical / High",
        kpi_priority: "priority",
        kpi_pending_review: "Pending Review",
        kpi_unassigned: "unassigned",
        kpi_in_progress: "In Progress",
        kpi_crews_active: "crews active",
        kpi_resolved: "Resolved",
        kpi_repaired: "repaired",
        kpi_app_users: "App Users",
        kpi_citizens: "citizens",

        // Upazilla Hotspots Section
        geo_section_title: "Upazilla Pothole Density Ratio & Hotspot Analytics",
        geo_section_sub: "Live density percentages calculated based on pothole locations in database to guide authority repair prioritization",
        geo_monitored_upazillas: "Monitored Upazillas",
        geo_total_hazards: "Total Hazards Analyzed",
        geo_filter_title: "Hierarchical Geographic Filter (Select Division → District → Upazilla):",
        geo_select_division: "1. Select Division",
        geo_all_divisions: "All Divisions",
        geo_select_district: "2. Select District",
        geo_all_districts: "All Districts",
        geo_select_upazilla: "3. Select Upazilla",
        geo_all_upazillas: "All Upazillas",
        geo_search_label: "Quick Upazilla Search",
        geo_search_placeholder: "Type upazilla name...",
        geo_reset_filters: "Reset Filters",

        // Particular Upazilla Card
        card_focus_map: "Focus on Map",
        card_view_records: "View Records",
        card_density_ratio: "Pothole Density Ratio",
        card_density_ratio_sub: "of total recorded defects",
        card_total_in_upazilla: "Total Hazards in Upazilla",
        card_repair_status: "Repair Status",
        card_inspection_queue: "Inspection queue",
        card_authority_action: "Authority Action",
        card_action_guideline: "Action guideline",
        card_major_routes: "Major Affected Routes in this Upazilla:",
        card_all_clear: "All Clear • 0 Defects Reported",
        card_zero_pending: "0 Pending (All Clear)",
        card_safe_pavement: "Safe Pavement - Routine Monitoring",
        card_no_active_defects: "No active defects reported on this route",
        card_badge_zero: "ZERO DEFECTS (CLEAR)",
        card_badge_critical: "CRITICAL HOTSPOT",
        card_badge_high: "HIGH DENSITY HOTSPOT",
        card_badge_moderate: "MODERATE DENSITY",
        card_badge_stable: "LOW DENSITY / STABLE",
        card_active_crews: "active crew assigned",
        card_critical: "Critical",
        card_high: "High",
        card_medium: "Medium",
        card_pending_rev: "Pending Review",

        // Upazilla Leaderboard
        table_density_heading: "Upazilla Pothole Density Ratio (Ranked in Descending Order)",
        table_density_sub: "Click any row to inspect or focus GIS map",
        th_rank: "Rank",
        th_upazilla: "Upazilla",
        th_district_div: "District & Division",
        th_potholes_count: "Potholes Count",
        th_density_ratio: "Density Ratio (% of All Hazards)",
        th_severity_profile: "Severity Profile",
        th_repair_urgency: "Repair Urgency",
        th_actions: "Actions",
        btn_map: "Map",
        btn_records: "Records",
        btn_inspect: "Inspect",
        table_empty_upazilla: "No road hazard records found for the selected geographic scope.",
        table_loading_analytics: "Loading upazilla-wise density analytics...",
        defects_unit: "defects",
        pending_inspection_unit: "pending inspection",
        all_clear_count: "All Clear (0)",
        upazilla_suffix: "Upazilla",
        district_suffix: "District",
        division_suffix: "Division",

        // GIS Map Section
        map_title: "Live GIS Road Hazard Map",
        map_subtitle: "Real-time GPS coordinates transmitted from mobile surveys and citizen reports",
        map_search_placeholder: "Search street or city (e.g. Teligati Road, Mirpur Road)...",
        map_find_btn: "Find",
        map_refresh_btn: "Refresh",
        map_legend_title: "Map Legend:",
        legend_authority: "Authority Position",
        legend_critical: "High / Critical Defect",
        legend_medium: "Medium Defect",
        legend_low: "Low Defect",
        legend_resolved: "Repaired / Resolved",
        map_attribution: "Tiles © OpenStreetMap contributors",
        map_live_position: "Live Position:",
        map_scanning_hazards: "Scanning road hazards...",
        map_nearest: "Nearest:",
        popup_inspect: "Inspect →",

        // Database Records Table Section
        records_title: "Road Hazard & Pothole Records",
        records_loading: "Loading records...",
        records_of: "of",
        records_count_suffix: "records",
        search_records_placeholder: "Search by ID, User, Road...",
        filter_all_users_prefix: "All Citizens / Users",
        filter_contributors: "contributors",
        filter_all_severities: "All Severities",
        filter_critical: "Critical",
        filter_high: "High",
        filter_medium: "Medium",
        filter_low: "Low",
        filter_all_statuses: "All Statuses",
        status_reported: "⏳ Pending Review",
        status_verified: "🔍 Verified",
        status_assigned: "👷 Assigned",
        status_under_repair: "🛠️ Under Repair",
        status_resolved: "✅ Resolved",
        btn_export_csv: "Export CSV",
        th_photo: "Photo",
        th_id_date: "Record ID & Date",
        th_contributor: "Contributor",
        th_severity_conf: "Severity & Confidence",
        th_location: "Location & Coordinates",
        th_status: "Lifecycle Status",
        table_empty_records: "No road hazard records found matching current criteria.",
        table_loading_records: "Loading hazard records from all app users...",
        conf_suffix: "conf.",
        crew_label: "Crew:",
        delete_confirm: "Are you sure you want to delete report",

        // Modal Elements
        modal_details_title: "Pothole Defect Details",
        modal_photo_caption: "Field Mobile Photo & AI Detections",
        modal_submitted_by: "Submitted by Citizen Scanner",
        modal_phone_prefix: "Phone:",
        modal_ai_assessment: "AI Defect Assessment",
        modal_confidence: "Confidence",
        modal_severity: "Severity",
        modal_total_defects: "Total Defects",
        modal_detected_suffix: "detected",
        modal_dim_type: "Type",
        modal_dim_depth: "Est. Depth",
        modal_dim_crack_width: "Crack Width",
        modal_dim_area: "Damage Area",
        modal_defect_breakdown: "Defect Breakdown",
        modal_items_suffix: "Items",
        modal_surface_coverage: "Surface coverage:",
        modal_conf_short: "Conf.",
        modal_geo_coords: "Geographic Coordinates",
        modal_open_gmaps: "Open in Google Maps",
        modal_model_notes: "Model Inference Notes",
        modal_inference_suffix: "inference",
        modal_authority_workflow: "Authority Action & Repair Workflow",
        modal_workflow_sub: "Update maintenance status, assign repair crews and log field notes",
        modal_form_status: "Lifecycle Status",
        modal_opt_reported: "⏳ Pending Inspection",
        modal_opt_verified: "🔍 Field Verified",
        modal_opt_assigned: "👷 Crew Assigned",
        modal_opt_under_repair: "🛠️ Under Repair",
        modal_opt_resolved: "✅ Repaired & Resolved",
        modal_form_crew: "Assigned Repair Crew / Team",
        modal_form_crew_ph: "e.g. Zone 2 Rapid Maintenance Team",
        modal_form_date: "Scheduled Repair Date",
        modal_form_notes: "Authority Notes & Log",
        modal_form_notes_ph: "Enter inspection details, contractor estimates, or repair confirmation...",
        modal_form_proof: "Upload Repair Proof Photo (Optional)",
        modal_btn_cancel: "Cancel",
        modal_btn_save: "Save Action",

        // Severities & Urgencies
        sev_critical: "CRITICAL",
        sev_high: "HIGH",
        sev_medium: "MEDIUM",
        sev_low: "LOW",
        urgency_urgent: "Urgent Repair",
        urgency_high: "High Priority",
        urgency_medium: "Medium Priority",
        urgency_routine: "Routine Monitoring",
        urgency_safe: "Routine Monitoring",

        // Defect types
        defect_pothole: "Pothole",
        defect_longitudinal: "Longitudinal Crack",
        defect_transverse: "Transverse Crack",
        defect_alligator: "Alligator Crack",

        // Toasts & Notifications
        toast_saving: "Saving authority action...",
        toast_saved: "✓ Status and notes updated successfully!",
        toast_deleted: "Report deleted.",
        toast_filter_reset: "✓ Geographic filters reset to all Bangladesh.",
        toast_filtered_records: "Filtered database records to: ",
        toast_focused_map: "📍 Focused GIS Map on "
    },

    bn: {
        app_title: "সড়কসুরক্ষা",
        authority_badge: "সড়ক কর্তৃপক্ষ",
        app_subtitle: "সড়ক বিপদ পর্যবেক্ষণ ও গর্ত মেরামত ব্যবস্থাপনা",
        nav_dashboard: "ড্যাশবোর্ড",
        footer_text: "সড়কসুরক্ষা • সড়ক বিপদ ও গর্ত কর্তৃপক্ষ ব্যবস্থাপনা পোর্টাল",

        // KPI Metric Cards
        kpi_total_hazards: "মোট সড়ক বিপদ",
        kpi_detected: "শনাক্তকৃত",
        kpi_critical_high: "জরুরি / উচ্চ ঝুঁকি",
        kpi_priority: "অগ্রাধিকার",
        kpi_pending_review: "পর্যালোচনা বাকি",
        kpi_unassigned: "বরাদ্দহীন",
        kpi_in_progress: "চলমান মেরামত",
        kpi_crews_active: "কর্মী সক্রিয়",
        kpi_resolved: "মেরামত সম্পন্ন",
        kpi_repaired: "মেরামতকৃত",
        kpi_app_users: "নাগরিক ব্যবহারকারী",
        kpi_citizens: "নাগরিক",

        // Upazilla Hotspots Section
        geo_section_title: "উপজেলা ভিত্তিক গর্তের ঘনত্ব ও হটস্পট বিশ্লেষণ",
        geo_section_sub: "মেরামত কাজের অগ্রাধিকার নির্ধারণে ডেটাবেসের গর্তের অবস্থানের ভিত্তিতে সরাসরি ঘনত্বের অনুপাত",
        geo_monitored_upazillas: "পর্যবেক্ষণাধীন উপজেলা",
        geo_total_hazards: "মোট বিশ্লেষিত বিপদ",
        geo_filter_title: "ভৌগোলিক ফিল্টার (বিভাগ → জেলা → উপজেলা নির্বাচন করুন):",
        geo_select_division: "১. বিভাগ নির্বাচন করুন",
        geo_all_divisions: "সকল বিভাগ",
        geo_select_district: "২. জেলা নির্বাচন করুন",
        geo_all_districts: "সকল জেলা",
        geo_select_upazilla: "৩. উপজেলা নির্বাচন করুন",
        geo_all_upazillas: "সকল উপজেলা",
        geo_search_label: "দ্রুত উপজেলা অনুসন্ধান",
        geo_search_placeholder: "উপজেলার নাম লিখুন...",
        geo_reset_filters: "ফিল্টার রিসেট",

        // Particular Upazilla Card
        card_focus_map: "ম্যাপে দেখুন",
        card_view_records: "তথ্য দেখুন",
        card_density_ratio: "গর্তের ঘনত্বের অনুপাত",
        card_density_ratio_sub: "মোট নথিবদ্ধ ত্রুটির",
        card_total_in_upazilla: "উপজেলায় মোট বিপদ",
        card_repair_status: "মেরামতের অবস্থা",
        card_inspection_queue: "পরিদর্শন তালিকায়",
        card_authority_action: "কর্তৃপক্ষের করণীয়",
        card_action_guideline: "করণীয় নির্দেশনা",
        card_major_routes: "উপজেলার প্রধান ক্ষতিগ্রস্ত সড়কসমূহ:",
        card_all_clear: "সব ঠিক আছে • কোনো ত্রুটি নেই",
        card_zero_pending: "০টি বাকি (ঝুঁকিমুক্ত)",
        card_safe_pavement: "নিরাপদ সড়ক - নিয়মিত পর্যবেক্ষণ",
        card_no_active_defects: "এই রুটে কোনো সক্রিয় সড়ক ত্রুটি নথিবদ্ধ নেই",
        card_badge_zero: "কোনো ত্রুটি নেই (ঝুঁকিমুক্ত)",
        card_badge_critical: "জরুরি হটস্পট",
        card_badge_high: "উচ্চ ঘনত্বের এলাকা",
        card_badge_moderate: "মাঝারি ঘনত্বের এলাকা",
        card_badge_stable: "স্বাভাবিক এলাকা",
        card_active_crews: "টিম সক্রিয়",
        card_critical: "মারাত্মক",
        card_high: "উচ্চ",
        card_medium: "মাঝারি",
        card_pending_rev: "পর্যালোচনা বাকি",

        // Upazilla Leaderboard
        table_density_heading: "উপজেলা ভিত্তিক গর্তের ঘনত্বের অনুপাত (সর্বোচ্চ থেকে সর্বনিম্ন)",
        table_density_sub: "যেকোনো সারিতে ক্লিক করে বিস্তারিত অথবা ম্যাপে অবস্থান দেখুন",
        th_rank: "ক্রমিক",
        th_upazilla: "উপজেলা",
        th_district_div: "জেলা ও বিভাগ",
        th_potholes_count: "গর্তের সংখ্যা",
        th_density_ratio: "ঘনত্বের অনুপাত (মোট বিপদের %)",
        th_severity_profile: "ঝুঁকির মাত্রা",
        th_repair_urgency: "জরুরিতা",
        th_actions: "পদক্ষেপ",
        btn_map: "ম্যাপ",
        btn_records: "রেকর্ড",
        btn_inspect: "পরিদর্শন",
        table_empty_upazilla: "নির্বাচিত ভৌগোলিক অঞ্চলের জন্য কোনো সড়ক বিপদের তথ্য পাওয়া যায়নি।",
        table_loading_analytics: "উপজেলা ভিত্তিক তথ্য লোড হচ্ছে...",
        defects_unit: "টি ত্রুটি",
        pending_inspection_unit: "টি পরিদর্শন বাকি",
        all_clear_count: "ঝুঁকিমুক্ত (০)",
        upazilla_suffix: "উপজেলা",
        district_suffix: "জেলা",
        division_suffix: "বিভাগ",

        // GIS Map Section
        map_title: "সরাসরি জিআইএস সড়ক বিপদ মানচিত্র",
        map_subtitle: "মোবাইল সমীক্ষা ও নাগরিক প্রতিবেদন থেকে প্রাপ্ত সরাসরি জিপিএস অবস্থান",
        map_search_placeholder: "সড়ক বা শহরের নাম খুঁজুন (যেমন: তেলিগাতি রোড, মিরপুর রোড)...",
        map_find_btn: "খুঁজুন",
        map_refresh_btn: "রিফ্রেশ",
        map_legend_title: "মানচিত্র নির্দেশিকা:",
        legend_authority: "কর্তৃপক্ষের বর্তমান অবস্থান",
        legend_critical: "উচ্চ / মারাত্মক ত্রুটি",
        legend_medium: "মাঝারি ত্রুটি",
        legend_low: "সাধারণ ত্রুটি",
        legend_resolved: "মেরামত সম্পন্ন",
        map_attribution: "টাইলস © ওপেনস্ট্রিটম্যাপ কন্ট্রিবিউটর",
        map_live_position: "বর্তমান অবস্থান:",
        map_scanning_hazards: "সড়ক বিপদ স্ক্যান করা হচ্ছে...",
        map_nearest: "নিকটতম:",
        popup_inspect: "পরিদর্শন →",

        // Database Records Table Section
        records_title: "সড়ক বিপদ ও গর্তের তথ্যাবলী",
        records_loading: "তথ্য লোড হচ্ছে...",
        records_of: "/",
        records_count_suffix: "টি রেকর্ড",
        search_records_placeholder: "আইডি, নাগরিক, সড়ক দিয়ে খুঁজুন...",
        filter_all_users_prefix: "সকল নাগরিক / ব্যবহারকারী",
        filter_contributors: "জন অবদানকারী",
        filter_all_severities: "সকল তীব্রতা",
        filter_critical: "মারাত্মক (Critical)",
        filter_high: "উচ্চ ঝুঁকি (High)",
        filter_medium: "মাঝারি ঝুঁকি (Medium)",
        filter_low: "সাধারণ ঝুঁকি (Low)",
        filter_all_statuses: "সকল অবস্থা",
        status_reported: "⏳ পর্যালোচনা বাকি",
        status_verified: "🔍 যাচাইকৃত",
        status_assigned: "👷 দল বরাদ্দকৃত",
        status_under_repair: "🛠️ মেরামত চলছে",
        status_resolved: "✅ মেরামত সম্পন্ন",
        btn_export_csv: "সিএসভি এক্সপোর্ট",
        th_photo: "ছবি",
        th_id_date: "রেকর্ড আইডি ও তারিখ",
        th_contributor: "প্রতিবেদনকারী",
        th_severity_conf: "তীব্রতা ও নির্ভুলতা",
        th_location: "অবস্থান ও স্থানাঙ্ক",
        th_status: "বর্তমান অবস্থা",
        table_empty_records: "আপনার ফিল্টার অনুযায়ী কোনো সড়ক বিপদের তথ্য পাওয়া যায়নি।",
        table_loading_records: "নাগরিকদের প্রেরিত সড়ক বিপদের তথ্য লোড হচ্ছে...",
        conf_suffix: "নির্ভুলতা",
        crew_label: "টিম:",
        delete_confirm: "আপনি কি নিশ্চিতভাবে এই রেকর্ডটি মুছে ফেলতে চান?",

        // Modal Elements
        modal_details_title: "সড়ক ত্রুটি ও গর্তের বিস্তারিত",
        modal_photo_caption: "মাঠ পর্যায়ের ছবি ও এআই শনাক্তকরণ",
        modal_submitted_by: "নাগরিক স্ক্যানার দ্বারা প্রেরিত",
        modal_phone_prefix: "ফোন:",
        modal_ai_assessment: "এআই ত্রুটি মূল্যায়ন",
        modal_confidence: "নির্ভুলতা",
        modal_severity: "তীব্রতা",
        modal_total_defects: "মোট ত্রুটি",
        modal_detected_suffix: "টি শনাক্ত",
        modal_dim_type: "প্রকার",
        modal_dim_depth: "আনুমানিক গভীরতা",
        modal_dim_crack_width: "ফাটলের প্রস্থ",
        modal_dim_area: "ক্ষতিগ্রস্ত ক্ষেত্রফল",
        modal_defect_breakdown: "ত্রুটির তালিকা",
        modal_items_suffix: "টি আইটেম",
        modal_surface_coverage: "পৃষ্ঠতলের ক্ষেত্রফল:",
        modal_conf_short: "নির্ভুলতা",
        modal_geo_coords: "ভৌগোলিক স্থানাঙ্ক (জিপিএস)",
        modal_open_gmaps: "গুগল ম্যাপে দেখুন",
        modal_model_notes: "এআই মডেল ইনফারেন্স বিবরণ",
        modal_inference_suffix: "ইনফারেন্স সময়",
        modal_authority_workflow: "কর্তৃপক্ষের পদক্ষেপ ও মেরামত কার্যপ্রণালী",
        modal_workflow_sub: "মেরামতের অগ্রগতি হালনাগাদ করুন, মেরামতের দল নির্ধারণ করুন এবং নোট যুক্ত করুন",
        modal_form_status: "কার্যক্রমের অবস্থা",
        modal_opt_reported: "⏳ পরিদর্শন বাকি (Pending)",
        modal_opt_verified: "🔍 সরেজমিনে যাচাইকৃত (Verified)",
        modal_opt_assigned: "👷 কর্মী দল বরাদ্দ (Assigned)",
        modal_opt_under_repair: "🛠️ মেরামত চলছে (Under Repair)",
        modal_opt_resolved: "✅ মেরামত সম্পন্ন (Resolved)",
        modal_form_crew: "নিযুক্ত মেরামতের দল",
        modal_form_crew_ph: "যেমন: জোন-২ জরুরি মেরামত টিম",
        modal_form_date: "নির্ধারিত মেরামতের তারিখ",
        modal_form_notes: "কর্তৃপক্ষের নোট ও বিবরণ",
        modal_form_notes_ph: "পরিদর্শনের তথ্য, ঠিকাদারের হিসাব বা মেরামতের বিবরণ লিখুন...",
        modal_form_proof: "মেরামতের প্রমাণ ছবি আপলোড করুন (ঐচ্ছিক)",
        modal_btn_cancel: "বাতিল",
        modal_btn_save: "সংরক্ষণ করুন",

        // Severities & Urgencies
        sev_critical: "মারাত্মক (Critical)",
        sev_high: "উচ্চ (High)",
        sev_medium: "মাঝারি (Medium)",
        sev_low: "সাধারণ (Low)",
        urgency_urgent: "জরুরি মেরামত প্রয়োজন",
        urgency_high: "উচ্চ অগ্রাধিকার",
        urgency_medium: "মাঝারি অগ্রাধিকার",
        urgency_routine: "নিয়মিত পর্যবেক্ষণ",
        urgency_safe: "নিরাপদ সড়ক - নিয়মিত পর্যবেক্ষণ",

        // Defect types
        defect_pothole: "গর্ত (Pothole)",
        defect_longitudinal: "অনুদৈর্ঘ্য ফাটল",
        defect_transverse: "তির্যক ফাটল",
        defect_alligator: "জালিকাকার ফাটল",

        // Toasts & Notifications
        toast_saving: "তথ্য সংরক্ষণ করা হচ্ছে...",
        toast_saved: "✓ সফলভাবে অবস্থা ও নোট হালনাগাদ করা হয়েছে!",
        toast_deleted: "রেকর্ড সফলভাবে মুছে ফেলা হয়েছে।",
        toast_filter_reset: "✓ সকল ভৌগোলিক ফিল্টার রিসেট করা হয়েছে।",
        toast_filtered_records: "ফিল্টারকৃত রেকর্ড: ",
        toast_focused_map: "📍 ম্যাপ ফোকাস করা হয়েছে: "
    }
};

// Complete Geographic Name Translations Dictionary for Bangladesh
const GEO_TRANSLATIONS = {
    "Khulna": "খুলনা",
    "Dhaka": "ঢাকা",
    "Chattogram": "চট্টগ্রাম",
    "Chittagong": "চট্টগ্রাম",
    "Rajshahi": "রাজশাহী",
    "Barishal": "বরিশাল",
    "Barisal": "বরিশাল",
    "Sylhet": "সিলেট",
    "Rangpur": "রংপুর",
    "Mymensingh": "ময়মনসিংহ",
    "Bagerhat": "বাগেরহাট",
    "Chuadanga": "চুয়াডাঙ্গা",
    "Jashore": "যশোর",
    "Jessore": "যশোর",
    "Jhenaidah": "ঝিনাইদহ",
    "Kushtia": "কুষ্টিয়া",
    "Magura": "মাগুরা",
    "Meherpur": "মেহেরপুর",
    "Narail": "নড়াইল",
    "Satkhira": "সাতক্ষীরা",
    "Gazipur": "গাজীপুর",
    "Narayanganj": "নারায়ণগঞ্জ",
    "Tangail": "টাঙ্গাইল",
    "Manikganj": "মানিকগঞ্জ",
    "Munshiganj": "মুন্সীগঞ্জ",
    "Narsingdi": "নরসিংদী",
    "Rajbari": "রাজবাড়ী",
    "Madaripur": "মাদারীপুর",
    "Gopalganj": "গোপালগঞ্জ",
    "Shariatpur": "শরীয়তপুর",
    "Kishoreganj": "কিশোরগঞ্জ",
    "Cox's Bazar": "কক্সবাজার",
    "Coxs Bazar": "কক্সবাজার",
    "Cumilla": "কুমিল্লা",
    "Comilla": "কুমিল্লা",
    "Feni": "ফেনী",
    "Brahmanbaria": "ব্রাহ্মণবাড়িয়া",
    "Noakhali": "নোয়াখালী",
    "Lakshmipur": "লক্ষ্মীপুর",
    "Chandpur": "চাঁদপুর",
    "Khagrachhari": "খাগড়াছড়ি",
    "Rangamati": "রাঙ্গামাটি",
    "Bandarban": "বান্দরবান",
    "Bogura": "বগুড়া",
    "Bogra": "বগুড়া",
    "Pabna": "পাবনা",
    "Sirajganj": "সিরাজগঞ্জ",
    "Natore": "নাটোর",
    "Naogaon": "নওগাঁ",
    "Joypurhat": "জয়পুরহাট",
    "Chapainawabganj": "চাঁপাইনবাবগঞ্জ",
    "Bhola": "ভোলা",
    "Patuakhali": "পটুয়াখালী",
    "Pirojpur": "পিরোজপুর",
    "Jhalokathi": "ঝালকাঠি",
    "Jhalakati": "ঝালকাঠি",
    "Barguna": "বরগুনা",
    "Moulvibazar": "মৌলভীবাজার",
    "Maulvibazar": "মৌলভীবাজার",
    "Habiganj": "হবিগঞ্জ",
    "Sunamganj": "সুনামগঞ্জ",
    "Dinajpur": "দিনাজপুর",
    "Gaibandha": "গাইবান্ধা",
    "Kurigram": "কুড়িগ্রাম",
    "Lalmonirhat": "লালমনিরহাট",
    "Nilphamari": "নীলফামারী",
    "Panchagarh": "পঞ্চগড়",
    "Thakurgaon": "ঠাকুরগাঁও",
    "Jamalpur": "জামালপুর",
    "Netrokona": "নেত্রকোনা",
    "Sherpur": "শেরপুর",
    "Brahmanbaria Sadar": "ব্রাহ্মণবাড়িয়া সদর",
    "Ashuganj": "আশুগঞ্জ",
    "Sarail": "সরাইল",
    "Nasirnagar": "নাসিরনগর",
    "Nabinagar": "নবীনগর",
    "Bancharampur": "বাঞ্ছারামপুর",
    "Kasba": "কসবা",
    "Akhaura": "আখাউড়া",
    "Khan Jahan Ali": "খান জাহান আলী",
    "Khulna Sadar": "খুলনা সদর",
    "Phultala": "ফুলতলা",
    "Dighalia": "দিঘলিয়া",
    "Khalishpur": "খালিশপুর",
    "Daulatpur": "দৌলতপুর",
    "Sonadanga": "সোনাডাঙ্গা",
    "Dumuria": "ডুমুরিয়া",
    "Batiaghata": "বটিয়াঘাটা",
    "Dacope": "দাকোপ",
    "Paikgachha": "পাইকগাছা",
    "Koyra": "কয়রা",
    "Rupsha": "রূপসা",
    "Terokhada": "তেরখাদা",
    "Kushtia Sadar": "কুষ্টিয়া সদর",
    "Kumarkhali": "কুমারখালী",
    "Khoksa": "খোকসা",
    "Mirpur": "মিরপুর",
    "Bheramara": "ভেড়ামারা",
    "Jashore Sadar": "যশোর সদর",
    "Jhikargachha": "ঝিকরগাছা",
    "Sharsha": "শার্শা",
    "Bagherpara": "বাঘারপাড়া",
    "Abhaynagar": "অভয়নগর",
    "Manirampur": "মণিরামপুর",
    "Keshabpur": "কেশবপুর",
    "Chaugachha": "চৌগাছা",
    "Jhenaidah Sadar": "ঝিনাইদহ সদর",
    "Kaliganj": "কালীগঞ্জ",
    "Kotchandpur": "কোটচাঁদপুর",
    "Maheshpur": "মহেশপুর",
    "Shailkupa": "শৈলকুপা",
    "Harinakundu": "হরিণাকুণ্ডু",
    "Bagerhat Sadar": "বাগেরহাট সদর",
    "Fakirhat": "ফকিরহাট",
    "Mollahat": "মোল্লাহাট",
    "Kachua": "কচুয়া",
    "Rampal": "রামপাল",
    "Mongla": "মংলা",
    "Morrelganj": "মোড়েলগঞ্জ",
    "Sarankhola": "শরণখোলা",
    "Chitalmari": "চিতলমারী",
    "Satkhira Sadar": "সাতক্ষীরা সদর",
    "Kalaroa": "কলারোয়া",
    "Tala": "তালা",
    "Debhata": "দেবহাটা",
    "Assasuni": "আশাশুনি",
    "Shyamnagar": "শ্যামনগর",
    "Chuadanga Sadar": "চুয়াডাঙ্গা সদর",
    "Alamdanga": "আলমডাঙ্গা",
    "Damurhuda": "দামুড়হুদা",
    "Jibannagar": "জীবননগর",
    "Magura Sadar": "মাগুরা সদর",
    "Sreepur": "শ্রীপুর",
    "Mohammadpur": "মোহাম্মদপুর",
    "Shalikha": "শালিখা",
    "Meherpur Sadar": "মেহেরপুর সদর",
    "Gangni": "গাংনী",
    "Mujibnagar": "মুজিবনগর",
    "Narail Sadar": "নড়াইল সদর",
    "Lohagara": "লোহাগড়া",
    "Kalia": "কালিয়া",
    "Dhanmondi": "ধানমন্ডি",
    "Gulshan": "গুলশান",
    "Uttara": "উত্তরা",
    "Savar": "সাভার",
    "Keraniganj": "কেরানীগঞ্জ",
    "Dhamrai": "ধামরাই",
    "Tejgaon": "তেজগাঁও",
    "Ramna": "রমনা",
    "Motijheel": "মতিঝিল",
    "Khilgaon": "খিলগাঁও",
    "Badda": "বাড্ডা",
    "Pallabi": "পল্লবী",
    "Kafrul": "কাফরুল",
    "Shah Ali": "শাহ আলী",
    "Gazipur Sadar": "গাজীপুর সদর",
    "Kaliakair": "কালিয়াকৈর",
    "Kapasia": "কাপাসিয়া",
    "Tongi": "টঙ্গী",
    "Narayanganj Sadar": "নারায়ণগঞ্জ সদর",
    "Bandar": "বন্দর",
    "Rupganj": "রূপগঞ্জ",
    "Sonargaon": "সোনারগাঁও",
    "Araihazar": "আড়াইহাজার",
    "Tangail Sadar": "টাঙ্গাইল সদর",
    "Gopalpur": "গোপালপুর",
    "Ghatail": "ঘাটাইল",
    "Madhupur": "মধুপুর",
    "Mirzapur": "মির্জাপুর",
    "Sakhipur": "সখিপুর",
    "Kalihati": "কালিহাতী",
    "Basail": "বাসাইল",
    "Faridpur Sadar": "ফরিদপুর সদর",
    "Boalmari": "বোয়ালমারী",
    "Alfadanga": "আলফাডাঙ্গা",
    "Madhukhali": "মধুখালী",
    "Bhanga": "ভাঙ্গা",
    "Nagarkanda": "নগরকান্দা",
    "Charbhadrasan": "চরভদ্রাসন",
    "Sadarpur": "সদরপুর",
    "Manikganj Sadar": "মানিকগঞ্জ সদর",
    "Singair": "সিংগাইর",
    "Shibalaya": "শিবালয়",
    "Saturia": "সাটুরিয়া",
    "Harirampur": "হরিরামপুর",
    "Ghior": "ঘিওর",
    "Munshiganj Sadar": "মুন্সীগঞ্জ সদর",
    "Sreenagar": "শ্রীনগর",
    "Sirajdikhan": "সিরাজদিখান",
    "Louhajang": "লৌহজং",
    "Tongibari": "টঙ্গিবাড়ী",
    "Gazaria": "গজারিয়া",
    "Narsingdi Sadar": "নরসিংদী সদর",
    "Palash": "পলাশ",
    "Belabo": "বেলাবো",
    "Monohardi": "মনোহরদী",
    "Shibpur": "শিবপুর",
    "Raipura": "রায়পুরা",
    "Rajbari Sadar": "রাজবাড়ী সদর",
    "Goalanda": "গোয়ালন্দ",
    "Pangsha": "পাংশা",
    "Baliakandi": "বালিয়াকান্দি",
    "Kalukhali": "কালুখালী",
    "Madaripur Sadar": "মাদারীপুর সদর",
    "Shibchar": "শিবচর",
    "Kalkini": "কালকিনি",
    "Rajoir": "রাজৈর",
    "Gopalganj Sadar": "গোপালগঞ্জ সদর",
    "Kashiani": "কাশিয়ানী",
    "Kotalipara": "কোটালীপাড়া",
    "Muksudpur": "মুকসুদপুর",
    "Tungipara": "টুঙ্গিপাড়া",
    "Shariatpur Sadar": "শরীয়তপুর সদর",
    "Zajira": "জাজিরা",
    "Naria": "নড়িয়া",
    "Bhedarganj": "ভেদরগঞ্জ",
    "Damudya": "ডামুড্যা",
    "Gosairhat": "গোসাইরহাট",
    "Kotwali": "কোতোয়ালি",
    "Panchlaish": "পাঁচলাইশ",
    "Pahartali": "পাহাড়তলী",
    "Halishahar": "হালিশহর",
    "Patenga": "পতেঙ্গা",
    "Hathazari": "হাটহাজারী",
    "Sitakunda": "সীতাকুণ্ড",
    "Mirsharai": "মীরসরাই",
    "Patiya": "পটিয়া",
    "Boalkhali": "বোয়ালখালী",
    "Anwara": "আনোয়ারা",
    "Chandanaish": "চন্দনাইশ",
    "Satkania": "সাতকানিয়া",
    "Banshkhali": "বাঁশখালী",
    "Raozan": "রাউজান",
    "Rangunia": "রাঙ্গুনিয়া",
    "Cox's Bazar Sadar": "কক্সবাজার সদর",
    "Chakaria": "চকরিয়া",
    "Maheshkhali": "মহেশখালী",
    "Teknaf": "টেকনাফ",
    "Ukhia": "উখিয়া",
    "Ramu": "রামু",
    "Pekua": "পেকুয়া",
    "Kutubdia": "কুতুবদিয়া",
    "Cumilla Sadar": "কুমিল্লা সদর",
    "Debidwar": "দেবিদ্বার",
    "Muradnagar": "মুরাদনগর",
    "Daudkandi": "দাউদকান্দি",
    "Chandina": "চান্দিনা",
    "Laksam": "লাকসাম",
    "Brahmanpara": "ব্রাহ্মণপাড়া",
    "Burichang": "বুড়িচং",
    "Chauddagram": "চৌদ্দগ্রাম",
    "Barura": "বরুড়া",
    "Homna": "হোমনা",
    "Titas": "তিতাস",
    "Feni Sadar": "ফেনী সদর",
    "Daganbhuiyan": "দাগনভূঞা",
    "Chhagalnaiya": "ছাগলনাইয়া",
    "Sonagazi": "সোনাগাজী",
    "Parshuram": "পরশুরাম",
    "Fulgazi": "ফুলগাজী",
    "Noakhali Sadar": "নোয়াখালী সদর",
    "Begumganj": "বেগমগঞ্জ",
    "Chatkhil": "চাটখিল",
    "Companiganj": "কোম্পানীগঞ্জ",
    "Hatiya": "হাতিয়া",
    "Senbagh": "সেনবাগ",
    "Sonaimuri": "সোনাইমুড়ী",
    "Subarnachar": "সুবর্ণচর",
    "Lakshmipur Sadar": "লক্ষ্মীপুর সদর",
    "Raipur": "রায়পুর",
    "Ramganj": "রামগঞ্জ",
    "Ramgati": "রামগতি",
    "Kamalnagar": "কমলনগর",
    "Chandpur Sadar": "চাঁদপুর সদর",
    "Faridganj": "ফরিদগঞ্জ",
    "Haimchar": "হাইমচর",
    "Haziganj": "হাজীগঞ্জ",
    "Matlab Dakshin": "মতলব দক্ষিণ",
    "Matlab Uttar": "মতলব উত্তর",
    "Shahrasti": "শাহরাস্তি",
    "Boalia": "বোয়ালিয়া",
    "Motihar": "মতিহার",
    "Rajputra": "রাজপুতরা",
    "Shah Makhdum": "শাহ মখদুম",
    "Paba": "পবা",
    "Durgapur": "দুর্গাপুর",
    "Bagmara": "বাগমারা",
    "Charghat": "চারঘাট",
    "Puthia": "পুঠিয়া",
    "Bagha": "বাঘা",
    "Godagari": "গোদাগাড়ী",
    "Tanore": "তানোর",
    "Mohanpur": "মোহনপুর",
    "Bogura Sadar": "বগুড়া সদর",
    "Shibganj": "শিবগঞ্জ",
    "Sonatola": "সোনাতলা",
    "Gabtali": "গাবতলী",
    "Sariakandi": "সারিয়াকান্দি",
    "Dhunat": "ধুনট",
    "Nandigram": "নন্দীগ্রাম",
    "Kahaloo": "কাহালু",
    "Adamdighi": "আদমদিঘী",
    "Dupchanchia": "দুপচাঁচিয়া",
    "Shajahanpur": "শাজাহানপুর",
    "Pabna Sadar": "পাবনা সদর",
    "Ishwardi": "ঈশ্বরদী",
    "Chatmohar": "চাটমোহর",
    "Sujanagar": "সুজানগর",
    "Santhia": "সাঁথিয়া",
    "Bera": "বেড়া",
    "Bhangoora": "ভাঙ্গুড়া",
    "Atgharia": "আটঘরিয়া",
    "Sirajganj Sadar": "সিরাজগঞ্জ সদর",
    "Belkuchi": "বেলকুচি",
    "Chauhali": "চৌহালী",
    "Kamarkhanda": "কামারখন্দ",
    "Kazipur": "কাজীপুর",
    "Raiganj": "রায়গঞ্জ",
    "Shahjadpur": "শাহজাদপুর",
    "Tarash": "তাড়াশ",
    "Ullahpara": "উল্লাপাড়া",
    "Natore Sadar": "নাটোর সদর",
    "Baraigram": "বড়াইগ্রাম",
    "Gurudaspur": "গুরুদাসপুর",
    "Lalpur": "লালপুর",
    "Singra": "সিংড়া",
    "Bagatipara": "বাগাতিপাড়া",
    "Naldanga": "নলডাঙ্গা",
    "Naogaon Sadar": "নওগাঁ সদর",
    "Badalgachhi": "বদলগাছী",
    "Dhamoirhat": "ধামইরহাট",
    "Manda": "মান্দা",
    "Mohadevpur": "মহাদেবপুর",
    "Niamatpur": "নিয়ামতপুর",
    "Patnitala": "পত্নীতলা",
    "Porsha": "পোরশা",
    "Raninagar": "রাণীনগর",
    "Sapahar": "সাপাহার",
    "Atrai": "আত্রাই",
    "Barishal Sadar": "বরিশাল সদর",
    "Babuganj": "বাবুগঞ্জ",
    "Bakerganj": "বাকেরগঞ্জ",
    "Banaripara": "বানারীপাড়া",
    "Gaurnadi": "গৌরনদী",
    "Agailjhara": "আগৈলঝাড়া",
    "Mehendiganj": "মেহেন্দীগঞ্জ",
    "Muladi": "মুলাদী",
    "Hizla": "হিজলা",
    "Wazirpur": "উজিরপুর",
    "Bhola Sadar": "ভোলা সদর",
    "Burhanuddin": "বোরহানউদ্দিন",
    "Char Fasson": "চরফ্যাশন",
    "Daulatkhan": "দৌলতখান",
    "Lalmohan": "লালমোহন",
    "Manpura": "মনপুরা",
    "Tazumuddin": "তজুমদ্দিন",
    "Patuakhali Sadar": "পটুয়াখালী সদর",
    "Bauphal": "বাউফল",
    "Dashmina": "দশমিনা",
    "Galachipa": "গলাচিপা",
    "Kalapara": "কলাপাড়া",
    "Mirzaganj": "মির্জাগঞ্জ",
    "Dumki": "দুমকি",
    "Rangabali": "রাঙ্গাবালী",
    "Pirojpur Sadar": "পিরোজপুর সদর",
    "Bhandaria": "ভান্ডারিয়া",
    "Kawkhali": "কাউখালী",
    "Mathbaria": "মঠবাড়িয়া",
    "Nazirpur": "নাজিরপুর",
    "Nesarabad": "নেছারাবাদ",
    "Zianagar": "জিয়ানগর",
    "Jhalokathi Sadar": "ঝালকাঠি সদর",
    "Kathalia": "কাঠালিয়া",
    "Nalchity": "নলছিটি",
    "Rajapur": "রাজাপুর",
    "Barguna Sadar": "বরগুনা সদর",
    "Amtali": "আমতলী",
    "Bamna": "বামনা",
    "Betagi": "বেতাগী",
    "Patharghata": "পাথরঘাটা",
    "Taltali": "তালতলী",
    "Sylhet Sadar": "সিলেট সদর",
    "Beanibazar": "বিয়ানীবাজার",
    "Golapganj": "গোলাপগঞ্জ",
    "Fenchuganj": "ফেঞ্চুগঞ্জ",
    "Balaganj": "বালাগঞ্জ",
    "Biswanath": "বিশ্বনাথ",
    "Gowainghat": "গোয়াইনঘাট",
    "Jaintiapur": "জৈন্তাপুর",
    "Zakiganj": "জকিগঞ্জ",
    "Kanaighat": "কানাইঘাট",
    "Dakshin Surma": "দক্ষিণ সুরমা",
    "Moulvibazar Sadar": "মৌলভীবাজার সদর",
    "Barlekha": "বড়লেখা",
    "Juri": "জুড়ী",
    "Kamalganj": "কমলগঞ্জ",
    "Kulaura": "কুলাউড়া",
    "Rajnagar": "রাজনগর",
    "Sreemangal": "শ্রীমঙ্গল",
    "Habiganj Sadar": "হবিগঞ্জ সদর",
    "Bahubal": "বাহুবল",
    "Baniachong": "বানিয়াচং",
    "Chunarughat": "চুনারুঘাট",
    "Lakhai": "লাখাই",
    "Madhabpur": "মাধবপুর",
    "Nabiganj": "নবীগঞ্জ",
    "Ajmiriganj": "আজমিরীগঞ্জ",
    "Sunamganj Sadar": "সুনামগঞ্জ সদর",
    "Bishwamvarpur": "বিশ্বম্ভরপুর",
    "Chhatak": "ছাতক",
    "Derai": "দিরাই",
    "Dharampasha": "ধর্মপাশা",
    "Dowarabazar": "দোয়ারাবাজার",
    "Jagannathpur": "জগন্নাথপুর",
    "Jamalganj": "জামালগঞ্জ",
    "Sullah": "শাল্লা",
    "Tahirpur": "তাহিরপুর",
    "Rangpur Sadar": "রংপুর সদর",
    "Badarganj": "বদরগঞ্জ",
    "Gangachhara": "গঙ্গাচড়া",
    "Kaunia": "কাউনিয়া",
    "Mithapukur": "মিঠাপুকুর",
    "Pirgachha": "পীরগাছা",
    "Pirganj": "পীরগঞ্জ",
    "Taraganj": "তারাগঞ্জ",
    "Dinajpur Sadar": "দিনাজপুর সদর",
    "Birampur": "বিরামপুর",
    "Birganj": "বীরগঞ্জ",
    "Biral": "বিরল",
    "Bochaganj": "বোচাগঞ্জ",
    "Chirirbandar": "চিরিরবন্দর",
    "Phulbari": "ফুলবাড়ী",
    "Ghoraghat": "ঘোড়াঘাট",
    "Hakimpur": "হাকিমপুর",
    "Kaharole": "কাহারোল",
    "Khansama": "খানসামা",
    "Nawabganj": "নবাবগঞ্জ",
    "Parbatipur": "পার্বতীপুর",
    "Gaibandha Sadar": "গাইবান্ধা সদর",
    "Fulchhari": "ফুলছড়ি",
    "Gobindaganj": "গোবিন্দগঞ্জ",
    "Palashbari": "পলাশবাড়ী",
    "Sadullapur": "সাদুল্লাপুর",
    "Saghata": "সাঘাটা",
    "Sundarganj": "সুন্দরগঞ্জ",
    "Mymensingh Sadar": "ময়মনসিংহ সদর",
    "Muktagachha": "মুক্তাগাছা",
    "Fulbaria": "ফুলবাড়িয়া",
    "Trishal": "ত্রিশাল",
    "Bhaluka": "ভালুকা",
    "Gafargaon": "গফরগাঁও",
    "Nandail": "নান্দাইল",
    "Ishwarganj": "ঈশ্বরগঞ্জ",
    "Haluaghat": "হালুয়াঘাট",
    "Dhobaura": "ধোবাউড়া",
    "Phulpur": "ফুলপুর",
    "Tara Khanda": "তারাকান্দা",
    "Jamalpur Sadar": "জামালপুর সদর",
    "Baksiganj": "বকশীগঞ্জ",
    "Dewanganj": "দেওয়ানগঞ্জ",
    "Islampur": "ইসলামপুর",
    "Madarganj": "মাদারগঞ্জ",
    "Melandaha": "মেলান্দহ",
    "Sarishabari": "সরিষাবাড়ী",
    "Netrokona Sadar": "নেত্রকোনা সদর",
    "Atpara": "আটপাড়া",
    "Barhatta": "বারহাট্টা",
    "Khaliajuri": "খালিয়াজুড়ী",
    "Kalmakanda": "কলমাকান্দা",
    "Kendua": "কেন্দুয়া",
    "Madan": "মদন",
    "Mohanganj": "মোহনগঞ্জ",
    "Purbadhala": "পূর্বধলা",
    "Sherpur Sadar": "শেরপুর সদর",
    "Jhenaigati": "ঝিনাইগাতী",
    "Nakla": "নকলা",
    "Nalitabari": "নালিতাবাড়ী",
    "Sreebardi": "শ্রীবরদী",
    "Faridpur": "ফরিদপুর"
};

// Active language state, defaults to stored preference or 'en'
let currentAppLang = localStorage.getItem('sorok_lang') || 'en';

/**
 * Translate a key into the active language
 */
function t(key, defaultVal = '') {
    const langObj = APP_TRANSLATIONS[currentAppLang] || APP_TRANSLATIONS.en;
    if (langObj && langObj[key] !== undefined) {
        return langObj[key];
    }
    const fallbackObj = APP_TRANSLATIONS.en;
    return (fallbackObj && fallbackObj[key] !== undefined) ? fallbackObj[key] : (defaultVal || key);
}

/**
 * Translate geographic place names (Divisions, Districts, Upazillas)
 */
function translateGeoName(name) {
    if (!name) return '';
    if (currentAppLang !== 'bn') return name;

    const clean = String(name).trim();
    if (GEO_TRANSLATIONS[clean]) return GEO_TRANSLATIONS[clean];

    // Case-insensitive match
    const lower = clean.toLowerCase();
    for (const [k, v] of Object.entries(GEO_TRANSLATIONS)) {
        if (k.toLowerCase() === lower) return v;
    }

    // Pattern: "[Name] Sadar"
    if (clean.toLowerCase().endsWith(' sadar')) {
        const base = clean.substring(0, clean.length - 6).trim();
        const translatedBase = translateGeoName(base);
        return `${translatedBase} সদর`;
    }

    return clean;
}

/**
 * Translate defect type names (e.g. Pothole, Longitudinal Crack)
 */
function translateDefectType(type) {
    if (!type) return '';
    if (currentAppLang !== 'bn') return type;
    const lower = type.toLowerCase();
    if (lower.includes('pothole')) return t('defect_pothole');
    if (lower.includes('longitudinal')) return t('defect_longitudinal');
    if (lower.includes('transverse')) return t('defect_transverse');
    if (lower.includes('alligator')) return t('defect_alligator');
    return type;
}

/**
 * Translate severity label
 */
function translateSeverity(sev) {
    if (!sev) return '';
    const upper = String(sev).toUpperCase();
    if (currentAppLang === 'bn') {
        if (upper === 'CRITICAL') return 'মারাত্মক (Critical)';
        if (upper === 'HIGH') return 'উচ্চ ঝুঁকি (High)';
        if (upper === 'MEDIUM') return 'মাঝারি (Medium)';
        if (upper === 'LOW') return 'সাধারণ (Low)';
    }
    return upper;
}

/**
 * Translate urgency text
 */
function translateUrgency(urgency) {
    if (!urgency) return '';
    if (currentAppLang !== 'bn') return urgency;
    if (urgency.includes('Urgent')) return t('urgency_urgent');
    if (urgency.includes('High')) return t('urgency_high');
    if (urgency.includes('Medium')) return t('urgency_medium');
    if (urgency.includes('Routine') || urgency.includes('Safe')) return t('urgency_safe');
    return urgency;
}

/**
 * Translate Density Grade badge
 */
function translateGrade(grade) {
    if (!grade) return '';
    if (currentAppLang !== 'bn') return grade.toUpperCase();
    const upper = grade.toUpperCase();
    if (upper.includes('CRITICAL')) return t('card_badge_critical');
    if (upper.includes('HIGH')) return t('card_badge_high');
    if (upper.includes('MODERATE')) return t('card_badge_moderate');
    if (upper.includes('LOW') || upper.includes('STABLE')) return t('card_badge_stable');
    if (upper.includes('ZERO') || upper.includes('CLEAR')) return t('card_badge_zero');
    return grade;
}

/**
 * Translate lifecycle status
 */
function translateStatus(status) {
    if (!status) return '';
    if (currentAppLang !== 'bn') {
        return (status || 'reported').replace('_', ' ').toUpperCase();
    }
    const map = {
        reported: 'পর্যালোচনা বাকি',
        verified: 'যাচাইকৃত',
        assigned: 'দল বরাদ্দকৃত',
        under_repair: 'মেরামত চলছে',
        resolved: 'মেরামত সম্পন্ন'
    };
    return map[status] || status;
}

/**
 * Convert numbers to Bengali digits if Bengali is active
 */
function formatNumber(num) {
    if (num === null || num === undefined) return '';
    if (currentAppLang !== 'bn') return String(num);
    const bnDigits = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    return String(num).replace(/[0-9]/g, d => bnDigits[d]);
}

/**
 * Format timestamp nicely into the active language
 */
function formatAppDate(isoStr) {
    if (!isoStr) return '';
    try {
        const d = new Date(isoStr);
        if (isNaN(d.getTime())) return isoStr;

        if (currentAppLang === 'bn') {
            const bnMonths = ['জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'];
            const day = formatNumber(d.getDate());
            const month = bnMonths[d.getMonth()];
            const year = formatNumber(d.getFullYear());
            let hours = d.getHours();
            const minutes = formatNumber(String(d.getMinutes()).padStart(2, '0'));
            const ampm = hours >= 12 ? 'বিকাল' : 'সকাল';
            hours = hours % 12 || 12;
            return `${day} ${month} ${year}, ${ampm} ${formatNumber(hours)}:${minutes}`;
        } else {
            return d.toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        }
    } catch (e) {
        return isoStr;
    }
}

/**
 * Set and switch the active application language
 */
function setAppLanguage(lang) {
    if (lang !== 'bn' && lang !== 'en') lang = 'en';
    currentAppLang = lang;
    localStorage.setItem('sorok_lang', lang);
    
    // Update HTML root lang attribute
    document.documentElement.lang = lang;

    // Update active styles on the segmented control buttons
    updateSwitcherButtonsUI();

    // Translate all static data-i18n DOM elements
    applyTranslationsToDOM();

    // Trigger dynamic component updates
    if (typeof onLanguageChanged === 'function') {
        onLanguageChanged(lang);
    }
}

/**
 * Update the UI appearance of the segmented language switcher buttons
 */
function updateSwitcherButtonsUI() {
    const bnBtn = document.getElementById('lang-btn-bn');
    const enBtn = document.getElementById('lang-btn-en');

    if (!bnBtn || !enBtn) return;

    if (currentAppLang === 'bn') {
        bnBtn.className = 'px-3.5 sm:px-5 py-2 sm:py-2.5 rounded-lg transition-all duration-150 flex items-center gap-1.5 font-bold text-sm sm:text-base bg-white text-sky-700 shadow-xs border border-slate-200/60 cursor-pointer';
        enBtn.className = 'px-3.5 sm:px-5 py-2 sm:py-2.5 rounded-lg transition-all duration-150 flex items-center gap-1.5 font-bold text-sm sm:text-base text-slate-500 hover:text-slate-800 cursor-pointer';
    } else {
        enBtn.className = 'px-3.5 sm:px-5 py-2 sm:py-2.5 rounded-lg transition-all duration-150 flex items-center gap-1.5 font-bold text-sm sm:text-base bg-white text-slate-900 shadow-xs border border-slate-200/60 cursor-pointer';
        bnBtn.className = 'px-3.5 sm:px-5 py-2 sm:py-2.5 rounded-lg transition-all duration-150 flex items-center gap-1.5 font-bold text-sm sm:text-base text-slate-500 hover:text-slate-800 cursor-pointer';
    }
}

/**
 * Scan DOM and replace innerText, placeholders, titles of tagged elements
 */
function applyTranslationsToDOM() {
    // Inner text / HTML
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (key) {
            el.textContent = t(key);
        }
    });

    // Placeholders
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
        const key = el.getAttribute('data-i18n-placeholder');
        if (key) {
            el.placeholder = t(key);
        }
    });

    // Title attributes
    document.querySelectorAll('[data-i18n-title]').forEach(el => {
        const key = el.getAttribute('data-i18n-title');
        if (key) {
            el.title = t(key);
        }
    });
}

// Auto-initialize when document is loaded
document.addEventListener('DOMContentLoaded', () => {
    updateSwitcherButtonsUI();
    applyTranslationsToDOM();
});
