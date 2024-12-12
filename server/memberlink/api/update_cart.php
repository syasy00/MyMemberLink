<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include_once("dbconnect.php");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user_id = $_POST['user_id'];
    $product_id = $_POST['product_id'];
    $quantity = $_POST['quantity'];

    if (empty($user_id) || empty($product_id) || empty($quantity)) {
        sendJsonResponse(['status' => 'failed', 'message' => 'All fields are required']);
        exit;
    }

    $sql = "UPDATE `tbl_cart` SET `quantity` = ? WHERE `user_id` = ? AND `product_id` = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iii", $quantity, $user_id, $product_id);

    if ($stmt->execute()) {
        sendJsonResponse(['status' => 'success', 'message' => 'Cart updated successfully']);
    } else {
        sendJsonResponse(['status' => 'failed', 'message' => 'Failed to update cart']);
    }

    $stmt->close();
    $conn->close();
} else {
    sendJsonResponse(['status' => 'failed', 'message' => 'Invalid request method']);
    exit;
}

function sendJsonResponse($response) {
    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}
?>

