-- -------------------------------------------------------------
-- PLSQL+triggers LAB TEST GROUP I. 17.12.2019
-- -------------------------------------------------------------
-- Student 1: Mario Quiñones Pérez
-- -------------------------------------------------------------

-- Execute this script to create the database for this test.

-- This database contains information about medication prescription to
-- patients and allergies to medication types.  Answer the questions
-- at the end of this file writing PL/SQL and trigger code next to
-- each comment block.

SET SERVEROUTPUT ON;
alter session set nls_date_format = 'DD/MM/YYYY';
SET LINESIZE 500;
SET PAGESIZE 500;

drop table ex_prescription cascade constraints;
drop table ex_allergy cascade constraints;
drop table ex_patient cascade constraints;
drop table ex_medication cascade constraints;
drop table ex_MedType cascade constraints;


-- Types of medications.
CREATE TABLE ex_MedType(
    typeId varchar2(20) PRIMARY KEY,
    description varchar2(100) NOT NULL
);

CREATE TABLE ex_medication(
    medId INTEGER PRIMARY KEY,
    description varchar2(100) NOT NULL,
    medType varchar2(20) NOT NULL REFERENCES ex_MedType,
    pricePerDose NUMBER(9,2) NOT NULL
    -- precio por cada dosis del medication
);

CREATE TABLE ex_patient(
    patientId INTEGER PRIMARY KEY,
    name varchar2(100) NOT NULL,
    birthDate DATE,
    totalExpense NUMBER(9,2),
    allergyRisk INTEGER
);

-- Prescription of medications to patients.
CREATE TABLE ex_prescription(
    presId INTEGER PRIMARY KEY,
    patientId INTEGER NOT NULL REFERENCES ex_patient,
    medId INTEGER NOT NULL REFERENCES ex_medication,
    numDoses INTEGER NOT NULL,  -- Number of prescribed doses
    allergyAlert INTEGER
);

-- Allergies to medication types diagnosed to patients.
CREATE TABLE ex_allergy(
    patientId INTEGER NOT NULL REFERENCES ex_patient,
    medType varchar2(20) NOT NULL REFERENCES ex_MedType,
    PRIMARY KEY (patientId, medType)
);


INSERT INTO ex_MedType VALUES ('penicillins', 'Antibiotics derived from penicillin');
INSERT INTO ex_MedType VALUES ('anticonvulsant', 'Anticonvulsant medications and derivatives');
INSERT INTO ex_MedType VALUES ('insulins', 'Animal insulins');
INSERT INTO ex_MedType VALUES ('iodines', 'Iodine-based contrast mediums');
INSERT INTO ex_MedType VALUES ('sulfas', 'Medications based on antibacterial sulfonamides');
INSERT INTO ex_MedType VALUES ('other', 'Remaining medicines');

INSERT INTO ex_medication VALUES (1, 'sulfamethoxazole', 'sulfas', 3.45);
INSERT INTO ex_medication VALUES (2, 'sulfadiazine', 'sulfas', 2.10);
INSERT INTO ex_medication VALUES (3, 'methicillin', 'penicillins', 0.87);
INSERT INTO ex_medication VALUES (4, 'amoxicillin', 'penicillins', 0.22);
INSERT INTO ex_medication VALUES (5, 'Ultrafast-acting insulin', 'insulins', 0.82);
INSERT INTO ex_medication VALUES (6, 'Fast-acting insulin', 'insulins', 0.55);
INSERT INTO ex_medication VALUES (7, 'potassium iodide', 'iodines', 0.30);
INSERT INTO ex_medication VALUES (8, 'acetylsalicylic acid', 'other', 0.05);

insert into ex_patient values (101,'Margarita Sanchez', TO_DATE('17/02/2001'), 0, 0);
insert into ex_patient values (102,'Angel Garcia', TO_DATE('24/09/1985'), 0, 0);
insert into ex_patient values (103,'Pedro Santillana', TO_DATE('28/02/1951'), 0, 0);
insert into ex_patient values (104,'Rosa Prieto', TO_DATE('5/12/2005'), 0, 0);
insert into ex_patient values (105,'Ambrosio Perez', TO_DATE('22/01/1951'), 0, 0);
insert into ex_patient values (106,'Lola Arribas', TO_DATE('14/12/1977'), 0, 0);

INSERT INTO ex_prescription VALUES (201,101,1,12,0);
INSERT INTO ex_prescription VALUES (202,101,3,24,0);
INSERT INTO ex_prescription VALUES (203,101,3,48,0);
INSERT INTO ex_prescription VALUES (204,101,7,8,0);
INSERT INTO ex_prescription VALUES (205,102,7,14,0);
INSERT INTO ex_prescription VALUES (206,103,3,24,0);
INSERT INTO ex_prescription VALUES (208,103,7,14,0);
INSERT INTO ex_prescription VALUES (209,104,7,8,0);
INSERT INTO ex_prescription VALUES (210,106,7,12,0);

INSERT INTO ex_allergy VALUES (101, 'penicillins');
INSERT INTO ex_allergy VALUES (104, 'iodines');
INSERT INTO ex_allergy VALUES (105, 'penicillins');
INSERT INTO ex_allergy VALUES (106, 'penicillins');
INSERT INTO ex_allergy VALUES (103, 'penicillins');

COMMIT;


