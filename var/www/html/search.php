<?php
$db_host = 'localhost:3306'; // Server Name
$db_user = 'root'; // Username
$db_pass = 'rock64'; // Password
$db_name = 'development'; // Database Name



$conn = mysqli_connect($db_host, $db_user, $db_pass, $db_name);
if (!$conn) {
	die ('Failed to connect to MySQL: ' . mysqli_connect_error());	
}

$sql = 'SELECT * FROM ipacct';

$search = $_GET['search'];

$min_length = 3;

if(strlen($search) >= $min_length){
	#$search=htmlspecialchars($search);
	#$search=mysqli_real_escape_string($search);
	$query = mysqli_query($conn, $search);
}
else{
	$query = mysqli_query($conn, $sql);
}

if (!$query) {
	die ('SQL Error: ' . mysqli_error($conn) . $_POST['search']);
}
?>
<html>
<head>
        <title>Search Results</title>
        <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
 <div class="topnav">
<?php
include("/var/www/html/topnav.html");
?>
</div>
<h1>SEARCH RESULTS</h1><br>
<?php
$all_property = array();
				//showing property
		echo '<table class="data-table">
				<tr class="data-heading">';  //initialize table tag
		while ($property = mysqli_fetch_field($query)) {
			echo '<td>' . $property->name . '</td>';  //get field name for header
			array_push($all_property, $property->name);  //save those to array
		}
		echo '</tr>'; //end tr tag

		//showing all data
		while ($row = mysqli_fetch_array($query)) {
			echo "<tr>";
			foreach ($all_property as $item) {
				echo '<td>' . $row[$item] . '</td>'; //get items using property value
			}
			echo '</tr>';
		}
		echo "</table>";
		?>

<?php
                $conn->close();
?>
</body>
</html>