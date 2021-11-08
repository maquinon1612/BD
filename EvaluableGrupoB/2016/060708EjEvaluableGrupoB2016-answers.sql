SET SERVEROUTPUT ON;

-- ----------------------------------------------------
-- APARTADO 0
-- ----------------------------------------------------

-- Primero eliminamos el trigger si se ha creado antes.
DROP TRIGGER mdf_Libros_Pedido;

-- Antes de continuar debe ejecutarse el Script Libreria.sql

DROP TABLE Existencias CASCADE CONSTRAINTS;
CREATE TABLE Existencias (
  ISBN CHAR(15) PRIMARY KEY,
  Stock NUMBER(6) NOT NULL,
  StockMin NUMBER(6) NOT NULL
);

INSERT INTO Existencias SELECT l.ISBN, 10-SUM(Cantidad), 5
FROM Libro l JOIN Libros_Pedido lp ON lp.ISBN = l.ISBN
GROUP BY l.ISBN;

SELECT * FROM Existencias;

-- ----------------------------------------------------
-- APARTADO 1
-- ----------------------------------------------------

CREATE OR REPLACE TRIGGER mdf_Libros_Pedido 
AFTER INSERT OR UPDATE OR DELETE ON Libros_Pedido
FOR EACH ROW
DECLARE
  v_Stock Existencias.Stock%TYPE;
  v_ISBN Existencias.ISBN%TYPE;
BEGIN
  IF DELETING THEN
    v_ISBN := :OLD.ISBN;
    UPDATE Existencias SET Stock = Stock + :OLD.Cantidad 
    WHERE ISBN = v_ISBN;
  ELSIF INSERTING THEN
    v_ISBN := :NEW.ISBN;
    UPDATE Existencias SET Stock = Stock - :NEW.Cantidad
    WHERE ISBN = v_ISBN;
  ELSIF UPDATING THEN
    v_ISBN := :NEW.ISBN;
    -- Suponemos que no se hacen cambios de ISBN (solo de Cantidad). 
    IF :OLD.Cantidad != :NEW.Cantidad THEN
      UPDATE Existencias SET Stock = Stock + :OLD.Cantidad - :NEW.Cantidad 
      WHERE ISBN = v_ISBN;
    END IF;
  END IF;
  -- Comprobacion de stock negativo.
  SELECT Stock INTO v_Stock FROM Existencias
  WHERE ISBN = v_ISBN;
  IF v_Stock < 0 THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: SIN EXISTENCIAS DEL LIBRO ' || v_ISBN);
  END IF;
EXCEPTION
  WHEN no_data_found THEN
    DBMS_OUTPUT.PUT_LINE('No se ha encontrado el ISBN: ' || v_ISBN);
END;
/

-- Para probar el trigger hay que ver el contenido de la tabla Existencias 
-- antes y después de modificar la tabla Libros_Pedido, en cada una de las
-- operaciones.  Ejecuta las siguientes sentencias paso a paso para ver
-- como se modifican los datos de las tablas.
SELECT * FROM Existencias;
SELECT * FROM Libros_Pedido;

-- Caso de insercion.
INSERT INTO Libros_Pedido VALUES ('1243415243666','0000002P',6);

SELECT * FROM Existencias WHERE ISBN = '1243415243666';

-- Caso de actualizacion.
update libros_pedido set cantidad = 4 
where isbn='8233771378567' and idpedido='0000001P';

SELECT * FROM Existencias WHERE ISBN = '8233771378567';

-- Caso de borrado.
DELETE FROM Libros_Pedido 
WHERE ISBN = '1243415243666' AND idpedido = '0000002P';

SELECT * FROM Existencias WHERE ISBN = '1243415243666';


-- ----------------------------------------------------
-- APARTADO 2
-- ----------------------------------------------------

CREATE OR REPLACE PROCEDURE ListaPedidosUrgentes IS
  CURSOR c_Existencias IS 
    SELECT e.ISBN, l.Titulo, e.StockMin, e.Stock, l.precioCompra
    FROM Existencias e JOIN Libro l ON e.ISBN = l.ISBN;
  v_repo NUMBER(8,0);
  v_impTotal NUMBER(10,2) := 0;  -- Acumula el importe total, asi evitamos
                                 -- una consulta adicional a la BD.
BEGIN
  DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE(rpad('ISBN',16) || rpad('Titulo',36) || 'Num.      Precio');
  DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------');
  FOR r_e IN c_Existencias LOOP
    v_repo := 2*r_e.StockMin - r_e.Stock;
    DBMS_OUTPUT.PUT_LINE(r_e.ISBN || ' ' 
      || rpad(r_e.Titulo,35) || ' ' || to_char(v_repo,'999') || ' ' 
      || to_char(v_repo*r_e.precioCompra,'999G999D99'));

    v_impTotal := v_impTotal + v_repo*r_e.precioCompra;
  END LOOP;
  
  DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('IMPORTE TOTAL PEDIDOS:                                   ' 
    || to_char(v_impTotal,'999G999D99'));
  DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------');
END;
/

-- Para probar el procedimiento, hay que llamarlo desde un bloque anónimo.
BEGIN
  ListaPedidosUrgentes;
END;
/

