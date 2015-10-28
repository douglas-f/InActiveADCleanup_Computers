<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.95
	 Created on:   	10/9/2015 2:05 PM
	 Created by:   	Douglas Francis
	 Organization: 	SnarkySysAdmin.net
	 Filename:     	60DayInactiveComputers
	 Version: 		1.0
	===========================================================================
	.DESCRIPTION
		Searches AD for computer objects that have not signed into the domain in over 60 days.
		Excluding the Servers & Servers_New OU
		Creates a CSV file of the servers found for history.
		Disables the computers moves them to the Termed Computers OU.
#>
# Getting all computers, excluding Servers OU and Termed Computers OU
Import-Module ActiveDirectory
$computers = Get-ADComputer -Filter * -Properties lastlogondate | where { $_.distinguishedName -notmatch "OU=Server_New,OU=Corporate,DC=contoso,DC=net" -and $_.distinguishedName -notmatch "OU=Servers,OU=Corporate,DC=contoso,DC=net" -and $_.distinguishedName -notmatch "OU=TermComputerAccounts,OU=Termed Accounts,DC=contoso,DC=net" }

# Filtering all computers down to those that have not signed in in 60 days. Excluding computers created in the past 7 days
$InactiveComputers = $computers | Where { $_.LastLogonDate -le $(Get-Date).AddDays(-60) -and $_.Created -le $(Get-Date).AddDays(-7) }

# Exporting Results to CSV
$Path = "C:\Scripts\Script_Results\TermComputers"
$Filename = (Get-date).ToString(“MM-dd-yyyy-HH-mm-ss”) + “ - 60DayInActiveComputers.csv”
$InactiveComputers | select name, lastlogondate, distinguishedname | Export-Csv $Path\$Filename -NoTypeInformation

# Disabling all accounts and moving to term computers OU
foreach ($computer in $InactiveComputers)
{
	Get-ADComputer $computer | Disable-ADAccount -Confirm:$false 
	Get-ADComputer $computer | Move-ADObject -TargetPath "OU=TermDesktops,OU=TermComputerAccounts,OU=Termed Accounts,DC=contoso,DC=net"
}

# Setting up email and HTML for sending the report on what was disabled.
$html = "<style>"
$html = $html + "BODY{background-color:white;}"
$html = $html + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$html = $html + "TH{border-width: 1px;padding: 10px;border-style: solid;border-color: black;background-color:Crimson}"
$html = $html + "TD{border-width: 1px;padding: 10px;border-style: solid;border-color: black;background-color:Yellow}"
$html = $html + "</style>"

$InactiveComputers = $InactiveComputers | select name, lastlogondate, distinguishedname | ConvertTo-Html -Head $html

# emailing report 
$smtpServer = "smtp.contoso.net"
$smtpFrom = "PoSH_Reporting@contoso.com"

$message = New-Object System.Net.Mail.MailMessage
$message.From = "PoSH_Reporting@contoso.com"
$message.to.Add("infosec@contoso.com")
$Message.To.Add("serveradmin@contoso.com")
$Message.to.add("DTS_Engineering@contoso.com")
$message.Attachments.Add("$Path\$Filename")
$message.IsBodyHtml = $true
$message.Subject = "60 Day InActive Computers Report"
$message.Body = "Computer Objects that have not signed into the domain in over 60 days. <br/> These objects have been disabled and moved to the TermDesktops OU" + $InactiveComputers

$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($message)