# Import the Azure PowerShell module if not already loaded
#Install-Module -Name Az -Repository PSGallery -Force
# Authenticate to Azure (if not already authenticated)
#Connect-AzAccount -Identity
Connect-AzAccount

# Define your Azure Key Vault and secret names
$KeyVaultNameDevOps = "kv-devops-dev-neu-00"
$KeyVaultNameDev = "kvappplanepaldev02"
$UsernameSecretName = "sqllogin"
$PasswordSecretName = "sqlpassword"
$NewUsernameSecretName = "kv-email"
$NewPasswordSecretName = "kv-email-password"
$BacpacUsernameSecretName = "sqllogin-bacpac"
$BacpacPasswordSecretName = "sqlpassword-bacpac"

# Get the secrets from Azure Key Vault
$UsernameSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultNameDevOps -Name $UsernameSecretName -AsPlainText
$PasswordSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultNameDevOps -Name $PasswordSecretName -AsPlainText
$NewUsernameSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultNameDev -Name $NewUsernameSecretName -AsPlainText
$NewPasswordSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultNameDev -Name $NewPasswordSecretName -AsPlainText
$BacpacUsernameSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultNameDevOps -Name $BacpacUsernameSecretName -AsPlainText
$BacpacPasswordSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultNameDevOps -Name $BacpacPasswordSecretName -AsPlainText
# Extract the username and password from the secrets
$Username = $UsernameSecret
$Password = $PasswordSecret
$NewUsername = $NewUsernameSecret
$NewPassword = $NewPasswordSecret
$BacpacUserName = $BacpacUsernameSecret
$BacpacPassword = $BacpacPasswordSecret

# Define database connection parameters
$SqlServer = "sqlplanepaldevneu00.database.windows.net"
$MasterDatabase = "master"
$Database = "sqldbplanepaldevneu00"

# Define the connection string
$ConnectionString = "Server=$SqlServer;Database=$MasterDatabase;User Id=$Username;Password=$Password;"

# Create a SQL connection
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = $ConnectionString
$SqlConnection.Open()

$CreateLoginSql = @"
CREATE LOGIN $NewUsername WITH PASSWORD = '$NewPassword';
CREATE LOGIN $BacpacUserName WITH PASSWORD = '$BacpacPassword';
"@
# CREATE USER $NewUsername FOR LOGIN $NewUsername WITH DEFAULT_SCHEMA=[$Database];
# CREATE USER $BacpacUserName FOR LOGIN $BacpacUserName WITH DEFAULT_SCHEMA=[$Database];

$SqlCommand = $SqlConnection.CreateCommand()
$SqlCommand.CommandText = $CreateLoginSql
try {
    $SqlCommand.ExecuteNonQuery()
} catch {
    Write-Host "Login already exists."
}

# Close the SQL connection
$SqlConnection.Close()

# Define the connection string
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$ConnectionString = "Server=$SqlServer;Database=$Database;User Id=$Username;Password=$Password;"
$SqlConnection.ConnectionString = $ConnectionString

# Open the SQL connection
$SqlConnection.Open()

$SqlGrantPermissions = @"
CREATE USER $NewUsername FOR LOGIN $NewUsername;
ALTER ROLE db_datareader ADD MEMBER $NewUsername;
ALTER ROLE db_datawriter ADD MEMBER $NewUsername;
GRANT CREATE TABLE TO $NewUsername;
DENY ALTER ON DATABASE::$Database TO $NewUsername;
GRANT ALTER, SELECT, INSERT, UPDATE, DELETE ON DATABASE::$Database TO $NewUsername;
GRANT ALTER ANY SCHEMA TO $NewUsername;
"@

# Execute the SQL commands in the target database
$SqlCommand = $SqlConnection.CreateCommand()
$SqlCommand.CommandText = $SqlGrantPermissions
try{
    $SqlCommand.ExecuteNonQuery()
} catch {
    Write-Host "User already exists."
}

$SqlCreateSchema = "CREATE SCHEMA $Database AUTHORIZATION $NewUsername;"

# Execute the SQL commands in the target database
$SqlCommand = $SqlConnection.CreateCommand()
$SqlCommand.CommandText = $SqlCreateSchema
try {
    $SqlCommand.ExecuteNonQuery()
} catch {
    Write-Host "Schema already exists."
}

$SqlAlterSchema = @"
ALTER USER $NewUsername WITH DEFAULT_SCHEMA = $Database;
CREATE USER $BacpacUsername FOR LOGIN $BacpacUsername WITH DEFAULT_SCHEMA=[$Database];
ALTER USER $BacpacUsername WITH DEFAULT_SCHEMA = $Database;
"@

# Execute the SQL commands in the target database
$SqlCommand = $SqlConnection.CreateCommand()
$SqlCommand.CommandText = $SqlAlterSchema
try {
    $SqlCommand.ExecuteNonQuery()
} catch {
    Write-Host "Backup user already exsits."
}

# Close the SQL connection
$SqlConnection.Close()