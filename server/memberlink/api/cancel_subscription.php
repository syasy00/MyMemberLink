<?php
include_once("dbconnect.php");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    $response = array('status' => 'failed', 'message' => 'Invalid request method');
    sendJsonResponse($response);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

// Required fields
$admin_email = $data['admin_email'] ?? null;
$subscription_id = $data['subscription_id'] ?? null;

if (!$admin_email || !$subscription_id) {
    $response = array(
        'status' => 'failed',
        'message' => 'Missing required fields'
    );
    sendJsonResponse($response);
    exit;
}

// Begin transaction
$conn->begin_transaction();

try {
    // Get admin details
    $adminSql = "SELECT admin_id FROM tbl_admins WHERE admin_email = ?";
    $adminStmt = $conn->prepare($adminSql);
    $adminStmt->bind_param("s", $admin_email);
    $adminStmt->execute();
    $adminResult = $adminStmt->get_result();
    
    if ($adminResult->num_rows === 0) {
        throw new Exception("Admin not found");
    }
    
    $adminData = $adminResult->fetch_assoc();
    $admin_id = $adminData['admin_id'];
    
    // Verify subscription belongs to admin and is active
    $subscriptionSql = "SELECT s.* 
                       FROM tbl_subscriptions s
                       LEFT JOIN tbl_membership_payment mp ON s.membership_type_id = mp.membership_type_id
                       LEFT JOIN tbl_payments p ON mp.payment_id = p.payment_id
                       WHERE s.subscription_id = ? 
                       AND s.admin_id = ?
                       AND s.subscription_status = 'active'
                       AND p.payment_status = 'completed'";
                       
    $subscriptionStmt = $conn->prepare($subscriptionSql);
    $subscriptionStmt->bind_param("ii", $subscription_id, $admin_id);
    $subscriptionStmt->execute();
    $subscriptionResult = $subscriptionStmt->get_result();
    
    if ($subscriptionResult->num_rows === 0) {
        throw new Exception("No active subscription found");
    }
    
    // Update subscription status to cancelled
    $updateSql = "UPDATE tbl_subscriptions 
                 SET subscription_status = 'cancelled',
                     updated_at = NOW(),
                     subscription_end_date = CURDATE()
                 WHERE subscription_id = ?
                 AND admin_id = ?";
                 
    $updateStmt = $conn->prepare($updateSql);
    $updateStmt->bind_param("ii", $subscription_id, $admin_id);
    
    if (!$updateStmt->execute()) {
        throw new Exception("Failed to cancel subscription");
    }
    
    // Commit transaction
    $conn->commit();
    
    $response = array(
        'status' => 'success',
        'message' => 'Subscription cancelled successfully'
    );
    
} catch (Exception $e) {
    $conn->rollback();
    $response = array(
        'status' => 'failed',
        'message' => $e->getMessage()
    );
}

// Close all statements
if (isset($adminStmt)) $adminStmt->close();
if (isset($subscriptionStmt)) $subscriptionStmt->close();
if (isset($updateStmt)) $updateStmt->close();
$conn->close();

sendJsonResponse($response);

function sendJsonResponse($response)
{
    header('Content-Type: application/json');
    echo json_encode($response);
}
?> 