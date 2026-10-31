<?php
/**
 * Authentication and Session Management Helper
 * Supports Dual Roles: 'authority' (Road Authority) and 'crew' (Construction Crew)
 */

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php';

class Auth {

    /**
     * Get currently authenticated user data
     */
    public static function user(): ?array {
        return $_SESSION['user'] ?? null;
    }

    /**
     * Check if user is logged in
     */
    public static function check(): bool {
        return !empty($_SESSION['user']['id']);
    }

    /**
     * Get current user role: 'authority' | 'crew' | null
     */
    public static function role(): ?string {
        return $_SESSION['user']['role'] ?? null;
    }

    /**
     * Check if current user is an authority admin
     */
    public static function isAuthority(): bool {
        return self::role() === 'authority';
    }

    /**
     * Check if current user is a construction crew
     */
    public static function isCrew(): bool {
        return self::role() === 'crew';
    }

    /**
     * Log user into session
     */
    public static function login(array $user): void {
        unset($user['password_hash']);
        $_SESSION['user'] = $user;
    }

    /**
     * Log out current user
     */
    public static function logout(): void {
        $_SESSION['user'] = null;
        unset($_SESSION['user']);
        session_destroy();
    }

    /**
     * Require login, redirecting to login.php if not authenticated.
     * Optionally restrict to a specific role.
     */
    public static function requireLogin(?string $requiredRole = null): array {
        if (!self::check()) {
            header("Location: login.php");
            exit;
        }

        $user = self::user();

        if ($requiredRole !== null && $user['role'] !== $requiredRole) {
            // Redirect to appropriate dashboard based on actual role
            if ($user['role'] === 'crew') {
                header("Location: crew_dashboard.php");
                exit;
            } else if ($user['role'] === 'authority') {
                header("Location: index.php");
                exit;
            }
        }

        return $user;
    }
}
