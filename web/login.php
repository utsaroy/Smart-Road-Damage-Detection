<?php
/**
 * Starting Page: Sign Up & Sign In Portal - SorokSurokkha
 * Professional Whitish Civic Design matching the Dashboard
 * User signs up first, then signs in to enter dashboard
 * Comfortable readable sizing without awkward top tabs
 */

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/geo_helper.php';

// If already logged in, redirect directly to appropriate dashboard
if (Auth::check()) {
    $role = Auth::role();
    if ($role === 'crew') {
        header("Location: crew_dashboard.php");
        exit;
    } else {
        header("Location: index.php");
        exit;
    }
}

$geoHierarchy = BangladeshGeo::getHierarchy();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SorokSurokkha - Portal Sign Up & Sign In</title>
    <link rel="icon" type="image/png" href="assets/images/logo.png">

    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: {
                            50: '#f0f9ff',
                            100: '#e0f2fe',
                            500: '#0284c7',
                            600: '#0369a1',
                            700: '#075985',
                            900: '#0c4a6e',
                        }
                    }
                }
            }
        }
    </script>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Hind+Siliguri:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    <script src="https://unpkg.com/lucide@latest"></script>
    <link rel="stylesheet" href="assets/css/style.css?v=<?= time() ?>">
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
    <script src="assets/js/i18n.js?v=<?= time() ?>"></script>
