USE master;

GO 
DROP DATABASE IF EXISTS Company;
GO 
CREATE DATABASE Company;
GO 

USE Company;

GO 
CREATE FUNCTION f_get_precentage(@insurance_type_code INT) 
RETURNS money 
BEGIN 
	DECLARE @insurance_percent FLOAT
	SELECT @insurance_percent = (
			SELECT percentage_of_the_type_of_insurance
			FROM Insurance_type
			WHERE Insurance_type.insurance_type_code = @insurance_type_code
		) 
	RETURN @insurance_percent
END 
GO 


CREATE FUNCTION f_get_salary(@code_insurance_agent INT) 
RETURNS money 
BEGIN 
	DECLARE @salary FLOAT
	SELECT @salary = (
			SELECT SUM(VALUE)
			FROM (
					SELECT [dbo].f_get_precentage(insurance_type_code) * insurance_payment AS VALUE
					FROM Contract
						INNER JOIN Insurance_agent ON Contract.insurance_agent_code = @code_insurance_agent
				) AS A
		)
	RETURN @salary
END 
GO 

CREATE VIEW V
AS SELECT RAND() AS R
GO

CREATE FUNCTION get_random_string()
RETURNS NVARCHAR(10)
BEGIN
	DECLARE @LoopCount AS INT=0
	DECLARE @Length AS INT=10
	DECLARE @RandomString AS NVARCHAR(10);
	WHILE (@LoopCount < @Length) 
	BEGIN
		SELECT @RandomString  = (SELECT CONCAT(@RandomString ,CHAR(CAST((SELECT R*26 FROM V) AS INT) + 65)))
		SELECT @LoopCount = @LoopCount + 1
	END
	RETURN @RandomString
END
GO

CREATE FUNCTION get_random_telephone()
RETURNS BIGINT
BEGIN
	DECLARE @TELEPHONE AS BIGINT=0
	SELECT @TELEPHONE=(SELECT CAST(FLOOR((SELECT R FROM V)*888888889) AS bigint))
	RETURN @TELEPHONE
END
GO

CREATE FUNCTION get__random_percent()
RETURNS FLOAT
BEGIN
	 DECLARE @Percent AS FLOAT=0
	 SELECT @Percent=(SELECT CAST(FLOOR((SELECT R FROM V)*101) as float))
	 RETURN @Percent
END
GO

CREATE FUNCTION get__random_number_positive()
RETURNS FLOAT
BEGIN
	 DECLARE @Num AS FLOAT=0
	 SELECT @Num=(SELECT CAST(FLOOR((SELECT R FROM V)*100000) as float))
	 RETURN @Num
END
GO

CREATE FUNCTION get_random_code_branch()
RETURNS INT
BEGIN
	DECLARE @Code AS INT=0
	SELECT @Code=(SELECT CAST(FLOOR((SELECT R FROM V)*(MAX(branch_code)-MIN(branch_code))+1) AS int)
from Branch)
	RETURN @Code
END
GO

CREATE FUNCTION get_random_code_Insurance_agent()
RETURNS INT
BEGIN
	DECLARE @Code AS INT=0
	SELECT @Code=(SELECT CAST(FLOOR((SELECT R FROM V)*(MAX(code_insurance_agent)-MIN(code_insurance_agent))+1) AS int)
from Insurance_agent)
	RETURN @Code
END
GO

CREATE FUNCTION get_random_code_Insurance_type()
RETURNS INT
BEGIN
	DECLARE @Code AS INT=0
	SELECT @Code=(SELECT CAST(FLOOR((SELECT R FROM V)*(MAX(insurance_type_code)-MIN(insurance_type_code))+1) AS int)
from Insurance_type)
	RETURN @Code
END
GO

CREATE FUNCTION get_random_code_Client()
RETURNS INT
BEGIN
	DECLARE @Code AS INT=0
	SELECT @Code=(SELECT CAST(FLOOR((SELECT R FROM V)*(MAX(client_code)-MIN(client_code))+1) AS int)
from Client)
	RETURN @Code
END
GO


CREATE FUNCTION get_random_date()
RETURNS DATE
BEGIN
	DECLARE @Date AS DATE;
	DECLARE @StartDate AS date='01/01/1900';
	DECLARE @EndDate AS date= GETDATE();
	SELECT @DATE=DATEADD(day, (ABS(CHECKSUM((SELECT R FROM V)))%DATEDIFF(day,@EndDate,@StartDate)), 0)
	RETURN @Date
