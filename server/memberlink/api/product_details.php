<?php
header("Content-Type: application/json");
require 'dbconnect.php';

$product_id = isset($_GET['product_id']) ? (int)$_GET['product_id'] : 0;

if ($product_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Invalid product ID"]);
    exit;
}

$sql = "SELECT * FROM tbl_products WHERE id = $product_id";
$result = $conn->query($sql);

if (!$result) {
    echo json_encode(["status" => "error", "message" => $conn->error]);
    exit;
}

if ($result->num_rows > 0) {
    $product = $result->fetch_assoc();
    $stock_status = (int)$product['quantity'] > 0 ? "In Stock" : "Out of Stock";

    echo json_encode([
        "status" => "success",
        "data" => [
            "id" => (int)$product['id'],
            "name" => $product['name'],
            "image_url" => $product['image_url'],
            "description" => $product['description'],
            "price" => (float)$product['price'],
            "quantity" => (int)$product['quantity'],
            "category" => $product['category'],
            "stock_status" => $stock_status,
        ]
    ]);
} else {
    echo json_encode(["status" => "error", "message" => "Product not found"]);
}
?>
