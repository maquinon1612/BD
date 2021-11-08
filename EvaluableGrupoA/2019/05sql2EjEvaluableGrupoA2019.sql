-- -------------------------------------------------------------
-- EJERCICIO EVALUABLE GRUPO A. 29.11.2019. SOLUCIONES.
-- -------------------------------------------------------------

-- Ejecuta este script para crear la base de datos del ejercicio.

-- Esta base de datos contiene información de prescripción de
-- medicamentos a pacientes y alergias a tipos de medicamentos.
-- Contesta a las preguntas que se detallan al final de este fichero
-- mediante sentencias SQL.
--
-- Recuerda que no se puede modificar la estructura de las tablas y no
-- se pueden utilizar vistas.


alter session set nls_date_format = 'DD/MM/YYYY';
SET LINESIZE 500;
SET PAGESIZE 500;

drop table ej_prescripcion cascade constraints;
drop table ej_alergia cascade constraints;
drop table ej_paciente cascade constraints;
drop table ej_medicamento cascade constraints;
drop table ej_tipoMed cascade constraints;


CREATE TABLE ej_tipoMed(
    IdTipo varchar2(20) PRIMARY KEY,
    descripcion varchar2(100) NOT NULL
);

CREATE TABLE ej_medicamento(
    IdMed INTEGER PRIMARY KEY,
    denominacion varchar2(100) NOT NULL,
    tipoMed varchar2(20) NOT NULL REFERENCES ej_tipoMed,
    precioDosis NUMBER(9,2) NOT NULL
    -- precio por cada dosis del medicamento
);

CREATE TABLE ej_paciente(
    IdPaciente INTEGER PRIMARY KEY,
    nombre varchar2(100) NOT NULL
);

CREATE TABLE ej_prescripcion(
    IdPres INTEGER PRIMARY KEY,
    IdPaciente INTEGER NOT NULL REFERENCES ej_paciente,
    IdMed INTEGER NOT NULL REFERENCES ej_medicamento,
    NumDosis INTEGER NOT NULL
    -- numero de dosis prescritas del medicamento al paciente
);

CREATE TABLE ej_alergia(
    IdPaciente INTEGER NOT NULL REFERENCES ej_paciente,
    tipoMed varchar2(20) NOT NULL REFERENCES ej_tipoMed,
    PRIMARY KEY (IdPaciente, tipoMed)
);


INSERT INTO ej_tipoMed VALUES ('penicilinas', 'Antibioticos derivados de la penicilina');
INSERT INTO ej_tipoMed VALUES ('anticonvulsivos', 'Medicamentos anticonvulsivos y derivados');
INSERT INTO ej_tipoMed VALUES ('insulinas', 'Insulinas animales');
INSERT INTO ej_tipoMed VALUES ('yodos', 'Medicamentos para contraste basados en yodo');
INSERT INTO ej_tipoMed VALUES ('sulfas', 'Medicamentos basados en sulfamidas antibacterianas');
INSERT INTO ej_tipoMed VALUES ('otros', 'Resto de medicamentos');

INSERT INTO ej_medicamento VALUES (1, 'sulfametoxazol', 'sulfas', 3.45);
INSERT INTO ej_medicamento VALUES (2, 'sulfadiazina', 'sulfas', 2.10);
INSERT INTO ej_medicamento VALUES (3, 'meticilina', 'penicilinas', 0.87);
INSERT INTO ej_medicamento VALUES (4, 'amoxicilina', 'penicilinas', 0.22);
INSERT INTO ej_medicamento VALUES (5, 'insulina de accion ultrarrapida', 'insulinas', 0.82);
INSERT INTO ej_medicamento VALUES (6, 'insulina de accion rapida', 'insulinas', 0.55);
INSERT INTO ej_medicamento VALUES (7, 'yoduro potasico', 'yodos', 0.30);
INSERT INTO ej_medicamento VALUES (8, 'acido acetilsalicilico', 'otros', 0.05);

insert into ej_paciente values (101,'Margarita Sanchez');
insert into ej_paciente values (102,'Angel Garcia');
insert into ej_paciente values (103,'Pedro Santillana');
insert into ej_paciente values (104,'Rosa Prieto');
insert into ej_paciente values (105,'Ambrosio Perez');
insert into ej_paciente values (106,'Lola Arribas');

INSERT INTO ej_prescripcion VALUES (201,101,1,12);
INSERT INTO ej_prescripcion VALUES (202,101,3,24);
INSERT INTO ej_prescripcion VALUES (203,101,3,48);
INSERT INTO ej_prescripcion VALUES (204,101,7,8);
INSERT INTO ej_prescripcion VALUES (205,102,7,14);
INSERT INTO ej_prescripcion VALUES (206,103,3,24);
INSERT INTO ej_prescripcion VALUES (207,103,4,36);
INSERT INTO ej_prescripcion VALUES (208,103,7,14);
INSERT INTO ej_prescripcion VALUES (209,104,7,8);
INSERT INTO ej_prescripcion VALUES (210,105,7,4);
INSERT INTO ej_prescripcion VALUES (211,106,7,2);

