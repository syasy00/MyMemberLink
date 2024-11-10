<?php
include_once("dbconnect.php");

header('Content-Type: application/json');

// Check if email and password are provided
if (!isset($_POST["email"]) || !isset($_POST["password"])) {
    echo json_encode(["status" => "failed", "message" => "Email and password are required."]);
    exit;
}

$email = $_POST["email"];
$new_password = $_POST["password"];

// Hash the new password
$new_password_hash = sha1($new_password);

try {
    // Update password in the database and clear the reset code
    $update_sql = "UPDATE tbl_admins 
                    SET admin_pass = ?, reset_code_hash = NULL, reset_code_expires_at = NULL 
                    WHERE admin_email = ?";
    $update_stmt = $conn->prepare($update_sql);
    
    if (!$update_stmt) {
        throw new Exception("Failed to prepare statement.");
    }
    
    $update_stmt->bind_param("ss", $new_password_hash, $email);

    if ($update_stmt->execute()) {
        echo json_encode(["status" => "success", "message" => "Password reset successfully."]);
    } else {
        echo json_encode(["status" => "failed", "message" => "Failed to update password."]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "failed", "message" => "Database error: " . $e->getMessage()]);
    exit;
}

// Close the statement and connection
$update_stmt->close();
$conn->close();
?>
