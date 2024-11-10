<?php
include_once("dbconnect.php");

header('Content-Type: application/json');

// Check if email and code are provided
if (!isset($_POST["email"]) || !isset($_POST["code"])) {
    echo json_encode(["status" => "failed", "message" => "Email and code are required."]);
    exit;
}

$email = $_POST["email"];
$code = $_POST["code"];
$hashed_code = hash("sha256", $code);  // Hash the provided code for comparison

// Prepare SQL to retrieve the stored code hash and expiry time
$sql = "SELECT reset_code_hash, reset_code_expires_at FROM tbl_admins WHERE admin_email = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $stored_code_hash = $row["reset_code_hash"];
    $expiry_time = $row["reset_code_expires_at"];

    // Check if the hashed code matches and if the code has not expired
    if ($hashed_code === $stored_code_hash && strtotime($expiry_time) > time()) {
        // Code is valid
        echo json_encode(["status" => "success", "message" => "Code verified successfully."]);
    } else {
        // Invalid or expired code
        echo json_encode(["status" => "failed", "message" => "Invalid or expired code."]);
    }
} else {
    echo json_encode(["status" => "failed", "message" => "Email not found."]);
}

$stmt->close();
$conn->close();
?>
