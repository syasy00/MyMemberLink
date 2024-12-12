<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include_once("dbconnect.php");

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $username = $_GET['username'] ?? null;
    $useremail = $_GET['useremail'] ?? null;

    if (!$username || !$useremail) {
        $response = array("status" => "failed", "message" => "Invalid user credentials");
        sendJsonResponse($response);
        exit();
    }

    // Query to get the cart count for the user
    $sql = "SELECT COUNT(*) as cart_count FROM tbl_cart 
            WHERE username = ? AND useremail = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $username, $useremail);

    if ($stmt->execute()) {
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $cartCount = $row['cart_count'] ?? 0;

        $response = array("status" => "success", "count" => (int)$cartCount);
        sendJsonResponse($response);
    } else {
        $response = array("status" => "failed", "message" => "Database error");
        sendJsonResponse($response);
    }
} else {
    $response = array("status" => "failed", "message" => "Invalid request method");
    sendJsonResponse($response);
}

function sendJsonResponse($response)
{
    header('Content-Type: application/json');
    echo json_encode($response);
}
?>

