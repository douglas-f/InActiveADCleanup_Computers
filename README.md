# InActiveADCleanup_Computers
Finds/Disables computer accounts that haven't not recently communicated with the domain.

Full blog post on how this works 
- http://snarkysysadmin.com/powershell/inactive-computer-account-cleanup/

Set this script to run as a scheduled task on a server that runs under a service account that has rights to move/delete AD computer objects.

Modify the email addresses the SMPT server settings along with the OU's to search/exclude and where disabled computers should be placed.

