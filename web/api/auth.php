<?php
/**
 * REST API: Authentication (Login, Register, Logout, Profile)
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once __DIR__ . '/../includes/auth.php';

$action = $_GET['action'] ?? $_POST['action'] ?? 'login';

try {
    $db = Database::getConnection();

    if ($action === 'login') {
        $email = trim($_POST['email'] ?? '');
        $password = trim($_POST['password'] ?? '');

        if (empty($email) || empty($password)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Email/Username and Password are required.']);
            exit;
        }

        $stmt = $db->prepare("SELECT * FROM users WHERE (email = :email OR id = :email) AND status = 'active' LIMIT 1");
        $stmt->execute([':email' => $email]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($password, $user['password_hash'])) {
            http_response_code(401);
            echo json_encode(['success' => false, 'error' => 'Invalid email or password.']);
            exit;
        }

        Auth::login($user);

        $redirect = ($user['role'] === 'crew') ? 'crew_dashboard.php' : 'index.php';

        echo json_encode([
            'success' => true,
            'message' => 'Login successful',
            'user' => [
                'id' => $user['id'],
                'name' => $user['name'],
                'email' => $user['email'],
                'role' => $user['role'],
                'division' => $user['division'],
                'district' => $user['district'],
                'upazilla' => $user['upazilla'],
                'team_name' => $user['team_name']
            ],
            'redirect' => $redirect
        ]);
        exit;
    }

    if ($action === 'register') {
        $name = trim($_POST['name'] ?? '');
        $email = trim($_POST['email'] ?? '');
        $password = trim($_POST['password'] ?? '');
        $role = trim($_POST['role'] ?? 'crew');
        $phone = trim($_POST['phone'] ?? '');
        $division = trim($_POST['division'] ?? '');
        $district = trim($_POST['district'] ?? '');
        $upazilla = trim($_POST['upazilla'] ?? '');
        $team_name = trim($_POST['team_name'] ?? '');

        if (empty($name) || empty($email) || empty($password)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Name, email and password are required.']);
            exit;
        }

        if (!in_array($role, ['authority', 'crew'])) {
            $role = 'crew';
        }

        if ($role === 'crew' && (empty($upazilla) || empty($district))) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Construction crews must select their assigned Upazilla and District.']);
            exit;
        }

        // Check if email already taken
        $check = $db->prepare("SELECT id FROM users WHERE email = :email");
        $check->execute([':email' => $email]);
        if ($check->fetch()) {
            http_response_code(409);
            echo json_encode(['success' => false, 'error' => 'An account with this email address already exists.']);
            exit;
        }

        $id = ($role === 'authority') ? 'USR-AUTH-' . strtoupper(substr(uniqid(), -6)) : 'USR-CREW-' . strtoupper(substr(uniqid(), -6));
        $hash = password_hash($password, PASSWORD_DEFAULT);

        if (empty($team_name)) {
            $team_name = ($role === 'crew') ? "{$upazilla} Road Repair Unit" : "Roads & Highways Department";
        }

        $stmt = $db->prepare("
            INSERT INTO users (id, name, email, password_hash, role, division, district, upazilla, phone, team_name)
            VALUES (:id, :name, :email, :password_hash, :role, :division, :district, :upazilla, :phone, :team_name)
        ");
        $stmt->execute([
            ':id' => $id,
            ':name' => $name,
            ':email' => $email,
            ':password_hash' => $hash,
            ':role' => $role,
            ':division' => $division,
            ':district' => $district,
            ':upazilla' => $upazilla,
            ':phone' => $phone,
            ':team_name' => $team_name
        ]);

        $newUser = [
            'id' => $id,
            'name' => $name,
            'email' => $email,
            'role' => $role,
            'division' => $division,
            'district' => $district,
            'upazilla' => $upazilla,
            'phone' => $phone,
            'team_name' => $team_name
        ];

        // Sync user signup info directly to Supabase Cloud Database & Auth
        try {
            $supaPayload = [
                'email' => $email,
                'password' => $password,
                'data' => [
                    'full_name' => $name,
                    'role' => $role,
                    'phone' => $phone,
                    'team_name' => $team_name,
                    'division' => $division,
                    'district' => $district,
                    'upazilla' => $upazilla
                ]
            ];

            $ch = curl_init(SUPABASE_URL . '/auth/v1/signup');
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($supaPayload));
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 4);
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'apikey: ' . SUPABASE_ANON_KEY,
                'Authorization: Bearer ' . SUPABASE_ANON_KEY,
                'Content-Type: application/json'
            ]);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            $supaRes = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode >= 200 && $httpCode < 300 && !empty($supaRes)) {
                $supaData = json_decode($supaRes, true);
                $supaUid = $supaData['user']['id'] ?? null;
                if ($supaUid) {
                    // Update role in profiles table in Supabase
                    $ch2 = curl_init(SUPABASE_URL . '/rest/v1/profiles?id=eq.' . urlencode($supaUid));
                    curl_setopt($ch2, CURLOPT_CUSTOMREQUEST, 'PATCH');
                    curl_setopt($ch2, CURLOPT_POSTFIELDS, json_encode(['role' => $role, 'full_name' => $name]));
                    curl_setopt($ch2, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch2, CURLOPT_TIMEOUT, 3);
                    curl_setopt($ch2, CURLOPT_HTTPHEADER, [
                        'apikey: ' . SUPABASE_ANON_KEY,
                        'Authorization: Bearer ' . SUPABASE_ANON_KEY,
                        'Content-Type: application/json'
                    ]);
                    curl_setopt($ch2, CURLOPT_SSL_VERIFYPEER, false);
                    curl_exec($ch2);
                    curl_close($ch2);
                }
            }
        } catch (Throwable $st) {
            // Log warning but allow registration to complete smoothly
            error_log('Supabase signup sync notice: ' . $st->getMessage());
        }

        Auth::login($newUser);

        $redirect = ($role === 'crew') ? 'crew_dashboard.php' : 'index.php';

        echo json_encode([
            'success' => true,
            'message' => 'Registration successful! Welcome to SorokSurokkha.',
            'user' => $newUser,
            'redirect' => $redirect
        ]);
        exit;
    }

    if ($action === 'logout') {
        Auth::logout();
        echo json_encode(['success' => true, 'redirect' => 'login.php']);
        exit;
    }

    if ($action === 'me') {
        if (Auth::check()) {
            echo json_encode(['success' => true, 'logged_in' => true, 'user' => Auth::user()]);
        } else {
            echo json_encode(['success' => true, 'logged_in' => false]);
        }
        exit;
    }

    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Unknown action.']);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
