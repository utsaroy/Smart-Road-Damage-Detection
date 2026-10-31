<?php
require_once __DIR__ . '/../config/database.php';

try {
    $db = Database::getConnection();

    // 1. Create users table
    $db->exec("
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'crew',
            division TEXT,
            district TEXT,
            upazilla TEXT,
            phone TEXT,
            team_name TEXT,
            status TEXT NOT NULL DEFAULT 'active',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    ");
    echo "Users table created or verified successfully.\n";

    // 2. Add extra columns to pothole_reports if needed
    $extra_cols = [
        "assigned_crew_id TEXT",
        "assigned_at DATETIME",
        "repair_completed_at DATETIME"
    ];
    foreach ($extra_cols as $c) {
        try { $db->exec("ALTER TABLE pothole_reports ADD COLUMN {$c}"); } catch (Throwable $e) {}
    }

    // Fix any remaining 'Location unavailable' road_name
    $db->exec("UPDATE pothole_reports SET road_name = 'Gulshan Avenue, Gulshan' WHERE upazilla = 'Gulshan' AND (road_name = 'Location unavailable' OR road_name IS NULL)");

    // 3. Seed demo users
    $users = [
        [
            'id' => 'USR-AUTH-001',
            'name' => 'Munem Shahriar',
            'email' => 'authority@amarpath.gov.bd',
            'password' => 'admin123',
            'role' => 'authority',
            'division' => 'Dhaka',
            'district' => 'Dhaka',
            'upazilla' => 'National HQ',
            'phone' => '+880 1711-000111',
            'team_name' => 'Roads & Highways Department (RHD)'
        ],
        [
            'id' => 'USR-CREW-001',
            'name' => 'Engr. Rafiqul Islam',
            'email' => 'crew.khulna@amarpath.gov.bd',
            'password' => 'crew123',
            'role' => 'crew',
            'division' => 'Khulna',
            'district' => 'Khulna',
            'upazilla' => 'Khan Jahan Ali',
            'phone' => '+880 1712-345678',
            'team_name' => 'Khulna Highway Maintenance Unit - Alpha'
        ],
        [
            'id' => 'USR-CREW-002',
            'name' => 'Kabir Hossain',
            'email' => 'kabir.khulna@amarpath.gov.bd',
            'password' => 'crew123',
            'role' => 'crew',
            'division' => 'Khulna',
            'district' => 'Khulna',
            'upazilla' => 'Khan Jahan Ali',
            'phone' => '+880 1819-876543',
            'team_name' => 'Rapid Pavement Repair Crew B'
        ],
        [
            'id' => 'USR-CREW-003',
            'name' => 'Tanvir Ahmed',
            'email' => 'crew.dhaka@amarpath.gov.bd',
            'password' => 'crew123',
            'role' => 'crew',
            'division' => 'Dhaka',
            'district' => 'Dhaka',
            'upazilla' => 'Gulshan',
            'phone' => '+880 1911-223344',
            'team_name' => 'Dhaka North City Rapid Patching Team'
        ],
        [
            'id' => 'USR-CREW-004',
            'name' => 'Abdur Rahim',
            'email' => 'rahim.khulna@amarpath.gov.bd',
            'password' => 'crew123',
            'role' => 'crew',
            'division' => 'Khulna',
            'district' => 'Khulna',
            'upazilla' => 'Khan Jahan Ali',
            'phone' => '+880 1610-998877',
            'team_name' => 'Emergency Road Patch Crew C'
        ]
    ];

    $stmt = $db->prepare("
        INSERT INTO users (id, name, email, password_hash, role, division, district, upazilla, phone, team_name)
        VALUES (:id, :name, :email, :password_hash, :role, :division, :district, :upazilla, :phone, :team_name)
        ON CONFLICT(email) DO UPDATE SET
            name = excluded.name,
            password_hash = excluded.password_hash,
            role = excluded.role,
            division = excluded.division,
            district = excluded.district,
            upazilla = excluded.upazilla,
            phone = excluded.phone,
            team_name = excluded.team_name
    ");

    foreach ($users as $u) {
        $stmt->execute([
            ':id' => $u['id'],
            ':name' => $u['name'],
            ':email' => $u['email'],
            ':password_hash' => password_hash($u['password'], PASSWORD_DEFAULT),
            ':role' => $u['role'],
            ':division' => $u['division'],
            ':district' => $u['district'],
            ':upazilla' => $u['upazilla'],
            ':phone' => $u['phone'],
            ':team_name' => $u['team_name']
        ]);
        echo "Seeded/Updated user: {$u['name']} ({$u['email']}) [{$u['role']}] - {$u['upazilla']}\n";
    }

    // 4. Seed initial realistic assignments
    $db->exec("
        UPDATE pothole_reports 
        SET assigned_crew = 'Engr. Rafiqul Islam (Team Alpha)',
            assigned_crew_id = 'USR-CREW-001',
            status = 'under_repair',
            scheduled_repair_date = '2026-10-31',
            repair_notes = 'Cold asphalt emulsion and roller compaction underway on westbound lane.',
            assigned_at = '2026-10-30 14:00:00'
        WHERE id = 'RPT-1793085821675'
    ");

    $db->exec("
        UPDATE pothole_reports 
        SET assigned_crew = 'Kabir Hossain (Crew B)',
            assigned_crew_id = 'USR-CREW-002',
            status = 'assigned',
            scheduled_repair_date = '2026-11-01',
            repair_notes = 'Scheduled for surface aggregate leveling and bitumen seal.',
            assigned_at = '2026-10-30 15:30:00'
        WHERE id = 'RPT-1793082968792'
    ");

    $db->exec("
        UPDATE pothole_reports 
        SET assigned_crew = 'Engr. Rafiqul Islam (Team Alpha)',
            assigned_crew_id = 'USR-CREW-001',
            status = 'resolved',
            repair_notes = 'Road patch complete. 50mm compacted asphalt installed and traffic restored.',
            repair_completed_at = '2026-10-29 17:00:00'
        WHERE id = 'RPT-1792958275288'
    ");

    echo "Sample repair assignments initialized.\n";

} catch (Throwable $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
