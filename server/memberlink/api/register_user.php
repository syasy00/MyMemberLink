<?php

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    $response = array('status' => 'failed', 'data' => null);
    sendJsonResponse($response);
    die;
}

include_once("dbconnect.php");

// Retrieve name, email, and password from POST data
$name = $_POST['name'];
$email = $_POST['email'];
$password = sha1($_POST['password']); // Hash the password

// Check if name, email, or password is empty
if (empty($name) || empty($email) || empty($password)) {
    $response = array('status' => 'failed', 'message' => 'Name, email, and password are required.');
    sendJsonResponse($response);
    exit;
}

// Check if the email already exists in the database
$sqlcheck = "SELECT * FROM `tbl_admins` WHERE `admin_email` = '$email'";
$result = $conn->query($sqlcheck);

if ($result->num_rows > 0) {
    // Email already exists
    $response = array('status' => 'failed', 'message' => 'Email already registered.');
    sendJsonResponse($response);
    exit;
}

// If email does not exist, proceed with registration
$sqlinsert = "INSERT INTO `tbl_admins`(`admin_name`, `admin_email`, `admin_pass`) VALUES ('$name', '$email', '$password')";

if ($conn->query($sqlinsert) === TRUE) {
    $response = array('status' => 'success', 'data' => null);
} else {
    $response = array('status' => 'failed', 'message' => 'Registration failed. Please try again.');
}

sendJsonResponse($response);
$conn->close();

// Function to send a JSON response
function sendJsonResponse($response) {
    header('Content-Type: application/json');
    echo json_encode($response);
}
?>