</head>
<body class="bg-slate-50 text-slate-800 min-h-screen flex flex-col justify-between font-sans antialiased selection:bg-sky-500 selection:text-white">

    <!-- Top Administrative Header (Whitish) -->
    <header class="bg-white border-b border-slate-200/90 shadow-2xs py-3 px-4 sm:px-8 shrink-0">
        <div class="max-w-6xl mx-auto flex items-center justify-between">
            <div class="flex items-center gap-3.5">
                <img src="assets/images/logo.png" alt="SorokSurokkha Logo" class="w-11 h-11 sm:w-12 sm:h-12 object-contain drop-shadow-2xs">
                <div>
                    <div class="flex items-center gap-2">
                        <span class="text-xl sm:text-2xl font-black text-slate-900 tracking-tight" data-i18n="app_title">SorokSurokkha</span>
                        <span class="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded bg-sky-50 text-sky-700 border border-sky-200 shadow-2xs">
                            DSS v2.4
                        </span>
                    </div>
                    <p class="text-xs text-slate-500 font-medium hidden sm:block mt-0.5" data-i18n="app_subtitle">Smart Road Hazard & Construction Crew Management</p>
                </div>
            </div>

            <!-- Language Selector Segment -->
            <div class="flex items-center bg-slate-100 p-1 rounded-xl border border-slate-200 select-none shadow-2xs">
                <button type="button" id="lang-btn-bn" onclick="setAppLanguage('bn')"
                        class="px-3.5 py-1.5 rounded-lg transition-all font-bold text-xs sm:text-sm text-slate-600 hover:text-slate-900 cursor-pointer">
                    <span>বাংলা</span>
                </button>
                <button type="button" id="lang-btn-en" onclick="setAppLanguage('en')"
                        class="px-3.5 py-1.5 rounded-lg transition-all font-bold text-xs sm:text-sm text-slate-600 hover:text-slate-900 cursor-pointer">
                    <span>English</span>
                </button>
            </div>
        </div>
    </header>

    <!-- Main Content Area: Centered Card (Whitish Aesthetic, Comfortable Sizing) -->
    <main class="flex-1 flex items-center justify-center p-4 sm:p-6 my-auto">
        <div class="w-full max-w-xl bg-white border border-slate-200/90 rounded-2xl shadow-xl shadow-slate-200/60 p-6 sm:p-8">

            <!-- Dynamic Alert / Notification Banner -->
            <div id="auth-alert" class="hidden mb-4 p-3 rounded-xl text-xs sm:text-sm font-semibold flex items-center gap-2.5 border"></div>

            <!-- ================= VIEW 1: SIGN UP (DEFAULT INITIAL STEP) ================= -->
            <div id="view-signup">
                <!-- Card Header -->
                <div class="flex items-center gap-3 mb-5 pb-3 border-b border-slate-100">
                    <div class="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center border border-emerald-200 shrink-0 shadow-2xs">
                        <i data-lucide="user-plus" class="w-5 h-5"></i>
                    </div>
                    <div>
                        <h2 class="text-lg sm:text-xl font-bold text-slate-900" id="card-heading-signup">Register New Account</h2>
                        <p class="text-xs text-slate-500" id="card-subheading-signup">Sign up first to create your credentials, then sign in to enter dashboard</p>
                    </div>
                </div>

                <form id="form-signup" onsubmit="handleSignUp(event)" class="space-y-3.5" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false">

                    <!-- Role Radio Selector (Comfortably Sized) -->
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5" id="lbl-role-select">
                            Select Account Role
                        </label>
                        <div class="grid grid-cols-2 gap-3">
                            <label class="p-3 rounded-xl border border-amber-300 bg-amber-50/60 flex items-center gap-2.5 cursor-pointer transition hover:bg-amber-50 has-[:checked]:border-amber-500 has-[:checked]:bg-amber-100/70 shadow-2xs">
                                <input type="radio" name="signup-role" value="crew" checked onchange="toggleCrewGeoFields(true)" class="accent-amber-600 w-4 h-4">
                                <div class="min-w-0">
                                    <div class="text-xs sm:text-sm font-bold text-slate-900 flex items-center gap-1.5 truncate">
                                        <i data-lucide="hard-hat" class="w-4 h-4 text-amber-600 shrink-0"></i>
                                        <span id="lbl-role-crew-title">Crew Member</span>
                                    </div>
                                    <div class="text-[11px] text-slate-500 truncate" id="lbl-role-crew-desc">Road Repair Field Team</div>
                                </div>
                            </label>

                            <label class="p-3 rounded-xl border border-slate-200 bg-slate-50/80 flex items-center gap-2.5 cursor-pointer transition hover:bg-sky-50/50 has-[:checked]:border-sky-500 has-[:checked]:bg-sky-50/80 shadow-2xs">
                                <input type="radio" name="signup-role" value="authority" onchange="toggleCrewGeoFields(false)" class="accent-sky-600 w-4 h-4">
                                <div class="min-w-0">
                                    <div class="text-xs sm:text-sm font-bold text-slate-900 flex items-center gap-1.5 truncate">
                                        <i data-lucide="shield-check" class="w-4 h-4 text-sky-600 shrink-0"></i>
                                        <span id="lbl-role-auth-title">Authority</span>
                                    </div>
                                    <div class="text-[11px] text-slate-500 truncate" id="lbl-role-auth-desc">Road & Highway Dept</div>
                                </div>
                            </label>
                        </div>
                    </div>

                    <!-- Full Name & Phone -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1" id="lbl-reg-name">Full Name</label>
                            <input type="text" id="signup-name" name="new_full_name" required placeholder="e.g. Engr. Asaduzzaman"
                                   autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" data-lpignore="true" data-form-type="other"
                                   class="w-full bg-slate-50 border border-slate-300 rounded-xl px-3.5 py-2 text-xs sm:text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-emerald-500 transition">
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1" id="lbl-reg-phone">Phone Number</label>
                            <input type="text" id="signup-phone" name="new_phone_num" placeholder="+880 1712-345678"
                                   autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" data-lpignore="true" data-form-type="other"
                                   class="w-full bg-slate-50 border border-slate-300 rounded-xl px-3.5 py-2 text-xs sm:text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-emerald-500 transition">
                        </div>
                    </div>

                    <!-- Email & Team Name -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1" id="lbl-reg-email">Email Address</label>
                            <input type="email" id="signup-email" name="new_email_addr" required placeholder="name@amarpath.gov.bd"
                                   autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" data-lpignore="true" data-form-type="other"
                                   class="w-full bg-slate-50 border border-slate-300 rounded-xl px-3.5 py-2 text-xs sm:text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-emerald-500 transition">
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1" id="lbl-reg-team">Team / Unit Name</label>
                            <input type="text" id="signup-team" name="new_team_title" placeholder="e.g. Quick Patch Unit 1"
                                   autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" data-lpignore="true" data-form-type="other"
                                   class="w-full bg-slate-50 border border-slate-300 rounded-xl px-3.5 py-2 text-xs sm:text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-emerald-500 transition">
                        </div>
                    </div>

                    <!-- Cascading Jurisdiction (Division -> District -> Upazilla) -->
                    <div id="crew-geo-section" class="p-3 rounded-xl bg-amber-50/50 border border-amber-200/80 space-y-2">
                        <div class="text-xs font-bold text-amber-900 flex items-center gap-1.5" id="lbl-geo-jurisdiction">
                            <i data-lucide="map-pin" class="w-3.5 h-3.5 text-amber-600"></i>
                            <span>Assigned Jurisdiction (Upazilla)</span>
                        </div>

                        <div class="grid grid-cols-3 gap-2">
                            <div>
                                <select id="signup-division" onchange="onSignUpDivisionChange()" class="w-full bg-white border border-slate-300 rounded-lg px-2 py-1.5 text-xs text-slate-800 focus:outline-none focus:border-amber-500">
                                    <option value="">Division</option>
                                </select>
                            </div>
                            <div>
                                <select id="signup-district" onchange="onSignUpDistrictChange()" class="w-full bg-white border border-slate-300 rounded-lg px-2 py-1.5 text-xs text-slate-800 focus:outline-none focus:border-amber-500">
                                    <option value="">District</option>
                                </select>
                            </div>
                            <div>
                                <select id="signup-upazilla" class="w-full bg-white border border-slate-300 rounded-lg px-2 py-1.5 text-xs text-slate-800 focus:outline-none focus:border-amber-500">
                                    <option value="">Upazilla</option>
                                </select>
                            </div>
                        </div>
                    </div>

                    <!-- Password & Confirm Password with Visibility Toggle -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1" id="lbl-reg-pwd">Password</label>
                            <div class="relative">
                                <input type="password" id="signup-password" name="new_sec_pwd" required placeholder="Min 6 characters"
                                       autocomplete="new-password" autocorrect="off" autocapitalize="off" spellcheck="false" data-lpignore="true"
                                       class="w-full bg-slate-50 border border-slate-300 rounded-xl pl-3.5 pr-10 py-2 text-xs sm:text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-emerald-500 transition">
                                <button type="button" onclick="togglePasswordVisibility('signup-password', this)"
                                        class="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 focus:outline-none p-1 rounded cursor-pointer transition"
                                        aria-label="Toggle password visibility">
                                    <i data-lucide="eye" class="w-4 h-4"></i>
                                </button>
                            </div>
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1" id="lbl-reg-cpwd">Confirm Password</label>
                            <div class="relative">
                                <input type="password" id="signup-cpassword" name="new_sec_cpwd" required placeholder="Repeat password"
                                       autocomplete="new-password" autocorrect="off" autocapitalize="off" spellcheck="false" data-lpignore="true"
                                       class="w-full bg-slate-50 border border-slate-300 rounded-xl pl-3.5 pr-10 py-2 text-xs sm:text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-emerald-500 transition">
                                <button type="button" onclick="togglePasswordVisibility('signup-cpassword', this)"
                                        class="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 focus:outline-none p-1 rounded cursor-pointer transition"
                                        aria-label="Toggle password visibility">
                                    <i data-lucide="eye" class="w-4 h-4"></i>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Sign Up Submit Button -->
                    <button type="submit" id="btn-submit-signup"
                            class="w-full py-2.5 sm:py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl shadow-md flex items-center justify-center gap-2 transition cursor-pointer text-sm sm:text-base mt-2">
                        <i data-lucide="user-check" class="w-4 h-4"></i>
                        <span id="txt-submit-signup">Register Account & Proceed to Sign In</span>
                    </button>

                    <!-- Already Signed Up Callout -->
                    <div class="text-center pt-3 border-t border-slate-100 text-xs sm:text-sm text-slate-600">
                        <span id="txt-already-account">Already Signed Up?</span>
                        <button type="button" onclick="showSignInView()"
                                class="font-extrabold text-sky-700 hover:text-sky-900 underline ml-1 cursor-pointer" id="lnk-switch-signin">
                            Sign In here &rarr;
                        </button>
                    </div>
                </form>
            </div>

            <!-- ================= VIEW 2: SIGN IN (STEP 2 TO ENTER DASHBOARD) ================= -->
            <div id="view-signin" class="hidden">
                <!-- Card Header -->
                <div class="flex items-center gap-3 mb-5 pb-3 border-b border-slate-100">
                    <div class="w-10 h-10 rounded-xl bg-sky-50 text-sky-600 flex items-center justify-center border border-sky-200 shrink-0 shadow-2xs">
                        <i data-lucide="log-in" class="w-5 h-5"></i>
                    </div>
                    <div>
                        <h2 class="text-lg sm:text-xl font-bold text-slate-900" id="card-heading-signin">Sign In to Dashboard</h2>
                        <p class="text-xs text-slate-500" id="card-subheading-signin">Enter your email and password to enter your dashboard</p>
                    </div>
                </div>

                <form id="form-signin" onsubmit="handleSignIn(event)" class="space-y-4">
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5" id="lbl-login-email">
                            Email Address or Username
                        </label>
                        <div class="relative">
                            <i data-lucide="mail" class="w-4 h-4 text-slate-400 absolute left-3.5 top-3"></i>
                            <input type="text" id="signin-email" required
                                   placeholder="e.g. authority@amarpath.gov.bd or crew.khulna@amarpath.gov.bd"
                                   class="w-full bg-slate-50 border border-slate-300 rounded-xl pl-10 pr-3.5 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-sky-500 transition">
                        </div>
                    </div>

                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5" id="lbl-login-pwd">
                            Password
                        </label>
                        <div class="relative">
                            <i data-lucide="lock" class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2"></i>
                            <input type="password" id="signin-password" required placeholder="••••••••"
                                   class="w-full bg-slate-50 border border-slate-300 rounded-xl pl-10 pr-10 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-sky-500 transition">
                            <button type="button" onclick="togglePasswordVisibility('signin-password', this)"
                                    class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 focus:outline-none p-1 rounded cursor-pointer transition"
                                    aria-label="Toggle password visibility">
                                <i data-lucide="eye" class="w-4 h-4"></i>
                            </button>
                        </div>
                    </div>

                    <button type="submit" id="btn-submit-signin"
                            class="w-full py-2.5 sm:py-3 bg-slate-900 hover:bg-slate-800 text-white font-bold rounded-xl shadow-md flex items-center justify-center gap-2 transition cursor-pointer text-sm sm:text-base mt-2">
                        <i data-lucide="arrow-right-circle" class="w-4 h-4"></i>
                        <span id="txt-submit-signin">Sign In to Dashboard</span>
                    </button>

                    <!-- Need an Account Callout -->
                    <div class="text-center pt-3 border-t border-slate-100 text-xs sm:text-sm text-slate-600">
                        <span id="txt-no-account">Don't have an account yet?</span>
                        <button type="button" onclick="showSignUpView()"
                                class="font-extrabold text-emerald-700 hover:text-emerald-900 underline ml-1 cursor-pointer" id="lnk-switch-signup">
                            Sign Up first &rarr;
                        </button>
                    </div>

                    <!-- One-Click Demo Quick Logins (Comfortable Sizing) -->
                    <div class="pt-3 border-t border-slate-100">
                        <p class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2.5 flex items-center gap-1.5" id="txt-quick-demo">
                            <i data-lucide="zap" class="w-3.5 h-3.5 text-amber-500"></i>
                            <span>One-Click Demo Access</span>
                        </p>

                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                            <!-- Authority Quick Login -->
                            <button type="button" onclick="quickFill('authority@amarpath.gov.bd', 'admin123')"
                                    class="p-2.5 bg-slate-50 hover:bg-sky-50/50 border border-slate-200 hover:border-sky-300 rounded-xl text-left transition flex items-center gap-2.5 group cursor-pointer shadow-2xs">
                                <span class="p-2 rounded-lg bg-sky-100 text-sky-700 shrink-0">
                                    <i data-lucide="shield-check" class="w-4 h-4"></i>
                                </span>
                                <div class="min-w-0">
                                    <div class="text-xs font-bold text-slate-900 truncate" id="lbl-demo-auth-role">Road Authority</div>
                                    <div class="text-[11px] text-slate-500 truncate">Munem Shahriar</div>
                                </div>
                            </button>

                            <!-- Crew Khan Jahan Ali Quick Login -->
                            <button type="button" onclick="quickFill('crew.khulna@amarpath.gov.bd', 'crew123')"
                                    class="p-2.5 bg-slate-50 hover:bg-amber-50/50 border border-slate-200 hover:border-amber-300 rounded-xl text-left transition flex items-center gap-2.5 group cursor-pointer shadow-2xs">
                                <span class="p-2 rounded-lg bg-amber-100 text-amber-700 shrink-0">
                                    <i data-lucide="hard-hat" class="w-4 h-4"></i>
                                </span>
                                <div class="min-w-0">
                                    <div class="text-xs font-bold text-slate-900 truncate" id="lbl-demo-crew-role">Crew (Khulna)</div>
                                    <div class="text-[11px] text-slate-500 truncate">Khan Jahan Ali</div>
                                </div>
                            </button>
                        </div>
                    </div>
                </form>
            </div>

        </div>
    </main>

    <!-- Compact Civic Footer -->
    <footer class="bg-white border-t border-slate-200/90 py-3 px-4 text-center text-xs text-slate-500 shrink-0">
        <p>&copy; <?= date('Y') ?> SorokSurokkha &bull; Bangladesh Road & Highway Management Portal &bull; Multi-Role DSS</p>
    </footer>

    <!-- Pass Geo Hierarchy to JS -->
    <script>
        const GEO_HIERARCHY = <?= json_encode($geoHierarchy, JSON_UNESCAPED_UNICODE) ?>;
    </script>

    <!-- Authentication Client Script -->
    <script>
        // Password Visibility Toggle Helper (Show / Hide Password)
        function togglePasswordVisibility(fieldId, btn) {
            const field = document.getElementById(fieldId);
            if (!field) return;
            const isPassword = field.type === 'password';
            field.type = isPassword ? 'text' : 'password';
            btn.innerHTML = `<i data-lucide="${isPassword ? 'eye-off' : 'eye'}" class="w-4 h-4"></i>`;
            btn.setAttribute('aria-label', isPassword ? 'Hide password' : 'Show password');
            lucide.createIcons();
        }

        // Clear all signup form fields to avoid autofill/cached suggestions
        function clearSignupForm() {
            const form = document.getElementById('form-signup');
            if (form) form.reset();
            const fieldIds = ['signup-name', 'signup-phone', 'signup-email', 'signup-team', 'signup-password', 'signup-cpassword'];
            fieldIds.forEach(id => {
                const el = document.getElementById(id);
                if (el) {
                    el.value = '';
                    el.setAttribute('autocomplete', id.includes('password') ? 'new-password' : 'off');
                }
            });
        }

        document.addEventListener('DOMContentLoaded', () => {
            lucide.createIcons();
            applyLoginLanguage(currentAppLang);
            clearSignupForm();
            // Default to Sign Up view as requested
            showSignUpView();
            setTimeout(clearSignupForm, 100);
            setTimeout(clearSignupForm, 400);
        });

        // Switch to Sign Up View
        function showSignUpView() {
            document.getElementById('view-signup').classList.remove('hidden');
            document.getElementById('view-signin').classList.add('hidden');
            document.getElementById('auth-alert').classList.add('hidden');
            clearSignupForm();
            lucide.createIcons();
        }

        // Switch to Sign In View
        function showSignInView() {
            document.getElementById('view-signin').classList.remove('hidden');
            document.getElementById('view-signup').classList.add('hidden');
            document.getElementById('auth-alert').classList.add('hidden');
            lucide.createIcons();
        }

        // Quick Fill for Demo
        function quickFill(email, pwd) {
            showSignInView();
            document.getElementById('signin-email').value = email;
            document.getElementById('signin-password').value = pwd;
            showAlert('Demo credentials filled. Signing in...', 'info');
            setTimeout(() => {
                document.getElementById('form-signin').dispatchEvent(new Event('submit', { cancelable: true, bubbles: true }));
            }, 250);
        }

        // Alert Helper
        function showAlert(msg, type = 'error') {
            const box = document.getElementById('auth-alert');
            box.classList.remove('hidden', 'bg-rose-50', 'border-rose-200', 'text-rose-800', 'bg-emerald-50', 'border-emerald-200', 'text-emerald-800', 'bg-sky-50', 'border-sky-200', 'text-sky-800');

            if (type === 'error') {
                box.classList.add('bg-rose-50', 'border-rose-200', 'text-rose-800');
                box.innerHTML = `<i data-lucide="alert-circle" class="w-4 h-4 text-rose-600 shrink-0"></i><span>${msg}</span>`;
            } else if (type === 'success') {
                box.classList.add('bg-emerald-50', 'border-emerald-200', 'text-emerald-800');
                box.innerHTML = `<i data-lucide="check-circle" class="w-4 h-4 text-emerald-600 shrink-0"></i><span>${msg}</span>`;
            } else {
                box.classList.add('bg-sky-50', 'border-sky-200', 'text-sky-800');
                box.innerHTML = `<i data-lucide="info" class="w-4 h-4 text-sky-600 shrink-0"></i><span>${msg}</span>`;
            }
            lucide.createIcons();
        }

        // Toggle Geo fields based on role
        function toggleCrewGeoFields(isCrew) {
            const geoSec = document.getElementById('crew-geo-section');
            if (geoSec) {
                geoSec.style.display = isCrew ? 'block' : 'none';
            }
        }

        // Populate Division Dropdown dynamically with bilingual labels
        function populateSignupDivisions(lang) {
            const isBn = lang === 'bn';
            const divSelect = document.getElementById('signup-division');
            if (!divSelect) return;
            const curVal = divSelect.value;
            divSelect.innerHTML = `<option value="">${isBn ? 'বিভাগ নির্বাচন করুন' : 'Division'}</option>`;
            if (typeof GEO_HIERARCHY !== 'undefined') {
                Object.keys(GEO_HIERARCHY).forEach(div => {
                    const opt = document.createElement('option');
                    opt.value = div;
                    opt.textContent = (isBn && typeof translateGeoName === 'function') ? translateGeoName(div) : div;
                    if (div === curVal) opt.selected = true;
                    divSelect.appendChild(opt);
                });
            }
        }

        // Cascading Division -> District
        function onSignUpDivisionChange() {
            const isBn = currentAppLang === 'bn';
            const divSelect = document.getElementById('signup-division');
            const distSelect = document.getElementById('signup-district');
            const upzSelect = document.getElementById('signup-upazilla');
            if (!divSelect || !distSelect || !upzSelect) return;

            const div = divSelect.value;
            const curDist = distSelect.value;

            distSelect.innerHTML = `<option value="">${isBn ? 'জেলা নির্বাচন করুন' : 'District'}</option>`;
            upzSelect.innerHTML = `<option value="">${isBn ? 'উপজেলা নির্বাচন করুন' : 'Upazilla'}</option>`;

            if (div && typeof GEO_HIERARCHY !== 'undefined' && GEO_HIERARCHY[div]) {
                Object.keys(GEO_HIERARCHY[div]).forEach(dist => {
                    const opt = document.createElement('option');
                    opt.value = dist;
                    opt.textContent = (isBn && typeof translateGeoName === 'function') ? translateGeoName(dist) : dist;
                    if (dist === curDist) opt.selected = true;
                    distSelect.appendChild(opt);
                });
            }
        }

        // Cascading District -> Upazilla
        function onSignUpDistrictChange() {
            const isBn = currentAppLang === 'bn';
            const divSelect = document.getElementById('signup-division');
            const distSelect = document.getElementById('signup-district');
            const upzSelect = document.getElementById('signup-upazilla');
            if (!divSelect || !distSelect || !upzSelect) return;

            const div = divSelect.value;
            const dist = distSelect.value;
            const curUpz = upzSelect.value;

            upzSelect.innerHTML = `<option value="">${isBn ? 'উপজেলা নির্বাচন করুন' : 'Upazilla'}</option>`;

            if (div && dist && typeof GEO_HIERARCHY !== 'undefined' && GEO_HIERARCHY[div] && GEO_HIERARCHY[div][dist]) {
                GEO_HIERARCHY[div][dist].forEach(upz => {
                    const opt = document.createElement('option');
                    opt.value = upz;
                    opt.textContent = (isBn && typeof translateGeoName === 'function') ? translateGeoName(upz) : upz;
                    if (upz === curUpz) opt.selected = true;
                    upzSelect.appendChild(opt);
                });
            }
        }

        // Handle Sign Up Submit -> Then switch to Sign In
        async function handleSignUp(e) {
            e.preventDefault();
            const role = document.querySelector('input[name="signup-role"]:checked').value;
            const name = document.getElementById('signup-name').value.trim();
            const email = document.getElementById('signup-email').value.trim();
            const phone = document.getElementById('signup-phone').value.trim();
            const team = document.getElementById('signup-team').value.trim();
            const password = document.getElementById('signup-password').value;
            const cpassword = document.getElementById('signup-cpassword').value;

            const division = document.getElementById('signup-division').value;
            const district = document.getElementById('signup-district').value;
            const upazilla = document.getElementById('signup-upazilla').value;

            if (password !== cpassword) {
                showAlert(currentAppLang === 'bn' ? 'পাসওয়ার্ড দুটি মেলেনি।' : 'Passwords do not match.', 'error');
                return;
            }

            if (role === 'crew' && (!division || !district || !upazilla)) {
                showAlert(currentAppLang === 'bn' ? 'অনুগ্রহ করে নির্ধারিত বিভাগ, জেলা ও উপজেলা নির্বাচন করুন।' : 'Please select your assigned Division, District, and Upazilla.', 'error');
                return;
            }

            const btn = document.getElementById('btn-submit-signup');
            btn.disabled = true;
            btn.innerHTML = `<i data-lucide="loader" class="w-4 h-4 animate-spin"></i><span>Registering...</span>`;
            lucide.createIcons();

            try {
                const formData = new FormData();
                formData.append('action', 'register');
                formData.append('role', role);
                formData.append('name', name);
                formData.append('email', email);
                formData.append('phone', phone);
                formData.append('team_name', team);
                formData.append('password', password);
                formData.append('division', division);
                formData.append('district', district);
                formData.append('upazilla', upazilla);

                // 1. Direct Supabase Client Auth Signup
                if (window.supabase) {
                    try {
                        const supaClient = window.supabase.createClient(
                            'https://dytilqslhxmlhrwselam.supabase.co',
                            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR5dGlscXNsaHhtbGhyd3NlbGFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5NDE5MDIsImV4cCI6MjEwODUxNzkwMn0.NHMeba85rqFXLO7UAnLqAT_j9J50Y-mwqRVpiVV59Uk'
                        );
                        await supaClient.auth.signUp({
                            email: email,
                            password: password,
                            options: {
                                data: {
                                    full_name: name,
                                    role: role,
                                    phone: phone,
                                    team_name: team,
                                    division: division,
                                    district: district,
                                    upazilla: upazilla
                                }
                            }
                        });
                    } catch (supaErr) {
                        console.warn('Supabase client registration note:', supaErr);
                    }
                }

                // 2. Local Database & Server Sync
                const res = await fetch('api/auth.php', { method: 'POST', body: formData });
                const data = await res.json();

                if (data.success) {
                    // Sign Up first, then Sign In to enter dashboard
                    await fetch('api/auth.php?action=logout');

                    // Pre-fill email in Sign In view
                    document.getElementById('signin-email').value = email;
                    document.getElementById('signin-password').value = '';
                    
                    // Switch to Sign In view
                    showSignInView();
                    showAlert(
                        currentAppLang === 'bn' 
                            ? '✅ রেজিস্ট্রেশন সফল হয়েছে! ড্যাশবোর্ডে প্রবেশ করতে অনুগ্রহ করে সাইন ইন করুন।' 
                            : '✅ Account registered successfully! Please Sign In below to enter your dashboard.', 
                        'success'
                    );
                } else {
                    showAlert(data.error || 'Registration failed.', 'error');
                }
            } catch (err) {
                showAlert('Network or server error during registration.', 'error');
            } finally {
                btn.disabled = false;
                btn.innerHTML = `<i data-lucide="user-check" class="w-4 h-4"></i><span>${currentAppLang === 'bn' ? 'রেজিস্ট্রেশন সম্পন্ন করে সাইন ইন করুন' : 'Register Account & Proceed to Sign In'}</span>`;
                lucide.createIcons();
            }
        }

        // Handle Sign In Submit -> Enter Dashboard
        async function handleSignIn(e) {
            e.preventDefault();
            const email = document.getElementById('signin-email').value.trim();
            const password = document.getElementById('signin-password').value;
            const btn = document.getElementById('btn-submit-signin');

            btn.disabled = true;
            btn.innerHTML = `<i data-lucide="loader" class="w-4 h-4 animate-spin"></i><span>Signing in...</span>`;
            lucide.createIcons();

            try {
                const formData = new FormData();
                formData.append('action', 'login');
                formData.append('email', email);
                formData.append('password', password);

                // Local Database & Server Sync
                const res = await fetch('api/auth.php', { method: 'POST', body: formData });
                const data = await res.json();

                if (data.success) {
                    showAlert(currentAppLang === 'bn' ? `স্বাগতম, ${data.user.name}! প্রবেশ করা হচ্ছে...` : `Welcome back, ${data.user.name}! Redirecting...`, 'success');
                    setTimeout(() => {
                        window.location.href = data.redirect;
                    }, 500);
                } else {
                    showAlert(data.error || (currentAppLang === 'bn' ? 'ভুল লগইন তথ্য।' : 'Invalid login credentials.'), 'error');
                    btn.disabled = false;
                    btn.innerHTML = `<i data-lucide="arrow-right-circle" class="w-4 h-4"></i><span>${currentAppLang === 'bn' ? 'ড্যাশবোর্ডে প্রবেশ করুন' : 'Sign In to Dashboard'}</span>`;
                    lucide.createIcons();
                }
            } catch (err) {
                showAlert(currentAppLang === 'bn' ? 'সার্ভারে সংযোগ ত্রুটি।' : 'Network or server error during sign in.', 'error');
                btn.disabled = false;
                btn.innerHTML = `<i data-lucide="arrow-right-circle" class="w-4 h-4"></i><span>${currentAppLang === 'bn' ? 'ড্যাশবোর্ডে প্রবেশ করুন' : 'Sign In to Dashboard'}</span>`;
                lucide.createIcons();
            }
        }

        // Bilingual Dynamic Labels for Login Screen
        function applyLoginLanguage(lang) {
            const isBn = lang === 'bn';

            // Sign Up View Headings
            document.getElementById('card-heading-signup').textContent = isBn ? 'নতুন অ্যাকাউন্ট তৈরি করুন' : 'Register New Account';
            document.getElementById('card-subheading-signup').textContent = isBn ? 'প্রথমে সাইন আপ সম্পন্ন করুন, এরপর সাইন ইন করে ড্যাশবোর্ডে প্রবেশ করুন' : 'Sign up first to create your credentials, then sign in to enter dashboard';

            // Role Selector Headings and Descriptions
            document.getElementById('lbl-role-select').textContent = isBn ? 'অ্যাকাউন্টের ভূমিকা নির্বাচন করুন' : 'Select Account Role';
            const crewTitle = document.getElementById('lbl-role-crew-title');
            if (crewTitle) crewTitle.textContent = isBn ? 'নির্মাণ ও মেরামত কর্মী' : 'Crew Member';
            const crewDesc = document.getElementById('lbl-role-crew-desc');
            if (crewDesc) crewDesc.textContent = isBn ? 'সড়ক মেরামত ফিল্ড টিম' : 'Road Repair Field Team';
            const authTitle = document.getElementById('lbl-role-auth-title');
            if (authTitle) authTitle.textContent = isBn ? 'সড়ক কর্তৃপক্ষ' : 'Authority';
            const authDesc = document.getElementById('lbl-role-auth-desc');
            if (authDesc) authDesc.textContent = isBn ? 'সড়ক ও জনপথ বিভাগ' : 'Road & Highway Dept';

            // Signup Field Labels
            document.getElementById('lbl-reg-name').textContent = isBn ? 'পূর্ণ নাম' : 'Full Name';
            document.getElementById('lbl-reg-phone').textContent = isBn ? 'মোবাইল নম্বর' : 'Phone Number';
            document.getElementById('lbl-reg-email').textContent = isBn ? 'ইমেইল ঠিকানা' : 'Email Address';
            document.getElementById('lbl-reg-team').textContent = isBn ? 'দলের নাম / ইউনিট' : 'Team / Unit Name';
            document.getElementById('lbl-geo-jurisdiction').innerHTML = `<i data-lucide="map-pin" class="w-3.5 h-3.5 text-amber-600"></i><span>${isBn ? 'নির্ধারিত উপজেলা এরিয়া' : 'Assigned Jurisdiction (Upazilla)'}</span>`;
            document.getElementById('lbl-reg-pwd').textContent = isBn ? 'পাসওয়ার্ড' : 'Password';
            document.getElementById('lbl-reg-cpwd').textContent = isBn ? 'পাসওয়ার্ড নিশ্চিত করুন' : 'Confirm Password';
            document.getElementById('txt-submit-signup').textContent = isBn ? 'রেজিস্ট্রেশন সম্পন্ন করে সাইন ইন করুন' : 'Register Account & Proceed to Sign In';

            // Input Placeholders (Zero Language Mismatch!)
            const nameInput = document.getElementById('signup-name');
            if (nameInput) nameInput.placeholder = isBn ? 'যেমনঃ মোঃ আসাদুজ্জামান' : 'e.g. Engr. Asaduzzaman';
            const phoneInput = document.getElementById('signup-phone');
            if (phoneInput) phoneInput.placeholder = isBn ? '০১৭১২-৩৪৫৬৭৮' : '+880 1712-345678';
            const emailInput = document.getElementById('signup-email');
            if (emailInput) emailInput.placeholder = isBn ? 'name@amarpath.gov.bd' : 'name@amarpath.gov.bd';
            const teamInput = document.getElementById('signup-team');
            if (teamInput) teamInput.placeholder = isBn ? 'যেমনঃ কুইক প্যাচ টিম ১' : 'e.g. Quick Patch Unit 1';
            const pwdInput = document.getElementById('signup-password');
            if (pwdInput) pwdInput.placeholder = isBn ? 'কমপক্ষে ৬ অক্ষর' : 'Min 6 characters';
            const cpwdInput = document.getElementById('signup-cpassword');
            if (cpwdInput) cpwdInput.placeholder = isBn ? 'পাসওয়ার্ড পুনরায় লিখুন' : 'Repeat password';

            // Dynamic Localized Geo Dropdowns
            const curDist = document.getElementById('signup-district').value;
            const curUpz = document.getElementById('signup-upazilla').value;
            populateSignupDivisions(lang);
            onSignUpDivisionChange();
            if (curDist) {
                document.getElementById('signup-district').value = curDist;
                onSignUpDistrictChange();
                if (curUpz) {
                    document.getElementById('signup-upazilla').value = curUpz;
                }
            }

            // Already Signed Up switch
            document.getElementById('txt-already-account').textContent = isBn ? 'ইতিমধ্যে সাইন আপ করেছেন?' : 'Already Signed Up?';
            document.getElementById('lnk-switch-signin').textContent = isBn ? 'এখানে সাইন ইন করুন →' : 'Sign In here →';

            // Sign In View Headings & Labels
            document.getElementById('card-heading-signin').textContent = isBn ? 'ড্যাশবোর্ডে সাইন ইন করুন' : 'Sign In to Dashboard';
            document.getElementById('card-subheading-signin').textContent = isBn ? 'আপনার ইমেইল ও পাসওয়ার্ড প্রদান করে ড্যাশবোর্ডে প্রবেশ করুন' : 'Enter your email and password to enter your dashboard';

            document.getElementById('lbl-login-email').textContent = isBn ? 'ইমেইল অথবা ইউজারনেম' : 'Email Address or Username';
            document.getElementById('lbl-login-pwd').textContent = isBn ? 'পাসওয়ার্ড' : 'Password';
            document.getElementById('txt-submit-signin').textContent = isBn ? 'ড্যাশবোর্ডে প্রবেশ করুন' : 'Sign In to Dashboard';
            document.getElementById('txt-no-account').textContent = isBn ? 'এখনও অ্যাকাউন্ট নেই?' : "Don't have an account yet?";
            document.getElementById('lnk-switch-signup').textContent = isBn ? 'প্রথমে সাইন আপ করুন →' : 'Sign Up first →';
            document.getElementById('txt-quick-demo').innerHTML = `<i data-lucide="zap" class="w-3.5 h-3.5 text-amber-500"></i><span>${isBn ? 'এক-ক্লিকে ডেমো প্রবেশ' : 'One-Click Demo Access'}</span>`;
            const demoAuth = document.getElementById('lbl-demo-auth-role');
            if (demoAuth) demoAuth.textContent = isBn ? 'সড়ক কর্তৃপক্ষ' : 'Road Authority';
            const demoCrew = document.getElementById('lbl-demo-crew-role');
            if (demoCrew) demoCrew.textContent = isBn ? 'মেরামত কর্মী (খুলনা)' : 'Crew (Khulna)';

            lucide.createIcons();
        }

        // Connect with i18n language change callback
        window.onLanguageChanged = function(lang) {
            applyLoginLanguage(lang);
        };
    </script>
</body>
</html>