<%
	Option Explicit
%>
<!-- #Include virtual = "/Main/Include/CommonFunc.asp" -->
<%
	' This page is called by LoginOK.asp and LoginOKMob.asp for successful logins in order to generate a new asp Session ID for PCI  JH 7-17-17
	' We also need to re-populate the Session variables lost when the pre-login session is abandoned
	Dim strReturnUrl
	Dim strFName		' Customer's First name
	Dim strMName		' Customer's Middle name
	Dim strLName		' Customer's Last name
	Dim strEmailAddress	' Customer's Email Addr 
	Dim objUtility		' Utility Object used to log the event
	Dim objCust		' RtlCustomer object
	Dim objCustomerRs	' Record set for customer info  
	Dim objRs   		' RecordSet object for customer preferences

	' Check for custID cookie value, set strCustomerID equal to that if avaiable. 
	If ( Request.Cookies("custID") <> "") then
		Set objCust = Server.CreateObject("RtlCustomer.clsCustomerBiz")

		' Get the CustomerID based off of the token in the Cookie("custID") and verify it is valid
		strCustomerID =  objCust.VerifySessionToken(XSSFilter(Request.Cookies("custID")))

		If InStr(strCustomerID, "INVALID") then
			Response.redirect "/Main/Include/Error.asp"
			response.end
		Else
			Session("CustomerID") = strCustomerID
		End If
		
		' Retrieve the customer's info
		Set objCustomerRs = objCust.GetCustomerInfo(Session("CustomerID"))

		If Not ( ( objCustomerRs.BOF = True ) or ( objCustomerRs.EOF = True ) ) Then
			strFName = objCustomerRs.Fields("FName")
			strMName = objCustomerRs.Fields("MName")
			strLName = objCustomerRs.Fields("LName")
			strEmailAddress = objCustomerRs.Fields("EmailAddress")
		Else
			strFName = ""
			strMName = ""
			strLName = ""
			strEmailAddress = ""
		End If

		' Re-populate session variables lost when the session was abandoned
		Session("CustomerFName")	= strFName
		Session("CustomerMName")	= strMName
		Session("CustomerLName")	= strLName
		Session("EmailAddress")		= strEmailAddress  

		Set objCustomerRs = Nothing
		
		' Log this into tblRtlWebSessions
		Set objUtility = Server.CreateObject("Utility.clsUtilityBiz")						  
		ObjUtility.InsertRtlWebSessions Session.SessionID, Session("VisitorID"), "Login - Session transfer", now,  Request.ServerVariables("REMOTE_HOST"), Request.ServerVariables("URL"), Request.ServerVariables("Query_String"), Session("AnoCustID"), Session("CustomerID")
		Set objUtility = Nothing


		Set objRs = objCust.GetCustomerWebSetting(Session("CustomerID"))
		
		Dim bExpressCheckoutFlag			' if use express checkout as default
		Dim bBookThumbnailsOffGlobalFlag	' Turn off all thumbnails in book page for viewing if true
		Dim bBookThumbnailsOffSearchFlag	' Turn off all thumbnails in book search page for viewing if true
		Dim bDVDThumbnailsOffGlobalFlag		' Turn off all thumbnails in DVD page for viewing if true
		Dim bDVDThumbnailsOffSearchFlag		' Turn off all thumbnails in DVD search page for viewing if true
		Dim bMusicThumbnailsOffGlobalFlag	' Turn off all thumbnails in music page for viewing if true
		Dim bMusicThumbnailsOffSearchFlag	' Turn off all thumbnails in music search page for viewing if true
		Dim intBookDefaultSort				' book page's default sort type
		Dim intDVDDefaultSort				' DVD page's default sort type
		Dim intMusicDefaultSort				' music page's default sort type
		Dim intShipMethod					' default ship method
		Dim intErrorCode					' to hold the error code returned by COM/Stored Proc
		Dim strErrorMsg						' error message to display to users when loading customer settings

		bExpressCheckoutFlag		= objRs("ExpressCheckoutFlag")
		bBookThumbnailsOffGlobalFlag	= objRs("BookThumbnailsOffGlobalFlag")
		bBookThumbnailsOffSearchFlag	= objRs("BookThumbnailsOffSearchFlag")
		bDVDThumbnailsOffGlobalFlag	= objRs("DVDThumbnailsOffGlobalFlag")
		bDVDThumbnailsOffSearchFlag	= objRs("DVDThumbnailsOffSearchFlag")
		bMusicThumbnailsOffGlobalFlag	= objRs("MusicThumbnailsOffGlobalFlag")
		bMusicThumbnailsOffSearchFlag	= objRs("MusicThumbnailsOffSearchFlag")
		intBookDefaultSort		= objRs("BookDefaultSort")
		intDVDDefaultSort		= objRs("DVDDefaultSort")
		intMusicDefaultSort		= objRs("MusicDefaultSort")
		intShipMethod			= objRs("DefaultShipMethodID")
		strErrorMsg			= objRs("ErrorMsg")
		
		objRs.Close
		Set objCust = Nothing
		Set objRs = Nothing

		' Set Session variables for customer preferences
		Session("ExpressCheckoutFlag")		= bExpressCheckoutFlag
		Session("BookThumbnailsOffGlobalFlag")	= bBookThumbnailsOffGlobalFlag
		Session("BookThumbnailsOffSearchFlag")	= bBookThumbnailsOffSearchFlag
		Session("DVDThumbnailsOffGlobalFlag")	= bDVDThumbnailsOffGlobalFlag
		Session("DVDThumbnailsOffSearchFlag")	= bDVDThumbnailsOffSearchFlag
		Session("MusicThumbnailsOffGlobalFlag")	= bMusicThumbnailsOffGlobalFlag
		Session("MusicThumbnailsOffSearchFlag")	= bMusicThumbnailsOffSearchFlag
		Session("BookDefaultSort")		= intBookDefaultSort
		Session("MusicDefaultSort")		= intMusicDefaultSort
		Session("DVDDefaultSort")		= intDVDDefaultSort
		Session("ShipMethod")			= intShipMethod

		If strErrorMsg & "x" <> "x" Then
		%>
			<script language="javascript">
				alert("Express Checkout is currently disabled. Reason: <%=strErrorMsg%>.\n\nTo re-enable Express Checkout, please correct this problem.");
			</script>				
		<%
		End if


		Response.Cookies("custID").Expires = DateAdd("d",-1,Now())		' expire the custID cookie once read
	End If

	strReturnUrl = Replace( PathFilter(XSSFilter(Request("ReturnUrl"))), "@", "&" )

	if ( strReturnUrl <> "" ) then
		Response.Redirect strReturnUrl
	else
		Response.Redirect "/default.asp"
	end if
	Response.End
%>
