<?php
$conexion = new mysqli("mysql", "user", "Abcd1234.", "Prueba");

if ($conexion->connect_error) {
    die("Conexión fallida: " . $conexion->connect_error);
}

echo "Conexión exitosa a la base de datos.";
?>