-- -----------------------------------------------------------------
-- 1. Write a PLSQL procedure named listPrescriptions that receives a
-- medication type id as a parameter and prints on the console all
-- patients (id and name) allergic to that medication type. For each
-- patient, the procedure must print the medications the patient has
-- been prescribed (presId, medication description, total price for 
-- that medication), or 'No medication prescribed' if no medication 
-- has been prescribed for them.
-- 
-- For each patient listed, the procedure must update the allergyRisk
-- on the database as follows: if the patient is aged less than 20 or
-- over 65, allergyRisk must be set to the number of prescribed
-- medications that the patient is allergic to.  You can use
-- ADD_MONTHS(date, numMonths) to perform calculations on dates.
-- 
-- If the medication type id does not exist, the procedure must detect
-- it and just print an error message on the console and terminate.


CREATE OR REPLACE PROCEDURE listPrescriptions (p_type ex_MedType.typeId%TYPE) IS
  v_pat ex_patient.patientId%TYPE;
  v_typeDescr ex_MedType.description%TYPE;
  v_numMed INTEGER;

  CURSOR cr_pat IS
    SELECT p.patientId, p.name, p.birthDate
    FROM ex_patient p JOIN ex_allergy a ON p.patientId = a.patientId
    WHERE a.medType = p_type;

  CURSOR cr_med IS
    SELECT r.PRESID, m.medType, m.description, r.numDoses*m.pricePerDose totalPrice
    FROM ex_prescription r
    JOIN ex_medication m ON r.medId = m.medId
    WHERE r.patientId = v_pat;

BEGIN
  SELECT description INTO v_typeDescr FROM ex_MedType WHERE typeId = p_type;

  FOR r_pat IN cr_pat LOOP
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Patient: ' || r_pat.patientId || ' - ' || r_pat.name); 
    v_numMed := 0;
    v_pat := r_pat.patientId;
    FOR r_med IN cr_med LOOP
      DBMS_OUTPUT.PUT_LINE(r_med.presId || '-' || RPAD(r_med.description,30) || TO_CHAR(r_med.totalPrice,'99G999D99'));
      v_numMed := v_numMed + 1;
    END LOOP;

    IF v_numMed = 0 THEN
      DBMS_OUTPUT.PUT_LINE('No medication prescribed');
    END IF;

    IF ADD_MONTHS(r_pat.birthDate,20*12) >= SYSDATE
    OR ADD_MONTHS(r_pat.birthDate,65*12) < SYSDATE THEN
      -- the SELECT subquery will always return exactly 1 row.
      UPDATE ex_patient SET allergyRisk = 
        (SELECT COUNT(*) 
        FROM ex_prescription r 
        JOIN ex_medication m ON r.medId = m.medId
        JOIN ex_allergy a  ON m.medType = a.medType AND r.patientId = a.patientId
        WHERE r.patientId = v_pat)
      WHERE patientId = v_pat;
      -- This UPDATE sentence includes a SELECT subquery in the SET
      -- clause.  It can also be programmed as a separated SELECT INTO
      -- sentence and a simpler UPDATE sentence without a subquery.
    END IF;
  END LOOP;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: Medication type not found'); 
END;
/

SET SERVEROUTPUT ON;
UPDATE ex_patient SET allergyRisk=0;
SELECT * FROM ex_patient;
BEGIN
  listPrescriptions('penicillins');
END;
/

-- -----------------------------------------------------------------
-- 2. Write a trigger that updates the total expense of patients on
-- medications when there is any change on the medication prescriptions
-- of a patient.  If the prescribed medicine is of a type that the
-- patient is allergic to, allergyAlert column must be set to 1.
--
-- Let us assume that the total expense before the change is
-- consistent with the database contents.

CREATE OR REPLACE TRIGGER updateExpenses
BEFORE INSERT OR UPDATE OR DELETE ON ex_prescription
FOR EACH ROW
DECLARE
  v_price ex_medication.pricePerDose%TYPE;
  v_allergy INTEGER;
BEGIN
  IF INSERTING THEN
    SELECT pricePerDose INTO v_price FROM ex_medication WHERE medId = :NEW.medId;
    UPDATE ex_patient SET totalExpense = totalExpense + :NEW.numDoses * v_price
    WHERE patientId = :NEW.patientId;
  ELSIF DELETING THEN
    SELECT pricePerDose INTO v_price FROM ex_medication WHERE medId = :OLD.medId;
    UPDATE ex_patient SET totalExpense = totalExpense - :OLD.numDoses * v_price
    WHERE patientId = :OLD.patientId;
  ELSIF UPDATING THEN
    SELECT pricePerDose INTO v_price FROM ex_medication WHERE medId = :OLD.medId;
    UPDATE ex_patient SET totalExpense = totalExpense - :OLD.numDoses * v_price
    WHERE patientId = :OLD.patientId;
      
    SELECT pricePerDose INTO v_price FROM ex_medication WHERE medId = :NEW.medId;
    UPDATE ex_patient SET totalExpense = totalExpense + :NEW.numDoses * v_price
    WHERE patientId = :NEW.patientId;
  END IF;
  
  IF INSERTING OR UPDATING THEN
    SELECT COUNT(*) INTO v_allergy 
    FROM ex_allergy a JOIN ex_medication m ON a.medType = m.medType
    WHERE patientId = :NEW.patientId AND medId = :NEW.medId;
    IF v_allergy > 0 THEN
      :NEW.allergyAlert := 1;
    END IF;
  END IF;
END;
/

