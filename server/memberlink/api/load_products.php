<?php
header("Content-Type: application/json");
require 'dbconnect.php'; // Ensure this file sets up your database connection

// Get the current page from the query string, default to 1
$page = isset($_GET['page']) && (int)$_GET['page'] > 0 ? (int)$_GET['page'] : 1;

// Allow a custom limit per page (optional), default to 6
$limit = isset($_GET['limit']) && (int)$_GET['limit'] > 0 ? (int)$_GET['limit'] : 6;

// Get the category filter if provided
$category = isset($_GET['category']) ? $conn->real_escape_string($_GET['category']) : '';

// Calculate the offset for SQL query
$offset = ($page - 1) * $limit;

// Add category filter to the WHERE clause if provided
$whereClause = !empty($category) ? "WHERE category = '$category'" : '';

// Query to fetch products for the current page
$sql = "SELECT * FROM tbl_products $whereClause LIMIT $limit OFFSET $offset";
$result = $conn->query($sql);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database query failed: " . $conn->error
    ]);
    exit;
}

// Query to calculate the total number of products with the filter
$total_query = "SELECT COUNT(*) as total FROM tbl_products $whereClause";
$total_result = $conn->query($total_query);

if (!$total_result) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Failed to count total products: " . $conn->error
    ]);
    exit;
}

// Calculate total pages
$total = $total_result->fetch_assoc()['total'];
$total_pages = ceil($total / $limit);

// Fetch the data for the current page
$data = [];
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
}

// Send JSON response
echo json_encode([
    "status" => "success",
    "data" => $data,
    "total_pages" => $total_pages,
    "current_page" => $page,
    "limit" => $limit
]);
?>
