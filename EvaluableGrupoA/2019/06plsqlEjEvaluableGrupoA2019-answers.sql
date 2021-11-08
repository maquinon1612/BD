-- -------------------------------------------------------------
-- EJERCICIO EVALUABLE PLSQL+triggers GRUPO A. 19.12.2019. SOLUCION
-- -------------------------------------------------------------
-- Alumno 1: Mario Quiñones Pérez
-- -------------------------------------------------------------

-- Ejecuta este script para crear la base de datos del ejercicio.

-- Esta base de datos contiene información de prescripción de
-- medicamentos a pacientes y alergias a tipos de medicamentos.
-- Contesta a las preguntas que se detallan al final de este fichero
-- mediante sentencias SQL a continuación de cada bloque de
-- comentarios.

SET SERVEROUTPUT ON;
alter session set nls_date_format = 'DD/MM/YYYY';
SET LINESIZE 500;
SET PAGESIZE 500;

drop table ej_estadisticas cascade constraints;
drop table ej_prescripcion cascade constraints;
drop table ej_alergia cascade constraints;
drop table ej_paciente cascade constraints;
drop table ej_medicamento cascade constraints;
drop table ej_tipoMed cascade constraints;

-- Tipos de medicamentos.
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
    nombre varchar2(100) NOT NULL,
    fecNacim DATE,
    descuento NUMBER(5,2)
);

-- Prescripción de medicamentos a pacientes.
CREATE TABLE ej_prescripcion(
    IdPres INTEGER PRIMARY KEY,
    IdPaciente INTEGER NOT NULL REFERENCES ej_paciente,
    IdMed INTEGER NOT NULL REFERENCES ej_medicamento,
    NumDosis INTEGER NOT NULL,  -- numero de dosis prescritas del medicamento al paciente
    alertaAlergia INTEGER
);

-- Alergias diagnosticadas de tipos de medicamento a pacientes.
CREATE TABLE ej_alergia(
    IdPaciente INTEGER NOT NULL REFERENCES ej_paciente,
    tipoMed varchar2(20) NOT NULL REFERENCES ej_tipoMed,
    PRIMARY KEY (IdPaciente, tipoMed)
);

