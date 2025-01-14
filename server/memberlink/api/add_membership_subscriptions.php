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
$amount = $data['amount'] ?? null;

// Get membership duration from tbl_membership_type
$durationSql = "SELECT membership_type_duration FROM tbl_membership_type WHERE membership_type_id = ?";
$durationStmt = $conn->prepare($durationSql);
$durationStmt->bind_param("i", $membership_type_id);
$durationStmt->execute();
$durationResult = $durationStmt->get_result();
$membershipData = $durationResult->fetch_assoc();
$duration = $membershipData['membership_type_duration'];

// Calculate subscription dates
$subscription_start_date = date('Y-m-d');
$subscription_end_date = date('Y-m-d', strtotime("+$duration months"));
$subscription_status = 'pending';

// Validate required fields
if (!$admin_email || !$membership_type_id || !$amount) {
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
$API_URL = "https://www.billplz-sandbox.com/api/v3/bills";

$amount_in_cents = $amount;

// Create Billplz Bill
$billplzData = array(
    'collection_id' => $COLLECTION_ID,
    'email' => $admin_email,
    'mobile' => null,
    'name' => $admin_name,
    'amount' => $amount_in_cents,
    'callback_url' => "https://ac7d-2001-e68-447f-e14e-4c97-23e-af82-473d.ngrok-free.app/memberlink/api/payment_callback.php",
    'description' => "Membership Subscription Payment"
);

// Debug log the request data
error_log("Billplz Request Data: " . print_r($billplzData, true));

// Initialize cURL session
$ch = curl_init($API_URL);

// Set cURL options
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($billplzData));
curl_setopt($ch, CURLOPT_USERPWD, $API_KEY . ":");
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'Content-Type: application/x-www-form-urlencoded'
));
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
curl_setopt($ch, CURLOPT_VERBOSE, true);

// Create a file handle for the verbose information
$verbose = fopen('php://temp', 'w+');
curl_setopt($ch, CURLOPT_STDERR, $verbose);

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
        // Check for active subscription
        $activeSubscriptionSql = "SELECT s.subscription_id 
                                 FROM tbl_subscriptions s
                                 LEFT JOIN tbl_membership_payment mp ON s.membership_type_id = mp.membership_type_id
                                 LEFT JOIN tbl_payments p ON mp.payment_id = p.payment_id
                                 WHERE s.admin_id = ? 
                                 AND p.payment_status = 'paid'
                                 AND s.subscription_status = 'active'
                                 AND s.subscription_end_date >= CURDATE()
                                 LIMIT 1";

        $activeStmt = $conn->prepare($activeSubscriptionSql);
        $activeStmt->bind_param("i", $admin_id);
        $activeStmt->execute();
        $activeResult = $activeStmt->get_result();

        if ($activeResult->num_rows > 0) {
            $response = array(
                'status' => 'failed',
                'message' => 'You already have an active subscription'
            );
            sendJsonResponse($response);
            exit;
        }

        // Store pending subscription
        $insertSql = "INSERT INTO tbl_subscriptions (
            admin_id,
            membership_type_id,
            subscription_start_date,
            subscription_end_date,
            subscription_status,
            created_at,
            updated_at
        ) VALUES (?, ?, ?, ?, ?, NOW(), NOW())";

        $insertStmt = $conn->prepare($insertSql);
        $insertStmt->bind_param(
            "iisss",
            $admin_id,
            $membership_type_id,
            $subscription_start_date,
            $subscription_end_date,
            $subscription_status
        );

        if ($insertStmt->execute()) {
            $subscription_id = $conn->insert_id;
            
            // Insert initial payment record with bill_id
            $paymentSql = "INSERT INTO tbl_payments (
                admin_id,
                payment_date,
                payment_method,
                payment_status,
                bill_id
            ) VALUES (?, NOW(), 'billplz', 'pending', ?)";
            
            $paymentStmt = $conn->prepare($paymentSql);
            $paymentStmt->bind_param("is", $admin_id, $billplzResponse['id']);
            $paymentStmt->execute();
            $payment_id = $conn->insert_id;
            
            // Link payment and subscription in tbl_membership_payment
            $membershipPaymentSql = "INSERT INTO tbl_membership_payment (
                membership_type_id,
                payment_id
            ) VALUES (?, ?)";
            
            $membershipPaymentStmt = $conn->prepare($membershipPaymentSql);
            $membershipPaymentStmt->bind_param("ii", $membership_type_id, $payment_id);
            $membershipPaymentStmt->execute();
            
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
if (isset($paymentStmt)) $paymentStmt->close();
if (isset($membershipPaymentStmt)) $membershipPaymentStmt->close();
$conn->close();

// After curl execution, log the verbose information
rewind($verbose);
$verboseLog = stream_get_contents($verbose);
error_log("Curl Verbose Log: " . $verboseLog);
fclose($verbose);

sendJsonResponse($response);

function sendJsonResponse($response)
{
    header('Content-Type: application/json');
    echo json_encode($response);
}
?> 