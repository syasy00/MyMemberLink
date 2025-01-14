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
$membership_type_id = $data['membership_type_id'] ?? null;
$subscription_start_date = $data['subscription_start_date'] ?? null;
$subscription_end_date = $data['subscription_end_date'] ?? null;
$subscription_status = $data['subscription_status'] ?? 'pending';
$amount = $data['amount'] ?? null;

// Validate required fields
if (!$admin_email || !$membership_type_id || !$amount || 
    !$subscription_start_date || !$subscription_end_date) {
    $response = array(
        'status' => 'failed',
        'message' => 'Missing required fields'
    );
    sendJsonResponse($response);
    exit;
}

// Get admin details from database
$adminSql = "SELECT admin_id, admin_name FROM tbl_admins WHERE admin_email = ?";
$adminStmt = $conn->prepare($adminSql);
$adminStmt->bind_param("s", $admin_email);
$adminStmt->execute();
$adminResult = $adminStmt->get_result();

if ($adminResult->num_rows === 0) {
    $response = array(
        'status' => 'failed',
        'message' => 'Admin not found'
    );
    sendJsonResponse($response);
    exit;
}

$adminData = $adminResult->fetch_assoc();
$admin_id = $adminData['admin_id'];
$admin_name = $adminData['admin_name'];

// Billplz API Configuration
$API_KEY = "b77b27ce-148a-419b-88f1-2c893cb2a84d";
$COLLECTION_ID = "3ruetpf7";
$API_URL = "https://www.billplz.com/api/v3/bills";

// Convert amount to cents (multiply by 100)
$amount_in_cents = $amount * 100;

// Create Billplz Bill
$billplzData = array(
    'collection_id' => $COLLECTION_ID,
    'email' => $admin_email,
    'name' => $admin_name,
    'amount' => $amount_in_cents,
    'callback_url' => "https://mymemberlink.com/api/payment_callback.php",
    'description' => "Membership Subscription Payment"
);

// Initialize cURL session
$ch = curl_init($API_URL);

// Set cURL options to match the documentation example
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($billplzData));
curl_setopt($ch, CURLOPT_USERPWD, $API_KEY . ":");
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'Content-Type: application/x-www-form-urlencoded'
));

// Execute cURL session
$result = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlInfo = curl_getinfo($ch);

// Get any cURL errors
$curlError = curl_error($ch);
curl_close($ch);

// Check if there was a cURL error
if ($curlError) {
    $response = array(
        'status' => 'failed',
        'message' => 'Connection error: ' . $curlError,
        'debug_info' => array(
            'curl_error' => $curlError,
            'http_code' => $httpCode,
            'curl_info' => $curlInfo,
            'raw_response' => $result
        )
    );
    sendJsonResponse($response);
    exit;
}

// Check if the API call was successful
if ($httpCode == 200) {
    $billplzResponse = json_decode($result, true);
    
    // Check if JSON decode was successful
    if (json_last_error() !== JSON_ERROR_NONE) {
        $response = array(
            'status' => 'failed',
            'message' => 'Invalid response from payment gateway',
            'debug_info' => array(
                'json_error' => json_last_error_msg(),
                'raw_response' => $result
            )
        );
        sendJsonResponse($response);
        exit;
    }
    
    // Begin transaction to store pending subscription
    $conn->begin_transaction();

    try {
        // Store pending subscription with bill_id
        $insertSql = "INSERT INTO tbl_subscriptions (
            admin_id,
            membership_type_id,
            subscription_start_date,
            subscription_end_date,
            subscription_status,
            bill_id
        ) VALUES (?, ?, ?, ?, ?, ?)";

        $insertStmt = $conn->prepare($insertSql);
        $insertStmt->bind_param(
            "iissss",
            $admin_id,
            $membership_type_id,
            $subscription_start_date,
            $subscription_end_date,
            $subscription_status,
            $billplzResponse['id']
        );

        if ($insertStmt->execute()) {
            $subscription_id = $conn->insert_id;
            $conn->commit();
            
            $response = array(
                'status' => 'success',
                'message' => 'Payment bill created successfully',
                'data' => array(
                    'subscription_id' => $subscription_id,
                    'bill_id' => $billplzResponse['id'],
                    'payment_url' => $billplzResponse['url'],
                    'admin_id' => $admin_id,
                    'admin_name' => $admin_name
                )
            );
        } else {
            throw new Exception("Failed to create pending subscription");
        }
    } catch (Exception $e) {
        $conn->rollback();
        $response = array(
            'status' => 'failed',
            'message' => 'Error creating subscription: ' . $e->getMessage(),
            'debug_info' => array(
                'error_type' => get_class($e),
                'error_line' => $e->getLine()
            )
        );
    }
} else {
    // Decode error response from Billplz if available
    $errorResponse = json_decode($result, true);
    $errorMessage = $errorResponse['error']['message'] ?? 'Unknown error';
    
    $response = array(
        'status' => 'failed',
        'message' => 'Payment gateway error: ' . $errorMessage,
        'debug_info' => array(
            'http_code' => $httpCode,
            'billplz_response' => $errorResponse ?? $result,
            'curl_info' => $curlInfo,
            'raw_response' => $result,
            'request_data' => array(
                'amount' => $amount,
                'email' => $admin_email,
                'name' => $admin_name
            )
        )
    );
}

// Close all statements
if (isset($adminStmt)) $adminStmt->close();
if (isset($insertStmt)) $insertStmt->close();
$conn->close();

sendJsonResponse($response);

function sendJsonResponse($response)
{
    header('Content-Type: application/json');
    echo json_encode($response);
}
?> 