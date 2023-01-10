CREATE TABLE cliente(
	id			numeric(10),
	nome		varchar(50) not null,
	dtNasc		date not null,
	constraint pk_cliente primary key (id)
);

CREATE TABLE genero(
	id			numeric(10),	
	nome		varchar(20) not null, -- campo nome: ação; infantil
	valorDiario	numeric(10,2) not null,
	constraint pk_genero primary key (id)
);

create table jogo(
	id 				numeric(10),
	nome			varchar(100) not null,
	descricao		varchar(500) not null,
	anoLanc			numeric(4) not null,	 
	classificacao	varchar(20) not null check (classificacao in ('livre','infantil','10 ano','18 anos')),  
	situacao		varchar(30) not null check (situacao in ('alugado','disponível')),
	plataforma      varchar(30) not null, 
	genero			numeric(10) not null,
	constraint pk_jogo primary key(id),
	constraint fk_jogo_genero foreign key (genero)  references genero(id)
);

create table locacao(
	id				numeric(10),	
	diarias			integer not null, --campo diarais = quantidade de diarias
	dataLocacao		date not null,
	dataRetorno		date,
	multa			numeric(10,2),	-- R$1,00 por dia de atraso
	situacao		varchar(15) not null check(situacao in('em aberto','finalizado')), 
	total			numeric(10,2),
	jogo		    numeric(10) not null,
	cliente			numeric(10) not null,
	constraint pk_locacao primary key (id),
	constraint fk_locacao_jogo    foreign key (jogo)    references jogo(id),	
	constraint fk_locacao_cliente foreign key (cliente) references cliente(id)
);

--EX1
CREATE SEQUENCE seq_cli;
CREATE SEQUENCE seq_gen;
CREATE SEQUENCE seq_jog;
CREATE SEQUENCE seq_loc;

--EX2
INSERT INTO cliente VALUES(nextval('seq_cli'),'Vinicius', '2004-02-07');
INSERT INTO cliente VALUES(nextval('seq_cli'),'Guilherme', '2004-02-02');
INSERT INTO cliente VALUES(nextval('seq_cli'),'Paloma','2003-12-28');

INSERT INTO genero VALUES(nextval('seq_gen'),'ação',20.00);
INSERT INTO genero VALUES(nextval('seq_gen'),'Aventura', 30.00);
INSERT INTO genero VALUES(nextval('seq_gen'),'Terror', 35.00);

INSERT INTO jogo VALUES(nextval('seq_jog'),'call of duty','jogo de tiro',2018, '10 ano', 'alugado', 'Ps2',
(SELECT id FROM genero WHERE nome='ação'));
INSERT INTO jogo VALUES(nextval('seq_jog'),'TINTIN','jogo de tiro',2018, '18 anos', 'disponível', 'Ps5',
(SELECT id FROM genero WHERE nome='Aventura'));
INSERT INTO jogo VALUES(nextval('seq_jog'),'medo','jogo de tiro',2022, '10 ano', 'alugado', 'Ps4',
(SELECT id FROM genero WHERE nome='Terror'));

INSERT INTO locacao VALUES (nextval('seq_loc'),10, '2022-05-10','2022-05-20',5.00,'finalizado',20.00,
(SELECT id FROM jogo WHERE nome= 'call of duty'), 
(SELECT id FROM cliente WHERE nome= 'Vinicius'));
INSERT INTO locacao VALUES (nextval('seq_loc'),10, '2022-05-12','2022-05-25',5.00,'finalizado',30.00,
(SELECT id FROM jogo WHERE nome= 'TINTIN'), 
(SELECT id FROM cliente WHERE nome= 'Guilherme'));
INSERT INTO locacao VALUES (nextval('seq_loc'),10, '2022-05-10','2022-05-20',5.00,'finalizado',35.00,
(SELECT id FROM jogo WHERE nome= 'medo'), 
(SELECT id FROM cliente WHERE nome= 'Paloma'));

--EX3
CREATE FUNCTION locacao_jog(numeric, integer, date, date, numeric, varchar, numeric, numeric, numeric) RETURNS void AS 
$$
  INSERT INTO locacao VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)
