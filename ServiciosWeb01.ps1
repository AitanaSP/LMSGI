param (
    [string]$NombreBase = "01"
)

$Region = "us-east-1"
$KeyName = "vockey"
$OutputFile = "ServiciosWeb$NombreBase-output.txt"
Remove-Item -Path $OutputFile -ErrorAction SilentlyContinue

function Write-OutputLog($text) {
    Add-Content -Path $OutputFile -Value $text
    Write-Host $text
}

# Crear VPC
$vpc = aws ec2 create-vpc --cidr-block 172.20.0.0/16 --region $Region | ConvertFrom-Json
$vpcId = $vpc.Vpc.VpcId
aws ec2 create-tags --resources $vpcId --tags Key=Name,Value="VPC-$NombreBase" --region $Region
Write-OutputLog "VPC creada: ID de VPC = $vpcId"

# Crear Subred
$subnet = aws ec2 create-subnet --vpc-id $vpcId --cidr-block 172.20.140.0/26 --region $Region | ConvertFrom-Json
$subnetId = $subnet.Subnet.SubnetId
aws ec2 create-tags --resources $subnetId --tags Key=Name,Value="Subred-$NombreBase" --region $Region
Write-OutputLog "Subred publica creada: ID de subred = $subnetId"

# Crear y asociar Internet Gateway
$igw = aws ec2 create-internet-gateway --region $Region | ConvertFrom-Json
$igwId = $igw.InternetGateway.InternetGatewayId
aws ec2 attach-internet-gateway --internet-gateway-id $igwId --vpc-id $vpcId --region $Region
aws ec2 create-tags --resources $igwId --tags Key=Name,Value="IGW-$NombreBase" --region $Region
Write-OutputLog "Internet Gateway creado: ID = $igwId"

# Crear tabla de rutas y asociarla
$routeTable = aws ec2 create-route-table --vpc-id $vpcId --region $Region | ConvertFrom-Json
$routeTableId = $routeTable.RouteTable.RouteTableId
aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 0.0.0.0/0 --gateway-id $igwId --region $Region
aws ec2 associate-route-table --route-table-id $routeTableId --subnet-id $subnetId --region $Region
aws ec2 create-tags --resources $routeTableId --tags Key=Name,Value="RT-$NombreBase" --region $Region
Write-OutputLog "Tabla de rutas creada y asociada: ID = $routeTableId"

# Obtener el ID del grupo de seguridad predeterminado de la VPC
$securityGroupId = aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpcId --query "SecurityGroups[?GroupName=='default'].GroupId" --output text --region $Region

# Agregar una regla de entrada para permitir tráfico HTTP en el puerto 80
aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $Region
Write-OutputLog "Regla de seguridad agregada: Puerto 80 (HTTP) abierto."

# Buscar AMIs más recientes para Ubuntu 24.04 y Windows Server 2025
$ubuntuAmi = "ami-084568db4383264d4"
$windowsAmi = "ami-02e3d076cbd5c28fa"

# Crear Ubuntu EC2
$userDataUbuntu = @"
#!/bin/bash
apt update
apt install -y nginx
echo 'Instancia Ubuntu 24.04 con Nginx - alisal01' > /var/www/html/index.html
"@ | Out-String
$ubuntuInstance = aws ec2 run-instances `
    --image-id $ubuntuAmi `
    --count 1 `
    --instance-type t3.micro `
    --key-name $KeyName `
    --subnet-id $subnetId `
    --associate-public-ip-address `
    --user-data "$userDataUbuntu" `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Ubuntu-$NombreBase}]" `
    --region $Region | ConvertFrom-Json
$ubuntuId = $ubuntuInstance.Instances[0].InstanceId
Write-OutputLog "EC2 Ubuntu creada: ID de instancia = $ubuntuId"

# Crear Windows EC2
# UserData para la instancia de Windows, asegurando que IIS se instale correctamente
$userDataWindows = @"
<powershell>
    # Instalar IIS y las herramientas de administración
    Install-WindowsFeature -Name Web-Server, Web-WebServer -IncludeManagementTools

    # Verificar si IIS está instalado
    $iisFeature = Get-WindowsFeature -Name Web-Server
    if ($iisFeature.Installed) {
        Write-Host 'IIS ha sido instalado correctamente.'
    } else {
        Write-Host 'Error al instalar IIS.'
    }

    # Crear una página de inicio personalizada en IIS
    $indexPath = 'C:\inetpub\wwwroot\index.html'
    Set-Content -Path $indexPath -Value 'Instancia Windows Server 2025 con IIS - alisal01'

    # Reiniciar el servicio IIS para asegurar que esté activo
    Restart-Service -Name W3SVC

    # Confirmación de que IIS está corriendo
    if ((Get-Service -Name W3SVC).Status -eq 'Running') {
        Write-Host 'El servicio IIS (W3SVC) está en funcionamiento.'
    } else {
        Write-Host 'El servicio IIS (W3SVC) no se pudo iniciar.'
    }
</powershell>
"@| Out-String
$windowsInstance = aws ec2 run-instances `
    --image-id $windowsAmi `
    --count 1 `
    --instance-type t3.micro `
    --key-name $KeyName `
    --subnet-id $subnetId `
    --associate-public-ip-address `
    --user-data "$userDataWindows" `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Windows-$NombreBase}]" `
    --region $Region | ConvertFrom-Json
$windowsId = $windowsInstance.Instances[0].InstanceId
Write-OutputLog "EC2 Windows creada: ID de instancia = $windowsId"

# Asignar IPs elásticas
$eipUbuntu = aws ec2 allocate-address --region $Region | ConvertFrom-Json
aws ec2 associate-address --instance-id $ubuntuId --allocation-id $eipUbuntu.AllocationId --region $Region
Write-OutputLog "IP elástica Ubuntu: $($eipUbuntu.PublicIp)"

$eipWindows = aws ec2 allocate-address --region $Region | ConvertFrom-Json
$retries = 5
$success = $false
for ($i = 0; $i -lt $retries; $i++) {
    try {
        # Intenta asociar la IP elástica
        aws ec2 associate-address --instance-id $windowsId --allocation-id $eipWindows.AllocationId --region $Region
        $success = $true
        break
    } catch {
        # Si falla, espera 30 segundos y vuelve a intentar
        Write-Host "Intento $($i+1) fallido. Esperando antes de reintentar..."
        Start-Sleep -Seconds 30
    }
}

if (-not $success) {
    Write-OutputLog "Error al asociar la IP elástica a la instancia de Windows después de varios intentos."
} else {
    Write-OutputLog "IP elástica Windows: $($eipWindows.PublicIp)"
}

Write-OutputLog "IP elástica Windows: $($eipWindows.PublicIp)"

Write-OutputLog "Despliegue completado. Archivo de salida: $OutputFile"
Read-Host "Presiona Enter para salir"