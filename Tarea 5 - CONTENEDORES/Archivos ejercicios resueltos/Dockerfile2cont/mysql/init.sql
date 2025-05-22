CREATE TABLE Profesores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    apellido VARCHAR(100),
    dni VARCHAR(20),
    especialidad VARCHAR(50)
);

INSERT INTO Profesores (nombre, apellido, dni, especialidad) VALUES
('Ana', 'López', '12345678A', 'Teórica'),
('Luis', 'Pérez', '23456789B', 'Práctica'),
('María', 'Gómez', '34567890C', 'Teórica'),
('Carlos', 'Ruiz', '45678901D', 'Práctica'),
('Laura', 'Santos', '56789012E', 'Teórica');
