-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Versión del servidor:         8.4.3 - MySQL Community Server - GPL
-- SO del servidor:              Win64
-- HeidiSQL Versión:             12.8.0.6908
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Volcando estructura para tabla app1601.restaurante
CREATE TABLE IF NOT EXISTS `restaurante` (
  `Restaurante_ID` int NOT NULL,
  `Nombre` varchar(50) NOT NULL DEFAULT '',
  `Logo` varchar(1000) DEFAULT NULL,
  `Direccion` varchar(50) NOT NULL DEFAULT '',
  `Telefono` int NOT NULL,
  `Correo` varchar(50) NOT NULL DEFAULT '',
  `rtn` int DEFAULT NULL,
  `Id_Usuario` int NOT NULL,
  KEY `id_Usuario` (`Id_Usuario`),
  CONSTRAINT `id_Usuario` FOREIGN KEY (`Id_Usuario`) REFERENCES `usuarios` (`Id_Usuario`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla app1601.restaurante: ~0 rows (aproximadamente)

-- Volcando estructura para tabla app1601.rol
CREATE TABLE IF NOT EXISTS `rol` (
  `Id_Rol` int NOT NULL AUTO_INCREMENT,
  `Descripcion` varchar(100) NOT NULL,
  PRIMARY KEY (`Id_Rol`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla app1601.rol: ~4 rows (aproximadamente)
REPLACE INTO `rol` (`Id_Rol`, `Descripcion`) VALUES
	(1, 'Administrador'),
	(2, 'Usuario'),
	(3, 'Repartidor'),
	(4, 'Empleado');

-- Volcando estructura para tabla app1601.usuarios
CREATE TABLE IF NOT EXISTS `usuarios` (
  `Id_Usuario` int NOT NULL AUTO_INCREMENT,
  `Nombre` varchar(150) NOT NULL,
  `Correo` varchar(150) NOT NULL,
  `Telefono` varchar(20) DEFAULT NULL,
  `Contrasena` varchar(255) NOT NULL,
  `Fecha_Registro` datetime DEFAULT CURRENT_TIMESTAMP,
  `Id_Rol` int NOT NULL,
  `activo` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`Id_Usuario`),
  UNIQUE KEY `Correo` (`Correo`),
  KEY `Id_Rol` (`Id_Rol`),
  CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`Id_Rol`) REFERENCES `rol` (`Id_Rol`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla app1601.usuarios: ~4 rows (aproximadamente)
REPLACE INTO `usuarios` (`Id_Usuario`, `Nombre`, `Correo`, `Telefono`, `Contrasena`, `Fecha_Registro`, `Id_Rol`, `activo`) VALUES
	(3, 'Jhair Rios', 'Jhair.com', '97854775', '1234', '2025-09-20 23:12:47', 1, 1),
	(5, 'Angel Perez', 'angel.com', NULL, '1234', '2025-09-21 18:27:34', 2, 1),
	(6, 'Jorge', 'Jorge.com', NULL, '1234', '2025-09-21 21:11:02', 2, 1);

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
