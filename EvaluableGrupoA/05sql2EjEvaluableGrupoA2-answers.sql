-- ---------------------------------------------------------------------
-- SOLUCIONES EJERCICIO EVALUABLE 1. GRUPO A.
-- Estas consultas se pueden resolver de diversas formas no incluidas
-- aquí.
-- ---------------------------------------------------------------------

-- Ejercicio 1. Librería AllTheBooks}.
-- Antes de realizar las consultas, utiliza sentencias SQL para insertar
-- un nuevo libro de Miguel de Cervantes editado en 2014 y titulado
-- 'Novelas Ejemplares', e invéntate los datos de precio de compra y
-- venta.  Añade además sentencias SQL para almacenar en la BD que ha
-- sido pedido el martes pasado por Pedro Santillana (3 ejemplares),
-- Ambrosio Perez (2 ejemplares) y Lola Arribas (2 ejemplares).

alter session set nls_date_format='DD/MM/YYYY';

insert into Libro values ('1234567890','Novelas Ejemplares',2014,27,33);
insert into Autor_Libro values ('1234567890',4);
insert into Pedido values ('0000007P','0000003',TO_DATE('29/11/2016'),NULL);
insert into Pedido values ('0000008P','0000005',TO_DATE('29/11/2016'),NULL);
insert into Pedido values ('0000009P','0000006',TO_DATE('29/11/2016'),NULL);
INSERT INTO LIBROS_PEDIDO values ('1234567890','0000007P',3);
INSERT INTO LIBROS_PEDIDO values ('1234567890','0000008P',2);
INSERT INTO LIBROS_PEDIDO values ('1234567890','0000009P',2);

-- 1.a. Lista de los autores y el número de ejemplares vendidos de
--      cada autor, en orden decreciente de ventas. 

SELECT a.IdAutor, a.Nombre, sum(lp.Cantidad)
FROM Autor a JOIN Autor_Libro al ON a.idautor = al.Autor
JOIN Libros_Pedido lp ON al.ISBN = lp.ISBN
GROUP BY a.IdAutor, a.Nombre
ORDER BY sum(lp.Cantidad) DESC;

-- 1.b. Lista de los autores y el número de clientes distintos que han 
--      comprado sus libros, en orden decreciente de número de clientes.

SELECT a.IdAutor, a.Nombre, count(DISTINCT IdCliente)
FROM Autor a JOIN Autor_Libro al ON a.idautor = al.Autor
JOIN Libros_Pedido lp ON al.ISBN = lp.ISBN
JOIN Pedido p ON lp.IdPedido = p.IdPedido
GROUP BY a.IdAutor, a.Nombre
ORDER BY count(DISTINCT IdCliente) DESC;

-- 1.c. Lista de los autores y el número de ejemplares vendidos de aquellos autores
--      que han vendido tantos ejemplares como el Autor con IdAutor = 1.

SELECT a.IdAutor, a.Nombre, sum(Cantidad)
FROM Autor a JOIN Autor_Libro al ON a.idautor = al.Autor
JOIN Libros_Pedido lp ON al.ISBN = lp.ISBN
GROUP BY a.IdAutor, a.Nombre
HAVING sum(Cantidad) >= 
       (SELECT sum(Cantidad)
        FROM Autor_Libro al1 JOIN Libros_Pedido lp1 ON al1.ISBN = lp1.ISBN
        WHERE al1.Autor = 1);

-- 1.d. Lista de los autores y su rentabilidad en orden decreciente de rentabilidad.

SELECT a.IdAutor, a.Nombre, sum(cantidad*l.PrecioVenta - cantidad*l.PrecioCompra)
FROM Autor a JOIN Autor_Libro al ON a.idautor = al.Autor
JOIN Libros_Pedido lp ON al.ISBN = lp.ISBN
JOIN Libro l ON lp.ISBN = l.ISBN
GROUP BY a.Nombre, a.IdAutor
ORDER BY sum(cantidad*l.PrecioVenta - cantidad*l.PrecioCompra) DESC;
  
-- 1.e. Lista de los autores que han tenido para la tienda una rentabilidad mayor 
--      que la rentabilidad media, en orden alfabético.