INSERT INTO ej_alergia VALUES (101,'penicilinas');
INSERT INTO ej_alergia VALUES (104,'yodos');
INSERT INTO ej_alergia VALUES (106,'penicilinas');

COMMIT;



-- -----------------------------------------------------------------
-- 1. Lista de pacientes que incluya id, nombre del paciente y el
-- gasto total en medicamentos de tipo 'penicilinas' de aquellos
-- pacientes que toman al menos dos medicamentos distintos *entre sí
-- de tipo penicilina.*

SELECT p.idPaciente, p.nombre, SUM(r.numDosis*m.precioDosis)
FROM ej_paciente p
JOIN ej_prescripcion r ON p.idPaciente = r.idPaciente
JOIN ej_medicamento m ON m.idMed = r.idMed
WHERE m.tipoMed = 'penicilinas'
GROUP BY p.idPaciente, p.nombre
HAVING COUNT(DISTINCT r.idMed) >= 2;

-- -----------------------------------------------------------------
-- 2. Lista de todos los medicamentos (id, denominación) y el número
-- de pacientes con alergia a cada medicamento.  Si para un
-- medicamento no hay pacientes que sean alérgicos, debe mostrar un 0.

SELECT m.idMed, m.denominacion, NVL(COUNT(a.tipoMed), 0)
FROM ej_medicamento m
LEFT JOIN ej_alergia a ON m.tipoMed = a.tipoMed
GROUP BY m.idMed, m.denominacion;

-- Solución con subconsulta en LEFT JOIN:
SELECT m.idMed, m.denominacion, NVL(n.numPacientes, 0)
FROM ej_medicamento m
LEFT JOIN 
     (SELECT a.tipoMed, COUNT(a.tipoMed) numPacientes FROM ej_alergia a
      GROUP BY a.tipoMed) n
ON m.tipoMed = n.tipoMed;

-- Solución con INNER JOIN + UNION
SELECT m.idMed, m.denominacion, COUNT(*)
FROM ej_medicamento m
JOIN ej_alergia a ON m.tipoMed = a.tipoMed
GROUP BY m.idMed, m.denominacion
UNION ALL
SELECT m2.idMed, m2.denominacion, 0
FROM ej_medicamento m2
WHERE m2.tipoMed NOT IN 
  (SELECT a2.tipoMed FROM ej_alergia a2);


-- -----------------------------------------------------------------
-- 3. Lista de los pacientes (id, nombre) que no son alérgicos a
-- ninguno de los medicamentos que se les han prescrito.

SELECT p.idPaciente, p.nombre
FROM ej_paciente p
WHERE p.idPaciente NOT IN 
  (SELECT r2.idPaciente
   FROM ej_prescripcion r2
   JOIN ej_medicamento m2 ON r2.idMed = m2.idMed
   WHERE m2.tipoMed IN
     (SELECT a3.tipoMed
      FROM ej_alergia a3
      WHERE a3.idPaciente = r2.idPaciente));
      -- CONSULTA CORRELACIONADA

-- -----------------------------------------------------------------
-- 4. Lista de los tipos de medicamentos (tipo, descripción) que
-- tienen más casos de alergias. El resultado debe incluir el 
-- número de casos de alergias.

SELECT t.idTipo, t.descripcion, COUNT(*)
FROM ej_tipoMed t
JOIN ej_alergia a ON t.idTipo = a.tipoMed
GROUP BY t.idTipo, t.descripcion
HAVING COUNT(*) >= ALL
       (SELECT COUNT(*) FROM ej_alergia a2 GROUP BY a2.tipoMed);

-- -----------------------------------------------------------------
-- 5. Lista de medicamentos (id, denominación) que han sido prescritos
-- a todos los pacientes.

-- Solución comparando cardinalidades:
SELECT m.idMed, m.denominacion
FROM ej_medicamento m
JOIN ej_prescripcion r ON m.idMed = r.idMed
GROUP BY m.idMed, m.denominacion
HAVING COUNT(DISTINCT r.idPaciente) =
       (SELECT COUNT(*) FROM ej_paciente);

-- Solución por doble negación:
SELECT m.idMed, m.denominacion
FROM ej_medicamento m
WHERE NOT EXISTS
  (SELECT p2.idPaciente 
   FROM ej_paciente p2
   WHERE p2.idPaciente NOT IN
     (SELECT r3.idPaciente
      FROM ej_prescripcion r3
      WHERE r3.idMed = m.idMed));
      -- CONSULTA CORRELACIONADA

-- -----------------------------------------------------------------
-- 6. Lista de los pacientes (id, nombre) que solamente tienen alergia
-- a las penicilinas.

SELECT p.idPaciente, p.Nombre
FROM ej_paciente p
JOIN ej_alergia a ON p.idPaciente = a.idPaciente
WHERE a.tipoMed = 'penicilinas'
AND p.idPaciente NOT IN
    (SELECT a2.idPaciente
     FROM ej_alergia a2
     WHERE a2.tipoMed != 'penicilinas');


