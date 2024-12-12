<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include_once("dbconnect.php");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true);
    $username = $input['username'] ?? null;
    $useremail = $input['useremail'] ?? null;
    $product_id = $input['product_id'] ?? null;
    $quantity = $input['quantity'] ?? 1;

    if (!$username || !$useremail || !$product_id) {
        $response = array("status" => "failed", "message" => "Invalid input parameters");
        sendJsonResponse($response);
        exit();
    }

    // Check if sufficient stock is available
    if (!checkStockAvailability($conn, $product_id, $quantity)) {
        $response = array("status" => "failed", "message" => "Insufficient stock");
        sendJsonResponse($response);
        exit();
    }

    // Check if the product already exists in the user's cart
    $sqlCheck = "SELECT * FROM tbl_cart WHERE username = ? AND useremail = ? AND product_id = ?";
    $stmtCheck = $conn->prepare($sqlCheck);
    $stmtCheck->bind_param("ssi", $username, $useremail, $product_id);

    if ($stmtCheck->execute()) {
        $result = $stmtCheck->get_result();

        if ($result->num_rows > 0) {
            // Update quantity if the product exists
            $sqlUpdate = "UPDATE tbl_cart SET quantity = quantity + ? WHERE username = ? AND useremail = ? AND product_id = ?";
            $stmtUpdate = $conn->prepare($sqlUpdate);
            $stmtUpdate->bind_param("issi", $quantity, $username, $useremail, $product_id);

            if ($stmtUpdate->execute()) {
                // Decrease product quantity in stock
                if (decreaseProductStock($conn, $product_id, $quantity)) {
                    $response = array("status" => "success", "message" => "Cart updated successfully");
                } else {
                    $response = array("status" => "failed", "message" => "Failed to update product stock");
                }
            } else {
                $response = array("status" => "failed", "message" => "Failed to update cart");
            }
        } else {
            // Insert new product into the cart
            $sqlInsert = "INSERT INTO tbl_cart (username, useremail, product_id, quantity) VALUES (?, ?, ?, ?)";
            $stmtInsert = $conn->prepare($sqlInsert);
            $stmtInsert->bind_param("ssii", $username, $useremail, $product_id, $quantity);

            if ($stmtInsert->execute()) {
                // Decrease product quantity in stock
                if (decreaseProductStock($conn, $product_id, $quantity)) {
                    $response = array("status" => "success", "message" => "Product added to cart successfully");
                } else {
                    $response = array("status" => "failed", "message" => "Failed to update product stock");
                }
            } else {
                $response = array("status" => "failed", "message" => "Failed to add product to cart");
            }
        }
    } else {
        $response = array("status" => "failed", "message" => "Database error");
    }

    sendJsonResponse($response);
} else {
    $response = array("status" => "failed", "message" => "Invalid request method");
    sendJsonResponse($response);
}

function checkStockAvailability($conn, $product_id, $quantity) {
    $sql = "SELECT quantity FROM tbl_products WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $product_id);

    if ($stmt->execute()) {
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        if ($row && $row['quantity'] >= $quantity) {
            return true;
        }
    }
    return false;
}

function decreaseProductStock($conn, $product_id, $quantity) {
    $sql = "UPDATE tbl_products SET quantity = quantity - ? WHERE id = ? AND quantity >= ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iii", $quantity, $product_id, $quantity);

    if ($stmt->execute()) {
        return true;
    } else {
        error_log("Failed to update product stock: " . $stmt->error);
        return false;
    }
}

function sendJsonResponse($response) {
    header('Content-Type: application/json');
    echo json_encode($response);
}
?>
