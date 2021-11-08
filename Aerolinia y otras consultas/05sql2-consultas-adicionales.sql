-- -----------------------------------------------
-- 05sql2 Consultas adicionales resueltas en clase
-- -----------------------------------------------

-- T30 - Funciones de agregacion - Consultas adicionales:
-- 1. Número de empleados del departamento SMP.
SELECT COUNT(*) FROM Emp WHERE CodDp = 'SMP';

-- 2. Número total de jornadas asignadas a proyectos.
SELECT  SUM(Horas/8) FROM distribucion;

-- 3. Número total de horas y número de empleados asignados al
--    proyecto 'Ventas'.
SELECT  SUM(Horas), COUNT(*)
FROM distribucion JOIN proyecto USING (CodPr)
WHERE Descr = 'Ventas';

-- 4. Número de departamentos implicados en el proyecto 'Ventas'.
SELECT  COUNT(DISTINCT CodDp)
FROM distribucion JOIN emp USING (DNI)
JOIN proyecto USING (CodPr)
WHERE Descr = 'Sales';

-- --------------------------------------------------------------
-- T34 - GROUP BY - Consultas adicionales:
-- 1. Nombre de cada departamento y su número de empleados.
SELECT d.Nombre, COUNT(*)
FROM dpto d JOIN Emp e ON d.CodDp = e.CodDp
GROUP BY d.Nombre;

-- 2. Proyectos dirigidos por '37562365F' y horas totales asignadas a
--    cada proyecto.
SELECT p.CodPr, p.Descr, SUM(d.Horas)
FROM proyecto p JOIN distribucion d ON p.CodPr = d.CodPr
WHERE p.DNIDir = '37562365F'
GROUP BY p.CodPr, p.Descr;

-- 3. Proyectos dirigidos por '37562365F' y número de 
--    empleados asignados a cada proyecto de los proyectos con más de
--    50 horas asignadas.
SELECT p.CodPr, p.Descr, COUNT(*)
FROM proyecto p JOIN distribucion d ON p.CodPr = d.CodPr
WHERE p.DNIDir = '37562365F'
GROUP BY p.CodPr, p.Descr
HAVING SUM(d.Horas) > 50;

-- 4. Empleados asignados a un solo proyecto.
SELECT e.DNI, e.Nombre
FROM emp e JOIN distribucion d ON e.DNI = d.DNI
GROUP BY e.DNI, e.Nombre
HAVING COUNT(*) = 1;

-- 5. Nombre y DNI de los empleados asignados a menos de dos
--    proyectos
SELECT e.DNI, e.Nombre
FROM emp e JOIN distribucion d ON e.DNI = d.DNI
GROUP BY e.DNI, e.Nombre
HAVING COUNT(*) < 2;  -- INCORRECTO!!: los no asignados a ningún proyecto NO APARECEN

-- Solucion con diferencia de conjuntos:
SELECT DNI, Nombre FROM emp
MINUS
SELECT e.DNI, e.Nombre
FROM emp e LEFT JOIN distribucion d ON e.DNI = d.DNI
GROUP BY e.DNI, e.Nombre
HAVING COUNT(*) >= 2;

-- Solucion con subconsulta:
SELECT DNI, Nombre FROM emp
WHERE DNI NOT IN (
      SELECT e.DNI
      FROM emp e LEFT JOIN distribucion d ON e.DNI = d.DNI
      GROUP BY e.DNI
      HAVING COUNT(*) >= 2);

-- --------------------------------------------------------------
-- T36/T38 - Consultas anidadas - Consultas adicionales:
-- 1. Nombre de aquellos empleados que no trabajan en ningún
--    proyecto en el que trabaja 'María Puente'.
SELECT e.DNI, e.Nombre
FROM Emp e
WHERE e.DNI NOT IN
      (SELECT d.DNI FROM Distribucion d
       WHERE d.CodPr IN
       	     (SELECT d2.CodPr
	      FROM Distribucion d2 JOIN Emp e2 ON e2.DNI = d2.DNI
      	      WHERE e2.Nombre = 'Maria Puente'));

-- Otra solución:
SELECT e.DNI, e.Nombre
FROM Emp e
WHERE e.DNI NOT IN
      (SELECT d.DNI
      FROM Distribucion d
      JOIN Distribucion d2 ON d2.CodPr = d.CodPr
      JOIN Emp e2 ON e2.DNI = d2.DNI
      WHERE e2.Nombre = 'Maria Puente');

-- 2. Empleados que trabajan en el mayor número
--    de proyectos en cada departamento:
--    (CONSULTA CORRELACIONADA)
SELECT e.DNI, e.Nombre, e.CodDp, COUNT(*)
FROM Emp e JOIN Distribucion d on e.dni = d.dni
GROUP BY e.DNI, e.Nombre, e.CodDp
HAVING COUNT(*) >= ALL (
       SELECT COUNT(*)
       FROM Emp e2 JOIN Distribucion d2 on e2.dni = d2.dni
       WHERE e2.CodDp = e.CodDp
       GROUP BY e2.DNI);

-- --------------------------------------------------------------
-- T29 - LEFT OUTER JOIN - Consultas adicionales:
-- 1. Nombre de todos los empleados y código de los proyectos
--    en los que trabajan, o '(sin proyecto)' si no trabajan en
--    ningún proyecto. 
SELECT e.DNI, e.Nombre, NVL(d.CodPr, '(sin proyecto)')
FROM Emp e LEFT JOIN Distribucion d on e.dni = d.dni;

-- 2. Nombre de todos los empleados y número total de horas de los
--    proyectos en los que trabajan, o 0 si no trabajan en ningún
--    proyecto.
SELECT e.Nombre, nvl(sum(d.horas),0)
FROM emp e LEFT JOIN distribucion d ON e.DNI = d.DNI
GROUP BY e.DNI, e.Nombre;

-- Solucion alternativa con subconsulta en FROM

SELECT e.DNI, e.Nombre, NVL(acum.NumHoras, 0)
FROM Emp e
LEFT JOIN (SELECT d.dni, SUM(d.Horas) NumHoras FROM Distribucion d
     	   GROUP BY d.dni) acum
ON e.dni = acum.dni;

-- 3. Nombre y DNI de los empleados asignados a menos de dos
--    proyectos
--    (solución con reunión externa)
SELECT e.DNI, e.Nombre
FROM emp e LEFT JOIN distribucion d ON e.DNI = d.DNI
GROUP BY e.DNI, e.Nombre
HAVING COUNT(CodPr) < 2;




