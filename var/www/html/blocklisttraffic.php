<?php
$db_host = 'localhost:3306'; // Server Name
$db_user = 'root'; // Username
$db_pass = 'rock64'; // Password
$db_name = 'development'; // Database Name



$conn = mysqli_connect($db_host, $db_user, $db_pass, $db_name);
if (!$conn) {
	die ('Failed to connect to MySQL: ' . mysqli_connect_error());	
}

$sql = 'SELECT
src_ip AS Source,
src_port AS Port,
dest_ip AS Destination,
dest_port AS Port,
protocol,
length as Kilobytes,
flags,
ipacct.timestamp

FROM ipacct
JOIN blocklist
ON ipacct.src_ip = blocklist.blocklist_ip
OR ipacct.dest_ip = blocklist.blocklist_ip;';



$query = mysqli_query($conn, $sql);


if (!$query) {
	die ('SQL Error: ' . mysqli_error($conn));
}
?>
<html>
<head>
        <title>Blocklist Communique</title>
        <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
 <div class="topnav">
<?php
include("/var/www/html/topnav.html");
?>
</div>
  <h1>TRAFFIC WITH BLOCKLIST IP ADDRESSES</h1>
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
