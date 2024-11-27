<?php
include_once("dbconnect.php");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    $response = array('status' => 'failed', 'message' => 'Invalid request method');
    sendJsonResponse($response);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);
$news_id = $data['news_id'];
$action = $data['action']; // "like" or "unlike"

// Update likes in the database
if ($action === 'like') {
    $sql = "UPDATE `tbl_news` SET `likes` = `likes` + 1 WHERE `news_id` = ?";
} else if ($action === 'unlike') {
    $sql = "UPDATE `tbl_news` SET `likes` = `likes` - 1 WHERE `news_id` = ?";
} else {
    $response = array('status' => 'failed', 'message' => 'Invalid action');
    sendJsonResponse($response);
    exit;
}

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $news_id);
if ($stmt->execute()) {
    $response = array('status' => 'success', 'message' => 'Action successful');
} else {
    $response = array('status' => 'failed', 'message' => 'Database error');
}
$stmt->close();
$conn->close();

sendJsonResponse($response);

function sendJsonResponse($sentArray) {
    header('Content-Type: application/json');
    echo json_encode($sentArray);
}
?>
