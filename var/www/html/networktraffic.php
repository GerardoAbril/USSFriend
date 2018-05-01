<?php
$db_host = 'localhost:3306'; // Server Name
$db_user = 'root'; // Username
$db_pass = 'rock64'; // Password
$db_name = 'development'; // Database Name



$conn = mysqli_connect($db_host, $db_user, $db_pass, $db_name);
if (!$conn) {
	die ('Failed to connect to MySQL: ' . mysqli_connect_error());	
}

$sql = '
SELECT ip AS IP_Address, 
SUM(kilobytes) AS Kilobytes

FROM (
SELECT a.src_ip AS ip,
       SUM(a.length) AS kilobytes
FROM ipacct a
WHERE a.src_ip <> "0.0.0.0"
GROUP BY a.src_ip

UNION

SELECT b.dest_ip AS ip,
        SUM(b.length) AS kilobytes
FROM ipacct b
WHERE b.src_ip <> "0.0.0.0"
GROUP BY b.dest_ip
) as total

GROUP BY IP_Address
ORDER BY Kilobytes DESC;';



$query = mysqli_query($conn, $sql);


if (!$query) {
	die ('SQL Error: ' . mysqli_error($conn));
}
?>
<html>
<head>
        <title>Network Traffic</title>
        <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
 <div class="topnav">
<?php
include("/var/www/html/topnav.html");
?>
</div>
  <h1>NETWORK USAGE</h1>
<div style="{align:left;}">
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
</div>
<?php
                $conn->close();
?>
</body>
</html>
