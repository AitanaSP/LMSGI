VPC creada: ID de VPC = vpc-0135587e95c490ae9
Subred publica creada: ID de subred = subnet-00b1869a3fe7b93bd
Internet Gateway creado: ID = igw-042cd3a5d2d88feb9
{
    "Return": true
}

{
    "AssociationId": "rtbassoc-040f4bedd9a78528e",
    "AssociationState": {
        "State": "associated"
    }
}

Tabla de rutas creada y asociada: ID = rtb-0963259a4659ed69c
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-0ae18ecc2804a34f1",
            "GroupId": "sg-0b57627fb48d52995",
            "GroupOwnerId": "236098929594",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIpv4": "0.0.0.0/0",
            "SecurityGroupRuleArn": "arn:aws:ec2:us-east-1:236098929594:security-group-rule/sgr-0ae18ecc2804a34f1"
        }
    ]
}

Regla de seguridad agregada: Puerto 80 (HTTP) abierto.
EC2 Ubuntu creada: ID de instancia = i-0a258ca6a9dbba6f5

usage: aws [options] <command> <subcommand> [<subcommand> ...] [parameters]
To see help text, you can run:

  aws help
  aws <command> help
  aws <command> <subcommand> help

Unknown options: HTTP -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
    Start-Service -Name W3SVC
    # Confirmación de que IIS está corriendo
    if ((Get-Service -Name W3SVC).Status -eq 'Running') {
        Write-Host 'El servicio IIS (W3SVC) está en funcionamiento.'
    } else {
        Write-Host 'El servicio IIS (W3SVC) no se pudo iniciar.'
    }
</powershell>


No se puede indizar en una matriz nula.
En C:\Users\cloud\Documents\ScriptSkills.ps1: 116 Carácter: 1
+ $windowsId = $windowsInstance.Instances[0].InstanceId
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [], RuntimeException
    + FullyQualifiedErrorId : NullArray

EC2 Windows creada: ID de instancia =

An error occurred (InvalidInstanceID) when calling the AssociateAddress operation: The pending instance 'i-0a258ca6a9dbba6f5' is not in a valid state for this operation.
IP elástica Ubuntu: 44.193.22.77

usage: aws [options] <command> <subcommand> [<subcommand> ...] [parameters]
To see help text, you can run:

  aws help
  aws <command> help
  aws <command> <subcommand> help

aws.exe: error: argument --instance-id: expected one argument

IP elástica Windows: 34.197.142.124
IP elástica Windows: 34.197.142.124
Despliegue completado. Archivo de salida: ServiciosWeb01-output.txt
Presiona Enter para salir: