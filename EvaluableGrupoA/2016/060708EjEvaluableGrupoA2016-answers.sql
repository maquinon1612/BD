SET SERVEROUTPUT ON;

-- Antes de ejecutar nada de este fichero, ejecuta Script Aerolinea.sql

-- ----------------------------------------------------
-- EJERCICIO 1.
-- ----------------------------------------------------
-- La parte obligatoria de este ejercicio necesita un cursor 
-- para recorrer los aviones que puede realizar un vuelo.

CREATE OR REPLACE PROCEDURE AvionesVuelo1(v_flno IN vuelo.flno%TYPE) IS
  v_distancia vuelo.distancia%TYPE;
  v_avion     avion.aid%TYPE;
  CURSOR c_AvionesVuelo IS
    SELECT a.aid, a.nombre, count(*) numEmp, avg(e.salario) mediaEmp
    FROM avion a 
    JOIN certificado c ON a.aid = c.aid
    JOIN empleado e ON c.eid = e.eid
    WHERE a.autonomia >= v_distancia -- Se utiliza la var. local v_distancia 
                                     -- para seleccionar los aviones con 
                                     -- autonomia suficiente.
    GROUP BY a.aid, a.nombre
    ORDER BY a.aid;
BEGIN
  -- Primero recuperamos en v_distancia la distancia que deben
  -- poder recorrer los aviones seleccionados.
  SELECT vuelo.distancia INTO v_distancia
  FROM vuelo WHERE flno = v_flno;

  DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Aviones para el vuelo ' || v_flno || ' (' || v_distancia || ' millas)');
  DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('AID Modelo de avion                Num.emp.    Salario medio');
  DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------');
  FOR r_av IN c_AvionesVuelo LOOP
    DBMS_OUTPUT.PUT_LINE(to_char(r_av.aid,'99') || ' ' 
      || rpad(r_av.nombre,35) || to_char(r_av.numEmp,'999') || '      ' 
      || to_char(r_av.mediaEmp,'999G999D99'));
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------');
END;
/

-- Para probar el procedimiento utilizamos un bloque anónimo:
BEGIN
  AvionesVuelo1(2);
END;
/

-- EJERCICIO 1. PARTE OPCIONAL.
-- En este caso debemos mostrar los empleados certificados para
-- cada avion.  Hay dos formas de hacerlo, utilizando dos 
-- cursores o solo uno.  Veremos las dos soluciones, aunque la segunda
-- es mucho más eficiente.

-- Primero vamos a utilizar dos cursores para este ejercicio: uno para 
-- los aviones y otro para los empleados certificados para ese 
-- avión.  Se puede observar que el segundo cursor *se ejecuta tantas
-- veces como filas tiene el primer cursor*.

CREATE OR REPLACE PROCEDURE AvionesVuelo2(v_flno IN vuelo.flno%TYPE) IS
  v_distancia vuelo.distancia%TYPE;
  v_avion     avion.aid%TYPE;
  CURSOR c_AvionesVuelo IS
    SELECT a.aid, a.nombre, count(*) numEmp, avg(e.salario) mediaEmp
    FROM avion a 
    JOIN certificado c ON a.aid = c.aid
    JOIN empleado e ON c.eid = e.eid
    WHERE a.autonomia >= v_distancia -- Se utiliza v_distancia para seleccionar
                                     -- los aviones con autonomia suficiente.
    GROUP BY a.aid, a.nombre
    ORDER BY a.aid;
  CURSOR c_EmpleadosAvion IS
    SELECT e.nombre, e.salario
    FROM empleado e JOIN certificado c ON e.eid = c.eid
    WHERE c.aid = v_avion  -- Se utiliza v_avion para seleccionar los
                           -- empleados certificados para un avión.
    ORDER BY e.nombre;
BEGIN
  SELECT vuelo.distancia INTO v_distancia
  FROM vuelo WHERE flno = v_flno;
  DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Aviones para el vuelo ' || v_flno || ' (' || v_distancia || ' millas)');
  DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
  FOR r_av IN c_AvionesVuelo LOOP
    DBMS_OUTPUT.PUT_LINE(to_char(r_av.aid,'99') || ' ' || r_av.nombre);
    v_avion := r_av.aid; -- Por cada avion se debe asignar su valor a esta
                         -- variable para que funcione la consulta del 
                         -- cursor c_EmpleadosAvion.
    FOR r_ea IN c_EmpleadosAvion LOOP
      DBMS_OUTPUT.PUT_LINE('     ' 
        || rpad(r_ea.nombre,30) || '   ' 
        || to_char(r_ea.salario,'999G999D99'));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(to_char(r_av.aid,'99') || ' Num.empleados: ' 
      || to_char(r_av.numEmp,'999') || '  - Sal.medio: ' 
      || to_char(round(r_av.mediaEmp,2),'999G999D99'));
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
  END LOOP;
END;
/

-- Para probar el procedimiento utilizamos un bloque anónimo:
BEGIN
  AvionesVuelo2(2);
END;
/

-- EJERCICIO 1. PARTE OPCIONAL (continuacion).
-- La siguiente versión utiliza un solo cursor, pero los subtotales de cada 
-- avion los debemos calcular en el programa PLSQL (se puede hacer con un
-- cursor adicional solo para los subtotales).

CREATE OR REPLACE PROCEDURE AvionesVuelo3(v_flno IN vuelo.flno%TYPE) IS
  v_distancia vuelo.distancia%TYPE;
  v_avion     avion.aid%TYPE := -1; -- Un valor de AID no valido.
  v_numEmp    NUMBER(10)     := 0;
  v_sumaEmp   NUMBER(10,2)   := 0;
  CURSOR c_EmpleadosAviones IS
    SELECT a.aid, a.nombre nombreAvion, e.nombre nombreEmp, e.salario
    FROM empleado e JOIN certificado c ON e.eid = c.eid
    JOIN avion a ON c.aid = a.aid
    WHERE a.autonomia >= v_distancia -- Se utiliza v_distancia para seleccionar
                                     -- los aviones con autonomia suficiente.
    ORDER BY a.aid, e.nombre;
BEGIN
  SELECT vuelo.distancia INTO v_distancia
  FROM vuelo WHERE flno = v_flno;
  DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Aviones para el vuelo ' || v_flno || ' (' || v_distancia || ' millas)');
  DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
  FOR r_ea IN c_EmpleadosAviones LOOP
    IF r_ea.aid != v_avion THEN
      IF v_avion != -1 THEN
        -- Subtotales del avión anterior.
        DBMS_OUTPUT.PUT_LINE(to_char(v_avion,'99') || ' Num.empleados: ' 
          || to_char(v_numEmp,'999') || '  - Sal.medio: ' 
          || to_char(round(v_sumaEmp/v_numEmp,2),'999G999D99'));
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
      END IF;
      -- Encabezamiento del siguiente avión.
      DBMS_OUTPUT.PUT_LINE(to_char(r_ea.aid,'99') || ' ' || r_ea.nombreAvion);
      v_avion   := r_ea.aid;
      v_numEmp  := 0;
      v_sumaEmp := 0;
    END IF;

    DBMS_OUTPUT.PUT_LINE('     ' 
      || rpad(r_ea.nombreEmp,30) || '   ' || to_char(r_ea.salario,'999G999D99'));
    v_numEmp  := v_numEmp + 1;
    v_sumaEmp := v_sumaEmp + r_ea.salario;
  END LOOP;
  IF v_avion != -1 THEN
    -- Subtotales del ULTIMO avion.
    DBMS_OUTPUT.PUT_LINE(to_char(v_avion,'99') || ' Num.empleados: ' 
      || to_char(v_numEmp,'999') || '  - Sal.medio: ' 
      || to_char(round(v_sumaEmp/v_numEmp,2),'999G999D99'));
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
  END IF;
END;
/

-- Para probar el procedimiento utilizamos un bloque anónimo:
BEGIN
  AvionesVuelo3(2);
END;
/



-- ----------------------------------------------------
-- EJERCICIO 2.
-- ----------------------------------------------------

DROP TABLE incidencias;
CREATE TABLE incidencias (
  fecha DATE NOT NULL,
  usuario VARCHAR2(20) NOT NULL,
  descripcion VARCHAR2(80) NOT NULL
);

-- TRIGGER 1: Incidencia si se incrementa el salario de un empl.

CREATE OR REPLACE TRIGGER mdf_empleado_salario
AFTER UPDATE OF salario ON empleado
FOR EACH ROW
BEGIN
  IF :OLD.salario < :NEW.salario THEN
    INSERT INTO incidencias VALUES (SYSDATE, USER, 
      'Se ha incrementado el salario del empleado ' || :NEW.eid  
      || ' de ' || :OLD.salario || ' a ' || :NEW.salario || '.');
  END IF;
END;
/

-- Para probar el trigger, basta con cambiar un 
-- salario incrementando su valor:
UPDATE empleado SET salario = salario*1.05 WHERE eid = 567354612;

SELECT * FROM Incidencias;

-- TRIGGER 2: Modificaciones de la tabla certificado.

CREATE OR REPLACE TRIGGER mdf_certificado
AFTER INSERT OR DELETE ON certificado
FOR EACH ROW
DECLARE
  v_vuelos NUMBER := 0;
BEGIN
IF INSERTING THEN
  UPDATE empleado SET salario = round(salario * 1.03,2)
  WHERE eid = :NEW.eid;
ELSIF DELETING THEN
  SELECT COUNT(*) INTO v_vuelos
  FROM avion a JOIN vuelo v ON a.autonomia > v.distancia
  WHERE a.aid = :OLD.aid;
  IF v_vuelos > 0 THEN
    INSERT INTO incidencias VALUES (SYSDATE, USER, 
      'El avión ' || :OLD.aid || ' tiene un empleado certificado menos.');
  END IF;
END IF;
END;
/

-- A continuacion probamos los triggers. 
-- Ejecuta las siguientes sentencias paso a paso para ver
-- como se modifican los datos de las tablas.

-- Primero probamos el segundo trigger: vamos a eliminar un certificado
-- de un avion de forma que se genere incidencia:
DELETE FROM certificado WHERE aid = 1 AND eid = 269734834;
SELECT * FROM incidencias;

-- Para probar la combinación de los dos triggers, insertamos un
-- certificado nuevo, que dispara el segundo trigger que incrementa 
-- el salario del empleado.  Esto dispara a su vez el primer trigger.
insert into certificado (eid,aid) values (269734834,16);
select * from incidencias;

-- Si eliminamos de nuevo este certificado, no se genera ninguna
-- fila en Incidencias porque el avion 16 no puede cubrir ningun vuelo.
DELETE FROM certificado WHERE aid = 16 AND eid = 269734834;
select * from incidencias;


