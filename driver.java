import java.sql.*;

public class driver {
	public static void main (String [] args) {
	 
	try{
		//Connection to database
		Connection con = DriverManager.getConnection ("jdbc:mysql://localhost:3306/development", "root", "rock64");
		//Create a statement
		Statement mystm = con.createStatement ();
		//Execture SQL Query
		ResultSet myRs = mystm.executeQuery ("select * from ipacct");
		//Process the result	
		while (myRs.next()){
			System.out.println (myRs.toString());
		}
	} //end try
	catch (Exception exc){
		exc.printStackTrace ();
	}//end catch
}//end main
	
}