-- Informacion estadistica sobre medicamentos: numero de pacientes alergicos.
CREATE TABLE ej_estadisticas(
    IdMed INTEGER NOT NULL REFERENCES ej_medicamento,
    numPacientes INTEGER -- numero de pacientes alergicos.
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
INSERT INTO ej_medicamento VALUES (9, 'cloxacilina', 'penicilinas', 0.99);
 
insert into ej_paciente values (101,'Margarita Sanchez', TO_DATE('17/02/2001'), 0.0);
insert into ej_paciente values (102,'Angel Garcia', TO_DATE('24/09/1985'), 35.0);
insert into ej_paciente values (103,'Pedro Santillana', TO_DATE('28/02/1951'), 60.0);
insert into ej_paciente values (104,'Rosa Prieto', TO_DATE('5/12/2005'), 15.0);
insert into ej_paciente values (105,'Ambrosio Perez', TO_DATE('22/01/1951'), 60.0);
insert into ej_paciente values (106,'Lola Arribas', TO_DATE('14/12/1977'), 20.0);

INSERT INTO ej_prescripcion VALUES (201,101,1,12, 0);
INSERT INTO ej_prescripcion VALUES (202,101,3,24, 0);
INSERT INTO ej_prescripcion VALUES (203,101,4,48, 0);
INSERT INTO ej_prescripcion VALUES (204,101,7,8, 0);
INSERT INTO ej_prescripcion VALUES (205,102,4,14, 0);
INSERT INTO ej_prescripcion VALUES (206,103,3,24, 0);
INSERT INTO ej_prescripcion VALUES (208,103,7,14, 0);
INSERT INTO ej_prescripcion VALUES (209,104,7,8, 0);
INSERT INTO ej_prescripcion VALUES (210,106,7,12, 0);

INSERT INTO ej_alergia VALUES (101, 'penicilinas');
INSERT INTO ej_alergia VALUES (104, 'yodos');
INSERT INTO ej_alergia VALUES (105, 'penicilinas');
INSERT INTO ej_alergia VALUES (106, 'penicilinas');
INSERT INTO ej_alergia VALUES (103, 'penicilinas');

INSERT INTO ej_estadisticas SELECT IdMed, 0 FROM ej_medicamento;

COMMIT;


-- -----------------------------------------------------------------
-- 1. Escribe un procedimiento almacenado llamado mostrarMedicamentos
-- que reciba como parámetro un tipo de medicamento y muestre por la
-- consola todos los medicamentos de ese tipo (id, descripción y gasto
-- total de ese medicamento --coste de todas las dosis prescritas
-- de ese medicamento, sin aplicar descuentos).
--
-- Si el tipo de medicamento no existe en la base de datos debe
-- mostrar un mensaje de error y terminar.
-- 
-- Por cada medicamento, debe mostrar la lista de pacientes a los que
-- se ha prescrito ese medicamento (id, nombre, edad, gasto total 
-- antes y después de aplicar descuento). Para calcular la edad puedes
-- utilizar alguna de las funciones de fecha que hemos visto en clase
-- (por ejemplo, ADD_MONTHS o MONTHS_BETWEEN).  Si un medicamento no
-- ha sido prescrito a ningún paciente, debe mostrar el mensaje 'No
-- prescrito'.
--
-- Por cada medicamento mostrado, el procedimiento debe actualizar la
-- estadística de pacientes alérgicos en la base de datos
-- (ej_estadisticas), actualizando la columna numPacientes con el
-- número de pacientes alérgicos a ese medicamento.

CREATE OR REPLACE PROCEDURE mostrarMedicamentos (p_tipo ej_tipoMed.IdTipo%TYPE) IS
  v_med ej_medicamento.IdMed%TYPE;
  v_Destipo ej_tipoMed.descripcion%TYPE;
  v_numPacientes INTEGER;

  CURSOR cr_med IS
    SELECT m.IdMed, m.denominacion, NVL(SUM(m.precioDosis * r.numDosis),0) gastoTotal
    FROM ej_medicamento m LEFT JOIN ej_prescripcion r ON m.IdMed = r.IdMed
    WHERE m.tipoMed = p_tipo
    GROUP BY m.IdMed, m.denominacion
    ORDER BY m.IdMed;

  CURSOR cr_paciente IS
    SELECT p.IdPaciente, p.nombre, TRUNC(MONTHS_BETWEEN(SYSDATE,p.fecNacim)/12,0) edad,
           m.precioDosis*r.numDosis gasto, m.precioDosis*r.numDosis*(100-p.descuento)/100 dto
    FROM ej_paciente p
    JOIN ej_prescripcion r ON r.IdPaciente = p.IdPaciente
    JOIN ej_medicamento m ON r.IdMed = m.IdMed
    WHERE r.IdMed = v_med;

BEGIN
  SELECT descripcion INTO v_Destipo FROM ej_tipoMed WHERE IdTipo = p_tipo;

  FOR r_med IN cr_med LOOP
    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE('Medicamento: ' || r_med.IdMed || ' - ' || r_med.denominacion); 
    DBMS_OUTPUT.PUT_LINE('Gasto total: ' || TO_CHAR(r_med.gastoTotal, '99G999G990D99') || ' euros.');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------');
    v_numPacientes := 0;
    v_med := r_med.IdMed;
    FOR r_paciente IN cr_paciente LOOP
      IF v_numPacientes = 0 THEN
        DBMS_OUTPUT.PUT_LINE(' Paciente                             Edad   Gasto   Dto. ');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------');
      END IF;
      DBMS_OUTPUT.PUT_LINE(TO_CHAR(r_paciente.IdPaciente,'9999') || ' ' || RPAD(r_paciente.nombre,30) ||
                           TO_CHAR(r_paciente.edad,'9999') || '  ' || TO_CHAR(r_paciente.gasto,'990D99') ||
                           TO_CHAR(r_paciente.dto,'990D99'));
      v_numPacientes := v_numPacientes + 1;
    END LOOP;

    IF v_numPacientes = 0 THEN
      DBMS_OUTPUT.PUT_LINE('No prescrito');
    END IF;

    UPDATE ej_estadisticas SET numPacientes = 
      (SELECT COUNT(DISTINCT r.IdPaciente) 
      FROM ej_prescripcion r
      JOIN ej_medicamento m ON r.IdMed = m.IdMed
      JOIN ej_alergia a  ON m.tipoMed = a.tipoMed AND r.IdPaciente = a.IdPaciente
      WHERE r.IdMed = v_med)
    WHERE IdMed = v_med;
    -- Esta sentencia UPDATE incluye una subconsulta en la cláusula SET.
    -- Tenemos que estar seguros de que la subconsulta produce una sola fila
    -- para que no se produzca un error.
    -- También se puede programar como una sentencia SELECT INTO
    -- separada y una sentencia UPDATE sin subconsulta.
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('==========================================================');

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: Tipo de medicamento no encontrado'); 
END;
/

-- Prueba del procedimiento almacenado.
SET SERVEROUTPUT ON;
BEGIN
  mostrarMedicamentos('penicilinas');
END;
/
SELECT * FROM ej_estadisticas;

-- -----------------------------------------------------------------
-- 2. Añade una columna importeTotalDescuentos a la tabla ex_medicamento
-- con la siguiente sentencia DDL:
-- 
-- ALTER TABLE ej_medicamento ADD importeTotalDescuentos NUMBER(9,2) DEFAULT 0;
--
-- Esta columna debe contener el importe total de los descuentos
-- aplicados por cada paciente (precioDosis * numDosis * descuento / 100)
-- 
-- Escribe un disparador que mantenga actualizada la columna
-- importeTotalDescuentos ante cualquier cambio en la prescripcion de
-- medicaciones de un paciente. Además, si el paciente es alérgico al
-- medicamento prescrito, debe asignar un 1 en la columna
-- alertaAlergia.
--
-- Podemos suponer que el total de dosis prescritas es consistente con
-- la información de la base de datos antes del cambio que lanza el
-- disparador.

ALTER TABLE ej_medicamento ADD importeTotalDescuentos NUMBER(9,2) DEFAULT 0;

CREATE OR REPLACE TRIGGER actualizaTotalDescuentos
BEFORE INSERT OR UPDATE OR DELETE ON ej_prescripcion
FOR EACH ROW
DECLARE
  v_importe NUMBER(9,2);
  v_alergia INTEGER;
BEGIN
  IF INSERTING OR UPDATING THEN
    SELECT precioDosis * :NEW.numDosis * descuento / 100 INTO v_importe
    FROM ej_medicamento, ej_paciente WHERE IdMed = :NEW.IdMed AND IdPaciente = :NEW.IdPaciente;
    
    UPDATE ej_medicamento SET importeTotalDescuentos = importeTotalDescuentos + v_importe
    WHERE IdMed = :NEW.IdMed;
  END IF;
  IF DELETING OR UPDATING THEN
    SELECT precioDosis * :OLD.numDosis * descuento / 100 INTO v_importe
    FROM ej_medicamento, ej_paciente WHERE IdMed = :OLD.IdMed AND IdPaciente = :OLD.IdPaciente;
    
    UPDATE ej_medicamento SET importeTotalDescuentos = importeTotalDescuentos - v_importe
    WHERE IdMed = :OLD.IdMed;
  END IF;
  
  IF INSERTING OR UPDATING THEN
    SELECT COUNT(*) INTO v_alergia 
    FROM ej_alergia a JOIN ej_medicamento m ON a.tipoMed = m.tipoMed
    WHERE IdPaciente = :NEW.IdPaciente AND IdMed = :NEW.IdMed;
    IF v_alergia > 0 THEN
      :NEW.alertaAlergia := 1;
    ELSE
      :NEW.alertaAlergia := 0;
    END IF;
  END IF;
END;
/

-- Pruebas del disparador:
select * from ej_medicamento;
INSERT INTO ej_prescripcion VALUES (299,103,3,24, 0);
select * from ej_prescripcion;
select * from ej_medicamento;
UPDATE ej_prescripcion SET IdPaciente = 102 WHERE IdPres = 299;
select * from ej_prescripcion;
select * from ej_medicamento;
DELETE FROM ej_prescripcion WHERE IdPres = 299;
select * from ej_prescripcion;
select * from ej_medicamento;