END
GO


CREATE TABLE Branch (
    branch_code INT IDENTITY NOT NULL PRIMARY KEY CLUSTERED,
    Address nvarchar(50) NOT NULL,
    telephone BIGINT CONSTRAINT CHECK_TELEPHONE_FILIALS CHECK (telephone > 0),
    branch_name nvarchar(50) NOT NULL,
) 
GO 

CREATE TABLE Insurance_type (
    insurance_type_code INT IDENTITY NOT NULL PRIMARY KEY CLUSTERED,
    Name nvarchar(50) NOT NULL,
    percentage_of_the_type_of_insurance FLOAT NOT NULL CONSTRAINT CHECK_PERCENTEGE_OF_TYPE CHECK (
        percentage_of_the_type_of_insurance >= 0
        AND percentage_of_the_type_of_insurance <= 100
    ),
    percent_risk FLOAT NOT NULL CONSTRAINT CHECK_PERCENTEGE_OF_RISK CHECK (
        percent_risk >= 0
        AND percent_risk <= 100
    ),
) 
GO 

CREATE TABLE Insurance_agent (
    code_insurance_agent INT IDENTITY NOT NULL PRIMARY KEY CLUSTERED,
    surname nvarchar(50) NOT NULL,
    name nvarchar(50) NOT NULL,
    address nvarchar(50) NOT NULL,
    telephone BIGINT NOT NULL CONSTRAINT CHECK_TELEPHONE_AGENT CHECK (telephone > 0),
    branch_code INT NOT NULL,
    salary AS ([dbo].f_get_salary(code_insurance_agent))
) 
GO 

CREATE TABLE Client(
    client_code INT IDENTITY NOT NULL PRIMARY KEY CLUSTERED,
    name nvarchar(50) NOT NULL,
    surname nvarchar(50) NOT NULL,
    telephone BIGINT CONSTRAINT CHECK_TELEPHONE_CLIENT CHECK (telephone > 0),
    address nvarchar(50) NOT NULL,
) 
GO 

CREATE TABLE Contract (
    Number_dogovor INT IDENTITY NOT NULL PRIMARY KEY CLUSTERED,
    --branch_code int NOT NULL,
    DATE DATE NOT NULL CONSTRAINT CHECK_DATE_CONTRACT CHECK (DATE <= GETDATE()),
    insurance_type_code INT NOT NULL,
    tariff_rate money NOT NULL CONSTRAINT CHECK_TARIFF_RATE_CONTRACT CHECK (tariff_rate >= 0 AND tariff_rate <=100),
    insurance_sum money NOT NULL CONSTRAINT CHECK_INSYRANCE_SUM_CONTRACT CHECK (insurance_sum > 0),
    insurance_payment AS (tariff_rate * insurance_sum),
    Client_code INT NOT NULL,
    insurance_agent_code INT NOT NULL
) 
GO

ALTER TABLE Contract 
WITH CHECK ADD CONSTRAINT [contract_fk0] FOREIGN KEY ([insurance_type_code]) REFERENCES Insurance_type([insurance_type_code]) 
ON UPDATE CASCADE 
GO

ALTER TABLE Contract 
CHECK CONSTRAINT [contract_fk0 ]
GO

ALTER TABLE Contract 
WITH CHECK ADD CONSTRAINT [contract_fk1] FOREIGN KEY ([Client_code]) REFERENCES [Client]([client_code]) 
ON UPDATE CASCADE 
GO

ALTER TABLE Contract 
CHECK CONSTRAINT [contract_fk1] 
GO

ALTER TABLE Contract 
WITH CHECK ADD CONSTRAINT [contract_fk2] FOREIGN KEY ([insurance_agent_code]) REFERENCES Insurance_agent([code_insurance_agent]) 
ON UPDATE CASCADE 
GO

ALTER TABLE Contract 
CHECK CONSTRAINT [contract_fk2] 
GO

ALTER TABLE Insurance_agent 
WITH CHECK ADD CONSTRAINT [insurance_agent_fk0] FOREIGN KEY ([branch_code]) REFERENCES Branch([branch_code]) 
ON UPDATE CASCADE 
GO

