<?php
if (!isset($_POST)) {
	$response = array('status' => 'failed', 'data' => null);
    sendJsonResponse($response);
    die;
}

include_once("dbconnect.php");
$title = addslashes($_POST['title']);
$description = addslashes($_POST['description']);
$location = addslashes($_POST['location']);
$eventype = addslashes($_POST['eventtype']);
$startdate = ($_POST['start']);
$enddate = ($_POST['end']);
$image = ($_POST['image']);
$decoded_image = base64_decode($image);

$filename = "event-".randomfilename(10).".jpg";

 $sqlinsertevent="INSERT INTO `tbl_events`(`event_title`, `event_description`, `event_startdate`, `event_enddate`, `event_type`, `event_location`, `event_filename`) VALUES ('$title','$description','$startdate','$enddate','$eventype','$location','$filename')";

if ($conn->query($sqlinsertevent) === TRUE) {
    $path = "../assets/events/". $filename;
    file_put_contents($path, $decoded_image);
	$response = array('status' => 'success', 'data' => null);
    sendJsonResponse($response);
}else{
	$response = array('status' => 'failed', 'data' => null);
	sendJsonResponse($response);
}

function randomfilename($length) {
    $key = '';
    $keys = array_merge(range(0, 9), range('a', 'z'));

    for ($i = 0; $i < $length; $i++) {
        $key .= $keys[array_rand($keys)];
    }
    return $key;
}
	

function sendJsonResponse($sentArray)
{
    header('Content-Type: application/json');
    echo json_encode($sentArray);
}

?>
