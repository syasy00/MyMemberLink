<?php
include_once("dbconnect.php");

header('Content-Type: application/json');

// Check if email is provided
if (!isset($_POST["email"])) {
    echo json_encode(["status" => "failed", "message" => "Email is required."]);
    exit;
}

$email = $_POST["email"];
$verification_code = random_int(1000, 9999);  // Generate a 4-digit verification code
$code_hash = hash("sha256", $verification_code);  // Hash the code for secure storage
$expiry = date("Y-m-d H:i:s", time() + 60 * 10);  // Code is valid for 10 minutes

// Update the user's record with the verification code and expiry time
$sql = "UPDATE tbl_admins SET reset_code_hash = ?, reset_code_expires_at = ? WHERE admin_email = ?";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode(["status" => "failed", "message" => "Database error: unable to prepare statement."]);
    exit;
}

$stmt->bind_param("sss", $code_hash, $expiry, $email);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    // Load the mailer and configure email
    $mail = require __DIR__ . "/mailer.php";
    $mail->setFrom("noreply@mymemberlink.my", "MyMemberLink Support");
    $mail->addAddress($email);
    $mail->Subject = "Password Reset Verification Code";
    $mail->isHTML(true);  // Set email format to HTML

    // HTML email body
    $mail->Body = <<<END
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password Reset Verification Code</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f7;
            color: #51545e;
            margin: 0;
            padding: 0;
        }
        .email-container {
            max-width: 600px;
            margin: 20px auto;
            background-color: #ffffff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        h1 {
            color: #333333;
            font-size: 24px;
            margin-bottom: 20px;
        }
        p {
            font-size: 16px;
            line-height: 1.6;
            color: #51545e;
        }
        .code {
            font-size: 28px;
            font-weight: bold;
            color: #0073e6;
        }
        .footer {
            margin-top: 30px;
            font-size: 12px;
            color: #a8a8a8;
        }
        .footer a {
            color: #0073e6;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <h1>Password Reset Verification Code</h1>
        <p>Hello,</p>
        <p>We received a request to reset your password for your account. Use the following code to verify your identity and reset your password:</p>
        <p class="code">$verification_code</p>
        <p>If you didn't request this password reset, please ignore this email or contact support if you have any concerns.</p>
        <p>Thank you,<br>The MyMemberLink Team</p>
        <div class="footer">
            <p>If you have any questions, reach us at <a href="mailto:support@mymemberlink.my">support@mymemberlink.my</a>.</p>
        </div>
    </div>
</body>
</html>
END;

    // Attempt to send the email and handle errors
    try {
        $mail->send();
        echo json_encode(["status" => "success", "message" => "Verification code sent. Please check your inbox."]);
    } catch (Exception $e) {
        echo json_encode(["status" => "failed", "message" => "Mailer error: {$mail->ErrorInfo}"]);
    }
} else {
    echo json_encode(["status" => "failed", "message" => "No account found with that email address."]);
}
