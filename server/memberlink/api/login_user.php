<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

if (!isset($_POST)) {
    $response = array('status' => 'failed', 'data' => null);
    sendJsonResponse($response);
    die;
}

include_once("dbconnect.php");

$email = $_POST['email'];
$password = sha1($_POST['password']);

$sqllogin = "SELECT `admin_name`, `admin_email` FROM `tbl_admins` WHERE `admin_email` = '$email' AND `admin_pass` = '$password'";
$result = $conn->query($sqllogin);

if ($result->num_rows > 0) {
    // Fetch the user details
    $row = $result->fetch_assoc();
    $response = array(
        'status' => 'success',
        'username' => $row['admin_name'], // Add the user's name
        'email' => $row['admin_email']  // Optionally, include the email
    );
    sendJsonResponse($response);
} else {
    $response = array('status' => 'failed', 'data' => null);
    sendJsonResponse($response);
}

function sendJsonResponse($sentArray)
{
    header('Content-Type: application/json');
    echo json_encode($sentArray);
}
?>

