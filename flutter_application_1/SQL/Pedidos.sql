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


-- Volcando estructura de base de datos para app1601
CREATE DATABASE IF NOT EXISTS `app1601` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `app1601`;

-- Volcando estructura para tabla app1601.categoria
CREATE TABLE IF NOT EXISTS `categoria` (
  `ID_Categoria` int NOT NULL AUTO_INCREMENT,
  `Descripcion` varchar(100) NOT NULL,
  PRIMARY KEY (`ID_Categoria`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla app1601.categoria: ~0 rows (aproximadamente)

-- Volcando estructura para tabla app1601.menu
CREATE TABLE IF NOT EXISTS `menu` (
  `ID_Menu` int NOT NULL AUTO_INCREMENT,
  `Platillo` varchar(100) NOT NULL DEFAULT '',
  `Precio` float NOT NULL DEFAULT '0',
  `Descripcion` varchar(200) NOT NULL DEFAULT '',
  `ID_Categoria` int NOT NULL,
  `Estado` int NOT NULL,
  PRIMARY KEY (`ID_Menu`),
  KEY `FK__categoria` (`ID_Categoria`),
  CONSTRAINT `FK__categoria` FOREIGN KEY (`ID_Categoria`) REFERENCES `categoria` (`ID_Categoria`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla app1601.menu: ~0 rows (aproximadamente)

-- Volcando estructura para tabla app1601.pedidos
CREATE TABLE IF NOT EXISTS `pedidos` (
  `ID_Pedido` int NOT NULL AUTO_INCREMENT,
  `Platillo` int DEFAULT NULL,
  `ID_Usuarios` int DEFAULT '0',
  `Total` int DEFAULT '0',
  `Ubicacion` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`ID_Pedido`),
  KEY `Platillo_FK` (`Platillo`),
  KEY `Usuario_FK` (`ID_Usuarios`),
  CONSTRAINT `Platillo_FK` FOREIGN KEY (`Platillo`) REFERENCES `menu` (`ID_Menu`),
  CONSTRAINT `Usuario_FK` FOREIGN KEY (`ID_Usuarios`) REFERENCES `usuarios` (`Id_Usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla app1601.pedidos: ~0 rows (aproximadamente)

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
  PRIMARY KEY (`Restaurante_ID`),
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
INSERT IGNORE INTO `rol` (`Id_Rol`, `Descripcion`) VALUES
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla app1601.usuarios: ~3 rows (aproximadamente)
INSERT IGNORE INTO `usuarios` (`Id_Usuario`, `Nombre`, `Correo`, `Telefono`, `Contrasena`, `Fecha_Registro`, `Id_Rol`, `activo`) VALUES
	(2, 'Lucas Juarez', 'lucas.com', '97251345', '1234', '2025-09-19 22:45:37', 4, 1),
	(3, 'Jhair Rios', 'jhair.com', '97854775', '1234', '2025-09-20 23:12:47', 1, 1),
	(4, 'Dair', 'dair.com', NULL, '1234', '2025-09-23 18:14:21', 2, 1);

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
