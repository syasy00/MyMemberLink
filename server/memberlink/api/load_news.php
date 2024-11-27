<?php
include_once("dbconnect.php");

// Enable error reporting for debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

$page = isset($_GET['pageno']) ? (int)$_GET['pageno'] : 1;
$limit = isset($_GET['no_limit']) && $_GET['no_limit'] == "true" ? 0 : 5; // No limit if no_limit=true
$offset = ($page - 1) * $limit;

$query = isset($_GET['query']) ? $conn->real_escape_string($_GET['query']) : '';
$sort = isset($_GET['sort']) ? $_GET['sort'] : 'Latest';

$order = $sort === 'Trending' ? "ORDER BY likes DESC, news_date DESC" : "ORDER BY news_date DESC";

if (!empty($query)) {
    $sqlloadnews = "SELECT * FROM tbl_news WHERE 
                    news_title LIKE '%$query%' OR 
                    news_details LIKE '%$query%' 
                    $order";
    if ($limit > 0) {
        $sqlloadnews .= " LIMIT $offset, $limit"; // Add LIMIT if no_limit is not true
    }
} else {
    $sqlloadnews = "SELECT * FROM tbl_news $order";
    if ($limit > 0) {
        $sqlloadnews .= " LIMIT $offset, $limit"; // Add LIMIT if no_limit is not true
    }
}

$sqltotal = "SELECT COUNT(*) AS total FROM tbl_news 
             WHERE news_title LIKE '%$query%' OR news_details LIKE '%$query%'";

$totalresult = $conn->query($sqltotal);
$totalrows = $totalresult->fetch_assoc();
$totalpages = $limit > 0 ? ceil($totalrows['total'] / $limit) : 1;

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
    $newsarray['total_pages'] = $totalpages;
    $response = ['status' => 'success', 'data' => $newsarray];
} else {
    $response = ['status' => 'failed', 'data' => null];
}

header('Content-Type: application/json');
echo json_encode($response);
?>
