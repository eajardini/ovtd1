-- Cria banco de dados do ERP
CREATE DATABASE ovdt1_erp
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'    
    CONNECTION LIMIT = -1;
    
ALTER DATABASE ovdt1_erp SET datestyle TO 'SQL, DMY';
    
-- Cria banco de dados do DW
CREATE DATABASE ovdt1_dw
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'    
    CONNECTION LIMIT = -1;

ALTER DATABASE ovdt1_dw SET datestyle TO 'SQL, DMY';

-- Passo ERP1 - Criação das tabelas

-- Tabela Cliente 
create table cliente (
codigo_cliente bigserial not null,
nome_cliente varchar(40),
endereco varchar(40),
cidade varchar(20),
cep varchar(9),
uf char(2),
cnpj varchar(20),
ie varchar(20));

alter table cliente add constraint pk_cliente primary key (codigo_cliente);

-- Tabela vendedor 
create table vendedor (
codigo_vendedor bigserial not null,
nome_vendedor varchar(40) not null,
salario_fixo numeric(7,2),
faixa_comissao char(1),
senha varchar(50));

alter table vendedor add constraint pk_vendedor primary key (codigo_vendedor);


-- Tabela pedido
--Note: Uma vez que a tabela pedido faz referencia as tabelas CLIENTE e
--VENDEDOR, eu a
--criei depois de criar as tabelas referenciadas 
 

create table pedido(
num_pedido bigserial not null,
prazo_entrega numeric(3) not null,
codigo_cliente bigint not null,
codigo_vendedor bigint not null,
total_pedido    numeric(10,2),
data_pedido date );

alter table pedido add constraint pk_pedido primary key (num_pedido);

alter table pedido add constraint fk_pedido_cliente foreign key
(codigo_cliente)
                                              references cliente; 

alter table pedido add constraint fk_pedido_vendedor foreign key
(codigo_vendedor)
                                              references vendedor; 


                                              
--Tabela produto 
create table produto (
codigo_produto bigserial not null,
unidade char(3),
descricao varchar(30),
valor_venda  numeric(7,2),
valor_custo numeric(7,2),
qtde_minima numeric(5,2),
quantidade numeric (5,2),
comissao_produto numeric(5,3)
);

alter table produto add constraint pk_produto primary key (codigo_produto);



-- Tabela Item_Pedido
--Note: mesmo caso da tabela pedido 
 

create table item_pedido (
num_pedido bigint not null,
codigo_produto bigint not null,
quantidade numeric(3),
valor_venda numeric(7,2),
valor_custo numeric(7,2));

alter table item_pedido add constraint pk_item_pedido primary key
(num_pedido,codigo_produto);

alter table item_pedido add constraint fk_item_ped_pedi foreign key
(num_pedido)
                                              references pedido;
alter table item_pedido add constraint fk_item_ped_prod foreign key
(codigo_produto)
                                              references produto;


-- Fim das tabelas 

--Passo ERP2 - Inserido dados na tabela cliente




-- Configura valor para as sequencias
-- SELECT setval('cliente_codigo_cliente_seq', 999);
-- SELECT setval('pedido_num_pedido_seq',999);
-- SELECT setval('produto_codigo_produto_seq',999);
-- SELECT setval('vendedor_codigo_vendedor_seq',999);

----------------------------------------------------------
-- Passo ERP3 - Cria fake data nas tabelas

-- Fake data cliente
WITH uf_list AS (
    SELECT '{SP, MG, SP, RJ, SP, MG, PA}'::char(2)[] listaUF
)
insert into cliente
SELECT c, 'cliente'||c, 'Rua'||c, 'cidade'||c, 'cep'||c, 
       listaUF[1 + mod(c, array_length(listaUF, 1))], 'cnpj'||c,
	   'ie'||c
FROM uf_list, generate_series(1000,5000) c
--limit 10
;


