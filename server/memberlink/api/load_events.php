<?php

include_once("dbconnect.php");

$results_per_page = 20;
if (isset($_GET['pageno'])){
	$pageno = (int)$_GET['pageno'];
}else{
	$pageno = 1;
}

$page_first_result = ($pageno - 1) * $results_per_page;

$sqlloadevents = "SELECT * FROM `tbl_events` ORDER BY `event_date` DESC";
$result = $conn->query($sqlloadevents);
$number_of_result = $result->num_rows;

$number_of_page = ceil($number_of_result / $results_per_page);
$sqlloadevents = $sqlloadevents." LIMIT $page_first_result, $results_per_page";

$result = $conn->query($sqlloadevents);
// `event_id`, `event_title`, `event_description`, `event_startdate`, `event_enddate`, `event_type`, `event_location`, `event_filename`, `event_date`
if ($result->num_rows > 0) {
    $eventsarray['events'] = array();
    while ($row = $result->fetch_assoc()) {
        $event = array();
        $event['event_id'] = $row['event_id'];
        $event['event_title'] = $row['event_title'];
        $event['event_description'] = $row['event_description'];
        $event['event_startdate'] = $row['event_startdate'];
        $event['event_enddate'] = $row['event_enddate'];
        $event['event_type'] = $row['event_type'];
        $event['event_location'] = $row['event_location'];
        $event['event_filename'] = $row['event_filename'];
        $event['event_date'] = $row['event_date'];
        array_push($eventsarray['events'], $event);
    }
    $response = array('status' => 'success', 'data' => $eventsarray,'numofpage'=>$number_of_page,'numberofresult'=>$number_of_result);
    sendJsonResponse($response);
}else{
    $response = array('status' => 'failed', 'data' => null, 'numofpage'=>$number_of_page,'numberofresult'=>$number_of_result);
    sendJsonResponse($response);
}
	
	
function sendJsonResponse($sentArray)
{
    header('Content-Type: application/json');
    echo json_encode($sentArray);
}

?>
