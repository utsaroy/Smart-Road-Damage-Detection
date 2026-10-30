<?php
/**
 * SorokSurokkha - Configuration & Supabase Connection Details
 */

define('APP_NAME', 'SorokSurokkha');
define('BASE_PATH', dirname(__DIR__));
define('DATA_DIR', BASE_PATH . DIRECTORY_SEPARATOR . 'data' . DIRECTORY_SEPARATOR);
define('DB_FILE', DATA_DIR . 'potholes.sqlite');
define('UPLOAD_DIR', BASE_PATH . DIRECTORY_SEPARATOR . 'uploads' . DIRECTORY_SEPARATOR . 'potholes' . DIRECTORY_SEPARATOR);
define('UPLOAD_URL', 'uploads/potholes/');

// Supabase Cloud Backend Configuration
define('SUPABASE_URL', 'https://dytilqslhxmlhrwselam.supabase.co');
define('SUPABASE_ANON_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR5dGlscXNsaHhtbGhyd3NlbGFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5NDE5MDIsImV4cCI6MjEwODUxNzkwMn0.NHMeba85rqFXLO7UAnLqAT_j9J50Y-mwqRVpiVV59Uk');
define('SUPABASE_BUCKET', 'road-hazards');

// Ensure directories exist
if (!file_exists(DATA_DIR)) {
    mkdir(DATA_DIR, 0777, true);
}
if (!file_exists(UPLOAD_DIR)) {
    mkdir(UPLOAD_DIR, 0777, true);
}