-- Esta consulta es realmente difícil.  Se incluyen dos versiones:
-- (1) La primera versión utiliza vistas.  Observa que el producto
--     cartesiano de las dos vistas devuelve una sola fila, pues
--     cada vista devuelve una sola fila.
--     IMPORTANTE: en el control se os va a pedir que resolváis las consultas
--     sin utilizar vistas.

CREATE OR REPLACE VIEW vRentabAutores (IdAutor, rentabAutor) AS 
       SELECT al1.Autor, sum(lp1.Cantidad*l1.PrecioVenta - lp1.Cantidad*l1.PrecioCompra)
       FROM Autor_Libro al1 JOIN Libros_Pedido lp1 ON al1.ISBN = lp1.ISBN
       JOIN Libro l1 ON lp1.ISBN = l1.ISBN
       GROUP BY al1.Autor;

CREATE OR REPLACE VIEW vRentabMedia (rentabMedia) AS 
       SELECT avg(rentabAutor) FROM vRentabAutores;

SELECT v.IdAutor, a.Nombre, v.rentabAutor
FROM Autor a JOIN vRentabAutores v ON a.IdAutor = v.IdAutor
WHERE v.rentabAutor > (SELECT rentabMedia FROM vRentabMedia)
ORDER BY a.Nombre;

-- (2) La segunda versión no utiliza vistas, pero utiliza dos consultas
--     anidadas, una de ellas en la cláusula FROM:

SELECT a.IdAutor, a.Nombre, sum(lp.cantidad*l.PrecioVenta - lp.cantidad*l.PrecioCompra)
FROM Autor a JOIN Autor_Libro al ON a.idautor = al.Autor
JOIN Libros_Pedido lp ON al.ISBN = lp.ISBN
JOIN Libro l ON lp.ISBN = l.ISBN
GROUP BY a.IdAutor, a.Nombre
HAVING sum(lp.cantidad*l.PrecioVenta - lp.cantidad*l.PrecioCompra) > (
       SELECT avg(Rentab) 
       FROM (SELECT sum(lp1.cantidad*l1.PrecioVenta - lp1.cantidad*l1.PrecioCompra) Rentab
       	    FROM Autor_Libro al1 JOIN Libros_Pedido lp1 ON al1.ISBN = lp1.ISBN
	    JOIN Libro l1 ON lp1.ISBN = l1.ISBN
	    GROUP BY al1.Autor))
ORDER BY a.Nombre;

-- -------------------------------------------------------------
-- Ejercicio 2. Aerolínea.
-- Escribe consultas para proporcionar la siguiente información:

-- 2.a. Nombre de los aviones tales que todos los pilotos
--    certificados para operar con ellos tengan salarios superiores a 
--    80.000 euros.

SELECT a.nombre
FROM avion a
WHERE 80000 <= ALL (SELECT e.salario FROM certificado c
      	       	   JOIN empleado e ON e.eid = c.eid
		   WHERE c.aid = a.aid /*OJO: CORRELACIONADA*/);

-- 2.b. Calcular la diferencia entre la media salarial de todos
--    los empleados (incluidos los pilotos) y la de los pilotos.

-- Esta consulta es realmente difícil.  Se incluyen dos versiones:
-- (1) La primera versión utiliza vistas.  Observa que el producto
--     cartesiano de las dos vistas devuelve una sola fila, pues
--     cada vista devuelve una sola fila.

CREATE OR REPLACE VIEW vTodos (mediaTodos) AS 
       	    SELECT AVG(salario) FROM empleado;

CREATE OR REPLACE VIEW vPilotos (mediaPilotos) AS 
       	    SELECT AVG(salario) FROM empleado e 
	    	   		JOIN certificado c ON e.eid = c.eid;

SELECT mediaTodos - mediaPilotos FROM vTodos, vPilotos;

-- (2) La segunda versión no utiliza vistas, pero utiliza dos consultas
--     anidadas en la cláusula FROM:

SELECT mediaTodos - mediaPilotos 
FROM (SELECT AVG(salario) mediaTodos FROM empleado),
     (SELECT AVG(salario) mediaPilotos FROM empleado e 
      JOIN certificado c ON e.eid = c.eid);

-----------------------------------------------------------------

