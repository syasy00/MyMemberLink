<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include_once("dbconnect.php");

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Retrieve username and useremail from GET parameters
    $username = $_GET['username'] ?? null;
    $useremail = $_GET['useremail'] ?? null;

    if (!$username || !$useremail) {
        // Return an error if username or useremail is missing
        $response = array("status" => "failed", "message" => "Invalid user credentials");
        sendJsonResponse($response);
        exit();
    }

    // Fetch cart items for the user
    $sql = "SELECT c.product_id, c.quantity, p.name, 
                   CAST(p.price AS DECIMAL(10, 2)) AS price, 
                   p.image_url 
            FROM tbl_cart c
            JOIN tbl_products p ON c.product_id = p.id
            WHERE c.username = ? AND c.useremail = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $username, $useremail);

    if ($stmt->execute()) {
        $result = $stmt->get_result();
        $items = [];
        while ($row = $result->fetch_assoc()) {
            $items[] = $row;
        }

        $response = array("status" => "success", "data" => $items);
        sendJsonResponse($response);
    } else {
        // Handle SQL execution error
        $response = array("status" => "failed", "message" => "Database error");
        sendJsonResponse($response);
    }
} else {
    // Invalid request method
    $response = array("status" => "failed", "message" => "Invalid request method");
    sendJsonResponse($response);
}

// Helper function to send JSON responses
function sendJsonResponse($response)
{
    header('Content-Type: application/json');
    echo json_encode($response);
}
?>
