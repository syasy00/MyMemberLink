<?php
include_once("dbconnect.php");

$query = isset($_GET['query']) ? $conn->real_escape_string($_GET['query']) : '';

$sqlloadnews = "SELECT * FROM tbl_news 
                WHERE news_title LIKE '%$query%' 
                OR news_details LIKE '%$query%' 
                ORDER BY news_date DESC";

$result = $conn->query($sqlloadnews);

if ($result->num_rows > 0) {
    $newsarray = ['news' => []];
    while ($row = $result->fetch_assoc()) {
        $newsarray['news'][] = [
            'news_id' => $row['news_id'],
            'news_title' => $row['news_title'],
            'news_details' => $row['news_details'],
            'news_date' => $row['news_date'],
            'likes' => $row['likes'],
        ];
    }
    $response = ['status' => 'success', 'data' => $newsarray];
} else {
    $response = ['status' => 'failed', 'data' => null];
}

header('Content-Type: application/json');
echo json_encode($response);
?>

