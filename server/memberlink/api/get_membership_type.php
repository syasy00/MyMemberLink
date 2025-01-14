<?php
include_once("dbconnect.php");

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    $response = array('status' => 'failed', 'message' => 'Invalid request method');
    sendJsonResponse($response);
    exit;
}

// Get membership type ID from query parameter if provided
$membershipTypeId = isset($_GET['id']) ? $_GET['id'] : null;

if ($membershipTypeId) {
    // Query for specific membership type
    $sql = "SELECT * FROM tbl_membership_type WHERE membership_type_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $membershipTypeId);
} else {
    // Query for all membership types
    $sql = "SELECT * FROM tbl_membership_type";
    $stmt = $conn->prepare($sql);
}

if ($stmt->execute()) {
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $membershipTypes = array();
        
        while ($row = $result->fetch_assoc()) {
            $membershipType = array(
                'membership_type_id' => $row['membership_type_id'],
                'membership_type_name' => $row['membership_type_name'],
                'membership_type_description' => $row['membership_type_description'],
                'membership_type_price' => (float)$row['membership_type_price'],
                'membership_type_benefit' => $row['membership_type_benefit'],
                'membership_type_duration' => (int)$row['membership_type_duration'],
                'membership_type_terms' => $row['membership_type_terms']
            );
            array_push($membershipTypes, $membershipType);
        }
        
        $response = array(
            'status' => 'success',
            'data' => $membershipTypeId ? $membershipTypes[0] : $membershipTypes
        );
    } else {
        $response = array(
            'status' => 'failed',
            'message' => 'No membership types found'
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