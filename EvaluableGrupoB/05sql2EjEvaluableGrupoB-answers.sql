-- ---------------------------------------------------------------------
-- SOLUCIONES EJERCICIO EVALUABLE 1. GRUPO B.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- Ejercicio 1. Consultas sobre el ejercicio de la compañía aérea 
-- FlyWithOther.
-- Utiliza las tablas y los datos disponibles para este ejercicio y 
-- escribe consultas para proporcionar la siguiente información:

-- 1.a. Lista de los tipos de aviones y el gasto total en sueldos
--      de pilotos certificados por cada tipo de avión, en orden 
--      decreciente de gasto. 
--      Nota: un mismo piloto contribuye al gasto
--      total de cada uno de los tipos de avión para los que está
--      certificado.

SELECT a.aid, a.nombre, sum(e.salario) 
FROM avion a JOIN certificado c ON a.aid = c.aid
JOIN empleado e ON c.eid = e.eid
GROUP BY a.aid, a.nombre
ORDER BY sum(e.salario) DESC;

-- En esta consulta algunos habéis realizado un OUTER JOIN para 
-- mostrar todos los tipos de aviones (hay un tipo de avión que
-- no tiene pilotos certificados).  He considerado correctas las 
-- dos versiones.  La versión con OUTER JOIN es la siguiente:

SELECT a.aid, a.nombre, sum(e.salario) 
FROM (certificado c JOIN empleado e ON c.eid = e.eid)
RIGHT OUTER JOIN avion a ON a.aid = c.aid
GROUP BY a.aid, a.nombre
ORDER BY sum(e.salario) DESC;


-- 1.b. Lista de los id y nombre de los pilotos que están
--      certificados para alguno de los aviones para los que está
--      certificada 'Lisa Walker'. 

SELECT DISTINCT e.eid, e.nombre 
FROM empleado e JOIN certificado c ON e.eid=c.eid 
WHERE c.aid IN (SELECT c2.aid 
                FROM certificado c2 JOIN empleado e2 ON c2.eid=e2.eid
                WHERE e2.nombre='Lisa Walker');

-- 1.c. Lista de los pilotos que pueden pilotar el vuelo que une
--      Los Ángeles con Boston. 

-- Esta consulta es difícil porque la condición de una de las reuniones
-- (entre vuelo y avion) no es por igualdad.

SELECT DISTINCT e.eid, e.nombre   -- errata corregida: DISTINCT
FROM empleado e JOIN certificado c ON e.eid = c.eid
JOIN avion a ON c.aid = a.aid
JOIN vuelo v ON v.distancia <= a.autonomia
WHERE v.origen = 'Los Angeles' and v.destino = 'Boston';

-- 1.d. Lista de los vuelos que realiza la compañía, indicando por
--      cada vuelo el origen, destino, número de pilotos que pueden 
--      pilotar el vuelo y salario más bajo de los pilotos que lo 
--      pueden pilotar. 
--      Nota: un piloto puede hacer un mismo vuelo con
--      distintos modelos de avión, pero solo debe contarse una vez.

-- En este caso hay que darse cuenta de que la cuenta de pilotos
-- que pueden pilotar un vuelo debe considerar cada piloto una sola
-- vez (con DISTINCT).

SELECT v.flno, v.origen, v.destino, count(DISTINCT e.eid), min(e.salario)
FROM vuelo v JOIN avion a ON v.distancia <= a.autonomia
JOIN certificado c ON a.aid = c.aid
JOIN empleado e ON c.eid = e.eid
GROUP BY v.flno, v.origen, v.destino;

-- 1.e. Lista de los viajes (origen, destino, escala, precio total) que 
--      se pueden hacer con exactamente una escala y utilizando aviones 
--      modelo 'Boeing 727' en los dos vuelos.  
--      Nota: El resultado debe estar formado por solo dos filas que 
--      corresponden al trayecto Madison - New York, haciendo escala en 
--      Detroit o Minneapolis.

SELECT v1.origen, v2.destino, v1.destino AS escala, v1.precio+v2.precio
FROM vuelo v1 JOIN vuelo v2 ON v1.destino =v2.origen
WHERE v1.origen != v2.destino AND v1.llegada < v2.salida
AND greatest(v1.distancia,v2.distancia) <= 
       (SELECT autonomia FROM avion WHERE nombre = 'Boeing 727');

-- 1.f. Lista de los viajes que se pueden hacer con cero o una
--      escalas por menos de 301 euros. Se deben mostrar en el 
--      resultado dos columnas: el trayecto del viaje (con el
--      formato siguiente: origen--destino si el vuelo no tiene escalas,
--      o bien origen--escala--destino si tiene una escala) y el precio 
--      total. 

-- Esta consulta es difícil.  Hay que darse cuenta de que es necesario realizar
-- la unión de dos consultas más sencillas: los vuelos directos por una parte
-- y los vuelos con una escala por otra.  La operación de unión de teoría de
-- conjuntos no va a eliminar filas repetidas en las dos consultas porque
-- son conjuntos disjuntos (por la forma de la primera columna).  Es importante
-- darse cuenta de que el número y tipo de las columnas debe coincidir en las dos
-- consultas.

SELECT v0.origen || '--' || v0.destino trayecto, v0.precio
FROM vuelo v0
WHERE precio < 301
UNION
SELECT v1.origen || '--' || v1.destino || '--' || v2.destino trayecto, v1.precio+v2.precio
FROM vuelo v1 JOIN vuelo v2 ON v1.destino =v2.origen
WHERE v1.origen != v2.destino  AND v1.llegada < v2.salida AND v1.precio+v2.precio < 301;

-- -------------------------------------------------------------
-- Ejercicio 2. Consultas sobre el ejercicio de la
-- Librería AllTheBooks.
-- Escribe consultas para proporcionar la siguiente información:

-- 2.a. Lista de los pedidos, con el importe total de cada uno, que
--      contengan más de 4 libros (ejemplares). 

SELECT p.IdPedido, p.FechaPedido, sum(l.PrecioVenta*lp.Cantidad)
FROM Libro l JOIN LIbros_Pedido lp ON l.ISBN = lp.ISBN
JOIN Pedido p ON lp.IdPedido = p.IdPedido
GROUP BY p.IdPedido, p.FechaPedido
HAVING sum(Cantidad) > 4;

-- 2.b. Lista de los autores y el número de clientes distintos
--      que han comprado sus libros, en orden decreciente de 
--      número de clientes.

SELECT a.IdAutor, a.Nombre, count(DISTINCT IdCliente)
FROM Autor a JOIN Autor_Libro al ON a.idautor = al.Autor
JOIN Libros_Pedido lp ON al.ISBN = lp.ISBN
JOIN Pedido p ON lp.IdPedido = p.IdPedido
GROUP BY a.IdAutor, a.Nombre
ORDER BY count(DISTINCT IdCliente) DESC;