$$ LANGUAGE 'sql';

SELECT * FROM locacao_jog(nextval('seq_loc'), 6,'2022-11-23',NULL,0.00,'em aberto',NULL,
						 (SELECT id FROM jogo WHERE nome = 'call of duty'),
						 (SELECT id FROM cliente WHERE nome = 'Vinicius')
						 );

CREATE FUNCTION devolucao_jog(date, numeric, varchar, numeric, date, numeric) RETURNS void AS 
$$ 
  UPDATE locacao
  SET dataRetorno = $1, multa = $2, situacao = $3, total = $4
  WHERE dataLocacao = $5 AND cliente = $6
$$ LANGUAGE 'sql';

SELECT * FROM devolucao_jog ('2022-09-10', 0.00,'finalizado', 10, '2022-11-23', 1)
SELECT * FROM locacao

--EX4
CREATE VIEW jogos_alugados (jogo, quantidade) AS 
SELECT jogo.nome, count(l.id)
FROM jogo 
INNER JOIN locacao l ON jogo.id = l.jogo
GROUP BY jogo.nome

SELECT * FROM jogos_alugados

--EX5
CREATE SEQUENCE seq_loc_log;

CREATE TABLE locacao_log(
id INTEGER DEFAULT(nextval('seq_loc_log')),
	id_registro INTEGER,
	usuario VARCHAR(50) NOT NULL, 
	data_acao TIMESTAMP,
	acao VARCHAR(10),
	CONSTRAINT pk_loc_log PRIMARY KEY (id)
);

CREATE OR REPLACE FUNCTION loc_log() RETURNS TRIGGER AS 
$$
   BEGIN
        INSERT INTO locacao_log (id_registro, usuario, data_acao, acao) VALUES (OLD.id, current_user, now(),'Delete');
		RETURN OLD;
   END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER delete_log BEFORE DELETE ON locacao FOR EACH ROW EXECUTE PROCEDURE loc_log();

--INSERT--
CREATE SEQUENCE seq_loc_log2;
CREATE TABLE locacao_log2(
id INTEGER DEFAULT(nextval('seq_loc_log2')),
	id_registro INTEGER,
	usuario VARCHAR(50) NOT NULL,
	data_acao TIMESTAMP,
	acao VARCHAR(10),
	CONSTRAINT pk_loc_log2 PRIMARY KEY (id)
);
CREATE OR REPLACE FUNCTION loc_log2() RETURNS TRIGGER AS 
$$
  BEGIN
  INSERT INTO locaco_log2 (id_registro, usuario, data_acao, acao) VALUES (new.id, current_user, now(), 'Insert');
  RETURN NEW;
  END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE TRIGGER insert_log BEFORE INSERT ON locacao FOR EACH ROW EXECUTE PROCEDURE loc_log2();

INSERT INTO locacao VALUES (nextval('seq_loc'), 4, '2022-11-19', '2022-11-22', 1.00, 'finalizado', 0.50, 
						   (SELECT id FROM jogo WHERE nome = 'TINTIN'),
							(SELECT id From cliente WHERE nome = 'Guilherme')
						   );
--UPDATE--
CREATE SEQUENCE seq_loc_log3;
CREATE TABLE loc_log3(
id INTEGER DEFAULT(nextval('seq_loc_log3')),
	id_registro INTEGER, 
	usuario VARCHAR(10) NOT NULL, 
	data_acao TIMESTAMP, 
	acao VARCHAR(10),
	CONSTRAINT pk_loc_log3 PRIMARY KEY (id)
);

CREATE OR REPLACE FUNCTION loc_log3() RETURNS TRIGGER AS 
$$
   BEGIN
   INSERT INTO loc_log3(id_registro, usuario, data_acao, acao) VALUES (new.id, current_user, now(), 'Update');
   RETURN NEW
   END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE TRIGGER insert_log BEFORE UPDATE ON locacao FOR EACH ROW EXECUTE PROCEDURE loc_log3();

UPDATE locacao SET total=20.00 WHERE dataLocacao = '2022-11-23' AND cliente = 1