-- -------------------------------------------------------------
-- SOLUCIONES EXAMEN DE JUNIO 2018. BASES DE DATOS GRUPOS B Y D
-- -------------------------------------------------------------
alter session set nls_date_format = 'DD/MM/YYYY';

drop table noticia cascade constraints;
drop table autor cascade constraints;
drop table periodico cascade constraints;

create table periodico(
    pid integer primary key,
    nombre varchar2(40),
    url varchar2(200)
);

create table autor(
    aid integer primary key,
    nombre varchar2(30),
    seccion varchar2(30)
);

create table noticia(
    nid integer primary key,
    titular varchar2(50),
    resumen varchar2(1000),
    url varchar2(200),
    pid references periodico,
    aid references autor,
    fecha date,
    numVisitas integer
);


INSERT INTO periodico VALUES (1, 'El Noticiero', 'http://www.elnoticiero.es');
INSERT INTO periodico VALUES (2, 'El Diario de Zaragoza', 'http://www.diariozaragoza.es');
INSERT INTO periodico VALUES (3, 'La Gaceta de Guadalajara', 'http://www.gacetaguadalajara.es');

insert into autor values (201,'Margarita Sanchez', 'nacional');
insert into autor values (202,'Angel Garcia', 'internacional');
insert into autor values (203,'Pedro Santillana', 'deportes');
insert into autor values (204,'Rosa Prieto', 'deportes');
insert into autor values (205,'Ambrosio Perez', 'nacional');
insert into autor values (206,'Lola Arribas', 'cultura');

INSERT INTO noticia VALUES (101, 'noticia 101',
       	    	    	   'noticia 101...',
			   'http://www.elnoticiero.es/ibex9000',
			   1,204, TO_DATE('01/06/2018'), 370);
INSERT INTO noticia VALUES (102, 'noticia 102',
       	    	    	   'noticia 102...',
			   'http://www.elnoticiero.es/ibex9000',
			   1,204, TO_DATE('01/06/2018'), 1940);
INSERT INTO noticia VALUES (103, 'noticia 103',
       	    	    	   'noticia 103...',
			   'http://www.gacetaguadalajara.es/nacional24',
			   3,204, TO_DATE('01/06/2018'), 490);
INSERT INTO noticia VALUES (104, 'noticia 104',
       	    	    	   'noticia 104...',
			   'http://www.diariozaragoza.es/deportes33',
			   2,203, TO_DATE('01/06/2018'), 2300);
INSERT INTO noticia VALUES (105, 'noticia 105',
       	    	    	   'noticia 105...',
			   'http://www.diariozaragoza.es/ibex9000',
			   2,202, TO_DATE('01/06/2018'), 2300);

INSERT INTO noticia VALUES (106, 'noticia 106',
       	    	    	   'noticia 106...',
			   'http://www.elnoticiero.es/ibex9001',
			   1,206, TO_DATE('22/06/2018'), 23);
INSERT INTO noticia VALUES (107, 'noticia 107',
       	    	    	   'noticia 107...',
			   'http://www.diariozaragoza.es/nacional22062018',
			   2,205, TO_DATE('22/06/2018'), 23);
INSERT INTO noticia VALUES (108, 'noticia 108',
       	    	    	   'noticia 108...',
			   'http://www.gacetaguadalajara.es/deportes33',
			   3,204, TO_DATE('22/06/2018'), 23);

COMMIT;
