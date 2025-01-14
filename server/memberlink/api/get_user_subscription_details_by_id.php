<?php
include_once("dbconnect.php");

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    $response = array('status' => 'failed', 'message' => 'Invalid request method');
    sendJsonResponse($response);
    exit;
}

// Get email from query parameter
$email = isset($_GET['email']) ? $_GET['email'] : null;

if (!$email) {
    $response = array('status' => 'failed', 'message' => 'Email is required');
    sendJsonResponse($response);
    exit;
}

// First query to get admin_id from email
$adminQuery = "SELECT admin_id FROM tbl_admins WHERE admin_email = ?";
$adminStmt = $conn->prepare($adminQuery);
$adminStmt->bind_param("s", $email);

if (!$adminStmt->execute()) {
    $response = array('status' => 'failed', 'message' => 'Failed to fetch admin details');
    sendJsonResponse($response);
    exit;
}

$adminResult = $adminStmt->get_result();
if ($adminResult->num_rows === 0) {
    $response = array('status' => 'failed', 'message' => 'Admin not found');
    sendJsonResponse($response);
    exit;
}

$adminRow = $adminResult->fetch_assoc();
$adminId = $adminRow['admin_id'];
$adminStmt->close();

// Query to get subscription details with membership type information
$sql = "SELECT s.*, 
               mt.membership_type_name,
               mt.membership_type_description,
               mt.membership_type_price,
               mt.membership_type_benefit,
               mt.membership_type_duration,
               mt.membership_type_terms,
               p.payment_date,
               p.payment_method,
               p.payment_status,
               p.bill_id
        FROM tbl_subscriptions s
        LEFT JOIN tbl_membership_type mt ON s.membership_type_id = mt.membership_type_id
        LEFT JOIN (
            SELECT mp.membership_type_id, p.*
            FROM tbl_membership_payment mp
            JOIN tbl_payments p ON mp.payment_id = p.payment_id
            WHERE (mp.membership_type_id, p.payment_id) IN (
                SELECT mp2.membership_type_id, MAX(p2.payment_id)
                FROM tbl_membership_payment mp2
                JOIN tbl_payments p2 ON mp2.payment_id = p2.payment_id
                GROUP BY mp2.membership_type_id
            )
        ) p ON s.membership_type_id = p.membership_type_id
        WHERE s.admin_id = ?
        ORDER BY s.created_at DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $adminId);

if ($stmt->execute()) {
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $subscriptions = array();
        
        while ($row = $result->fetch_assoc()) {
            $subscription = array(
                'subscription_id' => $row['subscription_id'],
                'membership_type_id' => $row['membership_type_id'],
                'admin_id' => $row['admin_id'],
                'subscription_start_date' => $row['subscription_start_date'],
                'subscription_end_date' => $row['subscription_end_date'],
                'subscription_status' => $row['subscription_status'],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at'],
                'membership_details' => array(
                    'name' => $row['membership_type_name'],
                    'description' => $row['membership_type_description'],
                    'price' => (float)$row['membership_type_price'],
                    'benefit' => $row['membership_type_benefit'],
                    'duration' => (int)$row['membership_type_duration'],
                    'terms' => $row['membership_type_terms']
                ),
                'payment_details' => array(
                    'payment_date' => $row['payment_date'],
                    'payment_method' => $row['payment_method'],
                    'payment_status' => $row['payment_status'],
                    'bill_id' => $row['bill_id']
                )
            );
            array_push($subscriptions, $subscription);
        }
        
        // Sort subscriptions by created_at (latest first)
        usort($subscriptions, function($a, $b) {
            return strtotime($b['created_at']) - strtotime($a['created_at']);
        });
        
        $response = array(
            'status' => 'success',
            'data' => $subscriptions
        );
    } else {
        $response = array(
            'status' => 'failed',
            'message' => 'No subscription found for this user'
        );
    }
} else {
    $response = array(
        'status' => 'failed',
        'message' => 'Database query failed'
    );
}

$stmt->close();
$conn->close();

sendJsonResponse($response);

function sendJsonResponse($response)
{
    header('Content-Type: application/json');
    echo json_encode($response);
}
?> 