--  - fake data vendedor
WITH salario_list AS (
    SELECT '{2500, 2800, 3200, 3900,7000, 8000}'::int[] listaSalario
), faixaSalario_list AS (
    SELECT '{C, C, B, B, A, A}'::char(1)[] listaFaixaSalario
)
insert into vendedor
SELECT v, 'vendedor'||v, 
       listaSalario[1 + mod(v, array_length(listaSalario, 1))], 
	   listaFaixaSalario[1 + mod(v, array_length(listaFaixaSalario, 1))]	   
FROM salario_list, faixaSalario_list, generate_series(1010,1300) v
--limit 10
;

-- fake data produto

WITH unidade_list AS (
    SELECT '{L, M, MM, K, PC}'::varchar(2)[] listaUnidade
), valorVenda_list AS (
    SELECT '{50, 100, 200, 340, 780, 1300}'::int[] listaValorVenda
) , valorCusto_list AS (
    SELECT '{40, 80, 200, 315, 705, 1175}'::int[] listaValorCusto
) , qtdMinima_list AS (
    SELECT '{10, 20, 50, 200, 400, 800}'::int[] listaQtdMinima
) , qtdEstoque_list AS (
    SELECT '{15, 20, 30, 150, 380, 200}'::int[] listaQtdEstoque
)
insert into produto
SELECT p,         
       listaUnidade[1 + mod(p, array_length(listaUnidade, 1))], 
	   'produto'||p, 
	   listaValorVenda[1 + mod(p, array_length(listaValorVenda, 1))],	
	   listaValorCusto[1 + mod(p, array_length(listaValorCusto, 1))],
	   listaQtdMinima[1 + mod(p, array_length(listaQtdMinima, 1))],	   
	   listaQtdEstoque[1 + mod(p, array_length(listaQtdEstoque, 1))]	 
FROM unidade_list, valorVenda_list, valorCusto_list, qtdMinima_list, 
     qtdEstoque_list, generate_series(1000,8000) p
--limit 10
;

-- fake data pedido
WITH prazoEntrega_list AS (    
    SELECT '{50, 10, 20, 4, 7, 13}'::int[] listaprazoEntrega
) , codCliente_list AS (
    SELECT array(select codigo_Cliente from cliente)::bigint[] listaCodCliente
) , codVendedor_list AS (
    SELECT array(select codigo_Vendedor from vendedor)::bigint[] listaCodVendedor
),  totalPedido_list AS (
    SELECT '{150, 2000, 3040, 1560, 7000, 2000}'::int[] listaTotalPedido
),  dataPedido_list AS (
    SELECT '{30/04/2020, 20/04/2020, 10/05/2021 , 10/06/2021, 
	         05/09/2022, 25/09/2022, 03/11/2022, 23/03/2021}'::date[] listaDataPedido
) 
insert into pedido
SELECT ped,         
       listaprazoEntrega[1 + mod(ped, array_length(listaprazoEntrega, 1))], 	   
	   listaCodCliente[1 + mod(ped, array_length(listaCodCliente, 1))],	
	   listaCodVendedor[1 + mod(ped, array_length(listaCodVendedor, 1))],
	   listaTotalPedido[1 + mod(ped, array_length(listaTotalPedido, 1))],	   
	   listaDataPedido[1 + mod(ped, array_length(listaDataPedido, 1))]	 
FROM prazoEntrega_list, codCliente_list, codVendedor_list, totalPedido_list, 
     dataPedido_list, generate_series(1000,100000) ped
--limit 10
;

-- fake data item_pedido
WITH numPedido_list AS (
    SELECT array(select num_pedido from pedido)::bigint[] listaNumPedido
) , codProduto_list AS (
    SELECT array(select codigo_produto from produto)::bigint[] listaCodProduto
),  qtade_list AS (
    SELECT '{15, 2, 34, 10, 70, 50}'::int[] listaQtdade
),  valorVenda_list AS (
    SELECT array(select valor_venda from produto)::bigint[] listaValorVenda
),  valorCusto_list AS (
    SELECT array(select valor_custo from produto)::bigint[] listaValorCusto
) 
insert into item_pedido
SELECT listaNumPedido[1 + mod(ip, array_length(listaNumPedido, 1))], 	   
	   listaCodProduto[1 + mod(ip, array_length(listaCodProduto, 1))],	
	   listaQtdade[1 + mod(ip, array_length(listaQtdade, 1))],
	   listaValorVenda[1 + mod(ip, array_length(listaValorVenda, 1))],	   
	   listaValorCusto[1 + mod(ip, array_length(listaValorCusto, 1))]	 