ALTER TABLE Insurance_agent 
CHECK CONSTRAINT [insurance_agent_fk0] 
GO

INSERT INTO Branch(Address, telephone, branch_name)
VALUES
    ('Проспект Победителей, 21', 1235412, 'Pantomima'),
    ('Проспект Независимости, 123', 51224, 'Great'),
    ('Улица Ефремова, 13', 41564364363, 'Компания'),
    ('Мазурова, 23', 4248782, 'Классная'),
    ('Молодежная, 4', 42428974, 'Молодцы'),
    ('Белорусская, 65', 874397854, 'Наша'),
    ('Зайцева, 1', 2027484724, 'Атлант'),
    ('Щелкунская, 8', 82742982, 'Добрая'),
    ('Цельная, 53', 94682307, 'Еда'),
    ('Мехматовская, 1', 532567124, 'THE BEST') 
GO

--SELECT *
--FROM Branch

INSERT INTO Client(name, surname, telephone, address)
VALUES
    ('Даниил', 'Манкевич', 421412, 'Первомайская'),
    ('Антон', 'Логвиненко', 6215624142, 'Советская'),
    ('Виктор', 'Викторенко', 5347782398, 'Крутая'),
    ('Вано', 'Молодой', 458273839, 'Легендарная'),
    ('Игорь', 'Легенда', 5435735637, 'Мужская'),
    ('Артем', 'Метеленко', 43764782732, 'Женская'),
    ('Кузьма', 'Старорусский', 958783487, 'Ценная'),
    ('Данила', 'Уланский', 85673834, 'Душевная'),
    ('Кин', 'Ун Чан', 532564354, 'Китайская'),
    ('Никита', 'Драко', 723523522, 'Дзержинского') 
GO

--SELECT *
--FROM Client

INSERT INTO Insurance_type(
        Name,
        percentage_of_the_type_of_insurance,
        percent_risk
    )
VALUES
    ('Смерть', 32, 33),
    ('Травма', 54, 45),
    ('Болезнь', 12, 78),
    ('Имущество', 41, 34),
    ('Кража', 76, 12),
    ('Угон автомобиля', 59, 7),
    ('Угон велосипеда', 65, 34),
    ('Медицинское оборудование', 98, 87),
    ('Пожар', 47, 21),
    ('ДТП', 35, 12) 
GO

--SELECT *
--FROM insurance_type

INSERT INTO Insurance_agent(surname, name, address, telephone, branch_code)
VALUES
    ('Иванов', 'Иван', 'Молодежная', 12453523, 1),
    ('Петров', 'Петр', 'Купаловская', 52332423412, 1),
    ('Сол', 'Гудман', 'Минская', 543634324, 5),
    ('Инох', 'Томпсон', 'Гомельская', 52332423412, 4),
    ('Уолтер', 'Уайт', 'Гродненская', 52332423412, 2),
    ('Томас', 'Шелби', 'Брестская', 52332423412, 9),
    ('Рик', 'Санчес', 'Могилевская', 52332423412, 7),
    ('Морти', 'Смит', 'Купаловская', 52332423412, 6),
    ('Митрофан', 'Митрофанский', 'Полоцкая', 52332423412,3),
    ('Сергеев', 'Сергей', 'Фрунзенская', 82915712, 8) 
GO

--SELECT *
--FROM insurance_agent

INSERT INTO Contract(
        DATE,
        insurance_type_code,
        tariff_rate,
        insurance_sum,
        Client_code,
        insurance_agent_code
    )
VALUES
    ('02/03/2003', 3, 45, 15, 2, 3),
    ('03/03/2003', 1, 52, 16, 3, 1),
    ('08/31/2019', 6, 53, 64, 5, 5),
    ('05/16/1986', 6, 64, 23, 4, 7),
    ('01/29/2017', 2, 6, 53, 4, 5),
    ('10/19/2009', 3, 34, 32, 6, 7),
    ('02/06/2009', 8, 13, 54, 8, 9),
    ('01/14/2020', 9, 2, 34, 9, 4),
    ('12/23/1979', 7, 41, 543, 4, 6),
    ('03/16/2023', 1, 65, 122, 1, 8) 
GO

--SELECT *
--FROM Contract


