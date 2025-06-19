-- Creamos la base de datos y la usamos
CREATE DATABASE IF NOT EXISTS tienda_libros;
USE tienda_libros;

-- Creamos la tabla autor
CREATE TABLE autor (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    nacionalidad VARCHAR(50),
    fecha_nacimiento DATE,
    CONSTRAINT autor_nombre_apellido_unique UNIQUE (nombre, apellido)
);

-- Creamos la tabla libro
CREATE TABLE libro (
    id INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(100) NOT NULL,
    isbn VARCHAR(13) NOT NULL UNIQUE,
    año_publicacion INT,
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    CONSTRAINT stock_positivo CHECK (stock >= 0),
    CONSTRAINT precio_positivo CHECK (precio > 0)
);

-- Creamoss la tabla intermedia autor_libro (para la relación N:M)
CREATE TABLE autor_libro (
    autor_id INT,
    libro_id INT,
    PRIMARY KEY (autor_id, libro_id),
    FOREIGN KEY (autor_id) REFERENCES Autor(id) ON DELETE CASCADE,
    FOREIGN KEY (libro_id) REFERENCES Libro(id) ON DELETE CASCADE
);

-- Creamos la tabla cliente
CREATE TABLE cliente (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    direccion TEXT NOT NULL
);

-- Creamos la tabla pedido
CREATE TABLE pedido (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    total DECIMAL(10,2) NOT NULL,
    cliente_id INT NOT NULL,
    FOREIGN KEY (cliente_id) REFERENCES Cliente(id) ON DELETE RESTRICT,
    CONSTRAINT total_positivo CHECK (total >= 0),
    CONSTRAINT estado_valido CHECK (estado IN ('PENDIENTE', 'PROCESANDO', 'COMPLETADO', 'CANCELADO'))
);

-- Creamos la tabla detalle_pedido
CREATE TABLE detalle_pedido (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    pedido_id INT NOT NULL,
    libro_id INT NOT NULL,
    FOREIGN KEY (pedido_id) REFERENCES Pedido(id) ON DELETE CASCADE,
    FOREIGN KEY (libro_id) REFERENCES Libro(id) ON DELETE RESTRICT,
    CONSTRAINT cantidad_positiva CHECK (cantidad > 0),
    CONSTRAINT precio_unitario_positivo CHECK (precio_unitario > 0),
    CONSTRAINT subtotal_positivo CHECK (subtotal > 0)
);

-- Agregamos autores
INSERT INTO autor (nombre, apellido, nacionalidad, fecha_nacimiento) VALUES
('Gabriel', 'García Márquez', 'Colombiana', '1927-03-06'),
('Jorge Luis', 'Borges', 'Argentina', '1899-08-24'),
('Isabel', 'Allende', 'Chilena', '1942-08-02');

-- Agregamos libros
INSERT INTO libro (titulo, isbn, año_publicacion, precio, stock) VALUES
('Cien años de soledad', '9780307474728', 1967, 29.99, 50),
('El Aleph', '9780142437883', 1949, 19.99, 30),
('La casa de los espíritus', '9780525433477', 1982, 24.99, 40),
('Crónica de una muerte anunciada', '9780307474739', 1981, 21.99, 25),
('Ficciones', '9780802130303', 1944, 22.99, 35);

-- Agregamos relacion entre autores y libros
INSERT INTO autor_libro (autor_id, libro_id) VALUES
(1, 1), -- García Márquez - Cien años de soledad
(1, 4), -- García Márquez - Crónica de una muerte anunciada
(2, 2), -- Borges - El Aleph
(2, 5), -- Borges - Ficciones
(3, 3); -- Allende - La casa de los espíritus

-- Agregamos clientes
INSERT INTO cliente (nombre, apellido, email, telefono, direccion) VALUES
('Ana', 'Martínez', 'ana.martinez@email.com', '555-0101', 'Calle Principal 123'),
('Carlos', 'Rodríguez', 'carlos.rodriguez@email.com', '555-0102', 'Avenida Central 456'),
('María', 'González', 'maria.gonzalez@email.com', '555-0103', 'Plaza Mayor 789'),
('Juan', 'López', 'juan.lopez@email.com', '555-0104', 'Calle Secundaria 321');

-- Agregamos pedidos
INSERT INTO pedido (fecha_pedido, estado, total, cliente_id) VALUES
('2023-11-01 10:00:00', 'COMPLETADO', 74.97, 1),  -- Pedido de Ana
('2023-11-02 15:30:00', 'PROCESANDO', 44.98, 2),  -- Pedido de Carlos
('2023-11-03 09:15:00', 'PENDIENTE', 68.97, 3);   -- Pedido de María

-- Agregamos detalles de pedido
INSERT INTO detalle_pedido (cantidad, precio_unitario, subtotal, pedido_id, libro_id) VALUES
-- Pedido 1 (Ana)
(1, 29.99, 29.99, 1, 1),  -- Cien años de soledad
(1, 24.99, 24.99, 1, 3),  -- La casa de los espíritus
(1, 19.99, 19.99, 1, 2),  -- El Aleph

-- Pedido 2 (Carlos)
(2, 22.49, 44.98, 2, 5),  -- Ficciones (2 unidades)

-- Pedido 3 (María)
(2, 21.99, 43.98, 3, 4),  -- Crónica de una muerte anunciada (2 unidades)
(1, 24.99, 24.99, 3, 3);  -- La casa de los espíritus

-- Consulta para mostrar todos los libros publicados despues de 1980, ordenados por año
SELECT titulo, año_publicacion, precio
FROM libro
WHERE año_publicacion > 1980
ORDER BY año_publicacion ASC;

-- Consulta para mostrar autores y la cantidad de libros que han escrito
SELECT 
    a.nombre,
    a.apellido,
    COUNT(al.libro_id) as total_libros
FROM autor a
LEFT JOIN autor_libro al ON a.id = al.autor_id
GROUP BY a.id, a.nombre, a.apellido
ORDER BY total_libros DESC;

-- Actualiza el precio unitario y volvemos a calcular el subtotal
UPDATE detalle_pedido
SET 
    precio_unitario = 25.99,
    subtotal = cantidad * 25.99
WHERE id = 1;

-- Actualiza el total del pedido seleccionado
UPDATE pedido p
SET total = (
    SELECT SUM(subtotal)
    FROM detalle_pedido
    WHERE pedido_id = p.id
)
WHERE id = (
    SELECT pedido_id 
    FROM detalle_pedido 
    WHERE id = 1
);

-- Verifica si el libro tiene pedidos asociados
SELECT COUNT(*) 
FROM detalle_pedido 
WHERE libro_id = 1;

-- Si no hay pedidos asociados, elimina el libro y sus relaciones
DELETE FROM autor_libro
WHERE libro_id = 1;

DELETE FROM libro
WHERE id = 1;

-- Creamos vista
CREATE VIEW vista_pedidos AS
SELECT 
    p.id as pedido_id,
    CONCAT(c.nombre, ' ', c.apellido) as nombre_cliente,
    p.fecha_pedido,
    p.total
FROM pedido p
INNER JOIN cliente c ON p.cliente_id = c.id;

-- Consulta que muestra pedidos con total mayor a 50
SELECT *
FROM vista_pedidos
WHERE total > 50
ORDER BY total DESC;