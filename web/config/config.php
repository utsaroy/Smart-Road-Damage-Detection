<?php
/**
 * AmarPath - Configuration
 */

define('APP_NAME', 'AmarPath');
define('BASE_PATH', dirname(__DIR__));
define('DATA_DIR', BASE_PATH . DIRECTORY_SEPARATOR . 'data' . DIRECTORY_SEPARATOR);
define('DB_FILE', DATA_DIR . 'potholes.sqlite');
define('UPLOAD_DIR', BASE_PATH . DIRECTORY_SEPARATOR . 'uploads' . DIRECTORY_SEPARATOR . 'potholes' . DIRECTORY_SEPARATOR);
define('UPLOAD_URL', 'uploads/potholes/');

if (!file_exists(DATA_DIR)) {
    mkdir(DATA_DIR, 0777, true);
}
if (!file_exists(UPLOAD_DIR)) {
    mkdir(UPLOAD_DIR, 0777, true);
}
