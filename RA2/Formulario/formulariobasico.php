<?php
/*Esto define mis permisos para entrar a la base de datos*/
$db_host="localhost"
$db_user="aitana"
$db_password="aitana"
$db_name="pruebaLenguaje"
$db_tablename="usuariopeti"

/*Esto me hace la conexion con la base de datos */
$db_connection= mysqli_connect($db_host, $db_user, $db_name)

/* Esto manda lo que viene del formulario*/

$form_nombre = $_POST["nombre"]
$form_apellido = $_POST["apellido"]
$form_email = $_POST["email"]


?>