FROM numPedido_list, codProduto_list, qtade_list, valorVenda_list, 
     valorCusto_list, generate_series(1000,1000000) ip
--limit 10
;

-----------------------------------------------------------

--Passo DW1 - Cria dimensao tempo

set lc_time  TO 'pt_BR.UTF-8';
create table bi_DTempo
as
SELECT
	datum as Data,
	extract(year from datum) AS Ano,
	extract(month from datum) AS Mes,
	-- Localized month name
	to_char(datum, 'TMMonth') AS NomeMes,
	extract(day from datum) AS Dia,
	extract(doy from datum) AS DiaDoAno,
	-- Localized weekday
	to_char(datum, 'TMDay') AS NomeDiaSemana,
	-- ISO calendar week
	extract(week from datum) AS SemanaCalendario,
	to_char(datum, 'dd/mm/yyyy') AS DataFormatada,
	'Q' || to_char(datum, 'Q') AS Trimestre,	
	-- Weekend
	CASE WHEN extract(isodow from datum) in (6, 7) THEN 'Final de Semana' ELSE 'Dia da Semana' END AS FinalSemana,
	-- Fixed holidays 
        -- for Brasil
        CASE WHEN to_char(datum, 'DDMM') IN ('0101', '2104', '0105',  '0709', '2512')
		THEN 'Feriado' ELSE 'Dia útil' END
		AS Feriado,    
	-- ISO start and end of the week of this date
	datum + (1 - extract(isodow from datum))::integer AS InicioSemana,
	datum + (7 - extract(isodow from datum))::integer AS FimSemana,
	-- Start and end of the month of this date
	datum + (1 - extract(day from datum))::integer AS InicioMes,
	(datum + (1 - extract(day from datum))::integer + '1 month'::interval)::date - '1 day'::interval AS FimMes
FROM (
	-- There are 3 leap years in this range, so calculate 365 * 10 + 3 records
	SELECT '2020-01-01'::DATE + sequence.day AS datum
	FROM generate_series(0,3652) AS sequence(day)
	GROUP BY sequence.day
     ) DQ
order by 1;


commit;

----------------------------------------------------------------------------
-- Passo DW2 - Cria view materializada no banco de dados ovdt1_dw



CREATE EXTENSION dblink;

create materialized view bi_dcliente
as
SELECT * 
FROM dblink('host=localhost user=postgres password=postdba dbname=ovdt1_erp','select * from cliente')
  AS     minhaView(
  	  codigo_cliente  bigint, 
	  nome_cliente   character varying(40),
	  endereco      character varying(40),
	  cidade         character varying(20),
	  cep character varying(9),
	  uf             character(2),
	  cnpj           character varying(20),
	  ie            character varying(20)
  )
--limit 10
;

create index idx_codigocliente on bi_dcliente (codigo_cliente);


-- Cria view materializada referente da dimensão pedido no banco de dados ovdt1_dw
CREATE EXTENSION dblink;

create materialized view bi_dpedido
as
SELECT *
FROM dblink('host=localhost user=postgres password=postdba dbname=ovdt1_erp','select * from pedido')
  AS     minhaView(
    num_pedido bigint ,						
 	prazo_entrega numeric(3,0) 	,			
 	codigo_cliente bigint	,		
 	codigo_vendedor bigint ,			
 	total_pedido numeric(10,2),
 	data_pedido date
  )
--limit 10
;

create index idx_numpedido on bi_dpedido (num_pedido);

-- Cria view materializada referente da dimensão produto no banco de dados ovdt1_dw
CREATE EXTENSION dblink;