--ПРОВЕРКИ ОГРАНИЧЕНИЙ
--INSERT INTO Branch(Address, telephone,branch_name)
--VALUES ('Проспект Победителей, 21',-1235412,'Pantomima')
--GO
--INSERT INTO Client(name, surname,telephone,address)
--VALUES ('Даниил','Манкевич',-421412,'Первомайская')
--GO
--INSERT INTO Insurance_type(Name, percentage_of_the_type_of_insurance,percent_risk)
--VALUES ('Смерть',-3,33)
--GO
--INSERT INTO Insurance_type(Name, percentage_of_the_type_of_insurance,percent_risk)
--VALUES ('Смерть',4234,33)
--GO
--INSERT INTO Insurance_type(Name, percentage_of_the_type_of_insurance,percent_risk)
--VALUES ('Смерть',3,-33)
--GO
--INSERT INTO Insurance_type(Name, percentage_of_the_type_of_insurance,percent_risk)
--VALUES ('Смерть',3,144)
--GO
--INSERT INTO Insurance_agent(surname,name,address,telephone,branch_code)
--VALUES ('Иванов' ,'Иван', 'Молодежная',-12453523,1)
--GO
--INSERT INTO Insurance_agent(surname,name,address,telephone,branch_code)
--VALUES ('Иванов' ,'Иван', 'Молодежная',12453523,54)
--GO
--INSERT INTO Contract(Date,insurance_type_code,tariff_rate,insurance_sum,Client_code,insurance_agent_code)
--VALUES ('05/03/2033',3,45,15,2,3)
--GO
--INSERT INTO Contract(Date,insurance_type_code,tariff_rate,insurance_sum,Client_code,insurance_agent_code)
--VALUES ('02/03/2003',43,45,15,2,3)
--GO
--INSERT INTO Contract(Date,insurance_type_code,tariff_rate,insurance_sum,Client_code,insurance_agent_code)
--VALUES ('05/03/2033',3,-5,15,2,3)
--GO
--INSERT INTO Contract(Date,insurance_type_code,tariff_rate,insurance_sum,Client_code,insurance_agent_code)
--VALUES ('05/03/2033',3,45,-325,52,3)
--GO
--INSERT INTO Contract(Date,insurance_type_code,tariff_rate,insurance_sum,Client_code,insurance_agent_code)
--VALUES ('05/03/2033',3,45,15,2,54)
--GO


DECLARE @LoopCount AS INT=0
DECLARE @Length AS INT=20
WHILE (@LoopCount < @Length) 
BEGIN
	INSERT INTO Branch(Address, telephone, branch_name)
	VALUES ([dbo].get_random_string(),[dbo].get_random_telephone(),[dbo].get_random_string())
	SELECT @LoopCount = @LoopCount + 1
END


SET @LoopCount=0
SET @Length =190
WHILE (@LoopCount < @Length) 
BEGIN
	INSERT INTO Insurance_type(Name, percentage_of_the_type_of_insurance,percent_risk)
	VALUES ([dbo].get_random_string(),[dbo].get__random_percent(),[dbo].get__random_percent())
	SELECT @LoopCount = @LoopCount + 1
END

SET @LoopCount=0
SET @Length =20
WHILE (@LoopCount < @Length) 
BEGIN
	INSERT INTO Insurance_agent(surname, name, address, telephone, branch_code)
	VALUES ([dbo].get_random_string(),[dbo].get_random_string(),[dbo].get_random_string(),[dbo].get_random_telephone(),[dbo].get_random_code_branch())
	SELECT @LoopCount = @LoopCount + 1
END


SET @LoopCount=0
SET @Length =20
WHILE (@LoopCount < @Length) 
BEGIN
	INSERT INTO Client(name, surname, telephone, address)
	VALUES ([dbo].get_random_string(),[dbo].get_random_string(),[dbo].get_random_telephone(),[dbo].get_random_string())
	SELECT @LoopCount = @LoopCount + 1
END


SET @LoopCount=0
SET @Length =20
WHILE (@LoopCount < @Length) 
BEGIN
	INSERT INTO Contract(DATE, insurance_type_code,tariff_rate, insurance_sum, Client_code,insurance_agent_code)
	VALUES ([dbo].get_random_date(),[dbo].get_random_code_Insurance_type(),[dbo].get__random_percent(),[dbo].get__random_number_positive(),[dbo].get_random_code_Client(),[dbo].get_random_code_Insurance_agent())
	SELECT @LoopCount = @LoopCount + 1
END


