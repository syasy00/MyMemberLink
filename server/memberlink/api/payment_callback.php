<?php
include_once("dbconnect.php");

// Get the POST data from Billplz
$data = $_POST;

// Begin transaction
$conn->begin_transaction();

try {
    $bill_id = $data['id'];
    $paid_status = $data['paid'] === 'true' ? 'completed' : 'failed';
    
    // First, get payment details
    $paymentSql = "SELECT admin_id FROM tbl_payments WHERE bill_id = ?";
    $paymentStmt = $conn->prepare($paymentSql);
    $paymentStmt->bind_param("s", $bill_id);
    $paymentStmt->execute();
    $result = $paymentStmt->get_result();
    
    if ($result->num_rows > 0) {
        $payment = $result->fetch_assoc();
        $admin_id = $payment['admin_id'];
        
        // Update payment status
        $updatePaymentSql = "UPDATE tbl_payments 
                            SET payment_status = ?,
                                payment_date = NOW()
                            WHERE bill_id = ? AND payment_status = 'pending'";
        
        $updatePaymentStmt = $conn->prepare($updatePaymentSql);
        $updatePaymentStmt->bind_param("ss", $paid_status, $bill_id);
        $updatePaymentStmt->execute();
        
        // Update subscription status
        $subscription_status = $paid_status === 'completed' ? 'active' : 'failed';
        $updateSubscriptionSql = "UPDATE tbl_subscriptions 
                                SET subscription_status = ?,
                                    updated_at = NOW()
                                WHERE admin_id = ? 
                                AND subscription_status = 'pending'
                                ORDER BY created_at DESC
                                LIMIT 1";
        
        $updateSubscriptionStmt = $conn->prepare($updateSubscriptionSql);
        $updateSubscriptionStmt->bind_param("si", $subscription_status, $admin_id);
        $updateSubscriptionStmt->execute();
        
        // If everything is successful, commit the transaction
        $conn->commit();
        http_response_code(200);
    } else {
        throw new Exception("Payment record not found");
    }
} catch (Exception $e) {
    // Rollback the transaction if any error occurs
    $conn->rollback();
    error_log("Payment callback error: " . $e->getMessage());
    http_response_code(400);
}

// Close all statements
if (isset($paymentStmt)) $paymentStmt->close();
if (isset($updatePaymentStmt)) $updatePaymentStmt->close();
if (isset($updateSubscriptionStmt)) $updateSubscriptionStmt->close();
$conn->close();
?> 