create materialized view bi_dproduto
as
SELECT *
FROM dblink('host=localhost user=postgres password=postdba dbname=ovdt1_erp','select * from produto')
 AS     minhaView(
        codigo_produto    bigint,
        unidade           character(3),
        descricao         character varying(30),
        valor_venda       numeric(7,2),
        valor_custo       numeric(7,2),
        qtde_minima       numeric(5,2),
        quantidade        numeric(5,2),
        comissao_produto  numeric(5,3)
  )
--limit 10
;

create index idx_codigoproduto on bi_dproduto (codigo_produto);

-- Cria view materializada referente da dimensão VENDEDOR no banco de dados ovdt1_dw
CREATE EXTENSION dblink;

create materialized view bi_dvendedor
as
SELECT *
FROM dblink('host=localhost user=postgres password=postdba dbname=ovdt1_erp','select * from vendedor')
 AS minhaView(
    codigo_vendedor  bigint,
    nome_vendedor    character varying(40),
    salario_fixo     numeric(7,2),
    faixa_comissao   character(1),
    senha            character varying(50)   
  )
--limit 10
;

create index idx_codigovendedor on bi_dvendedor (codigo_vendedor);



-- Cria view materializada referente ao fato do pedido (item_pedido)no banco de dados ovdt1_dw
create materialized view bi_fitempedido
as
SELECT * 
FROM dblink('host=localhost user=postgres password=postdba dbname=ovdt1_erp',
			'
			select  ped.num_pedido, ped.codigo_cliente, ped.codigo_vendedor, ped.data_pedido,
        	pro.codigo_produto,
        	ip.quantidade, ip.valor_venda, ip.valor_custo
			from pedido ped, item_pedido ip, produto pro
			where ped.num_pedido = ip.num_pedido
  			  and ip.codigo_produto = pro.codigo_produto
			')
  AS    minhaView(
	  	num_pedido       bigint,
 		codigo_cliente   bigint,
 		codigo_vendedor  bigint,
 		data_pedido      date,
 		codigo_produto   bigint,
 		quantidade       numeric(3,0),
 		valor_venda      numeric(7,2),
 		valor_custo      numeric(7,2)
  )
-- limit 100
;

create index idx_numpedido_fip on bi_fitempedido (num_pedido);
create index idx_codigocliente_fip on bi_fitempedido (codigo_cliente);
create index idx_codigovendedor_fip on bi_fitempedido (codigo_vendedor);
create index idx_codigoproduto_fip on bi_fitempedido (codigo_produto);


-- Atualizar os dados da visao materializada
REFRESH MATERIALIZED VIEW bi_dcliente;
REFRESH MATERIALIZED VIEW bi_dpedido;
REFRESH MATERIALIZED VIEW bi_dvendedor;
REFRESH MATERIALIZED VIEW bi_droduto;
REFRESH MATERIALIZED VIEW bi_fitempedido;
 


---------------------------------------------
-- Testes 1 - Comparar tempo gasto de busca
-- 1.1 Sem usar o DW
explain
select nome_cliente, sum(quantidade*valor_venda)
  from cliente cli, pedido ped, item_pedido ip
where cli.codigo_cliente = ped.codigo_cliente
  and ped.num_pedido = ip.num_pedido
group by 1

-- 1.2 Usando o DW
explain
select nome_cliente, sum(quantidade*valor_venda)
  from bi_dcliente cli, bi_fitempedido ip
where cli.codigo_cliente = ip.codigo_cliente
group by 1
;


-- Consulta para subir os dados de ovdt1_erp para o Data Studio
select  ped.num_pedido, cli.nome_cliente, cli.cidade, cli.uf, ven.nome_vendedor, ped.data_pedido,
                pro.codigo_produto, ip.quantidade, ip.valor_custo, ip.valor_venda
                        from cliente cli, vendedor ven, pedido ped, item_pedido ip, produto pro
                        where cli.codigo_cliente = ped.codigo_cliente
                        and ven.codigo_vendedor = ped.codigo_vendedor
                        and ped.num_pedido = ip.num_pedido
                        and ip.codigo_produto = pro.codigo_produto;  


--select * from bi_cliente
--where nome_cliente like 'Jos%';
