CREATE DATABASE practiceSobes

--Task 0. Init db
USE practiceSobes
CREATE TABLE Banks(
	Id INT PRIMARY KEY IDENTITY NOT NULL ,
	Name NVARCHAR(50) NOT NULL
)

CREATE TABLE BankBranches(
	Id INT PRIMARY KEY IDENTITY NOT NULL,
	Name NVARCHAR(max) NOT NULL,
	City NVARCHAR(50) NOT NULL,
	BankId INT NOT NULL,

	FOREIGN KEY (BankId) REFERENCES Banks(Id)
)
CREATE TABLE SocialStatuses(
	Id INT PRIMARY KEY IDENTITY,
	Name NVARCHAR(50)
)
CREATE TABLE Clients(
	Id INT PRIMARY KEY IDENTITY NOT NULL,
	Name NVARCHAR(max) NOT NULL,
	SocialStatusId INT NOT NULL,

	FOREIGN KEY (SocialStatusId) REFERENCES SocialStatuses(Id)
)

CREATE TABLE Accounts(
	Id INT PRIMARY KEY IDENTITY NOT NULL,
	ClientId INT NOT NULL ,
	BankId INT NOT NULL ,
	CurrentMoney MONEY NOT NULL

	FOREIGN KEY (ClientId) REFERENCES Clients(Id),
	FOREIGN KEY (BankId) REFERENCES Banks(Id),

	UNIQUE (ClientId, BankId)
)

CREATE TABLE Cards(
	Id INT PRIMARY KEY IDENTITY NOT NULL,
	Number BIGINT NOT NULL,
	AccountId INT NOT NULL,
	BalanceMoney MONEY NOT NULL

	FOREIGN KEY (AccountId) REFERENCES Accounts(Id)
)
--Insert DATA
INSERT INTO Banks(Name) VALUES 
('Alfa-bank'), 
('Prior bank'), 
('Gazprom bank'), 
('Belarusbank'),
('BelAgroProm bank')

INSERT INTO SocialStatuses(Name) VALUES 
('Very low'), 
('Low'), 
('Middle'), 
('High'), 
('Very high')

INSERT INTO BankBranches(Name, City, BankId) VALUES 
('Metro "Uruchcha"', 'Minsk', 1),
('Ostrovskogo 15', 'Mogilev', 1),
('Gagarina 101a', 'Borisov', 2),
('Mostovaya 37', 'Grodno', 2),
('Pritytskogo 60/2', 'Minsk', 3),
('Velikii Gostinets 67', 'Molodechno', 3),
('Lenina 10b', 'Vitebsk', 4),
('Karpovicha 21', 'Gomel', 4),
('Antonova 1', 'Grodno', 5),
('Kyibysheva 76', 'Brest', 5),
('Pushkina 2', 'Gomel', 3),
('Petra Mstislavtsa 13', 'Minsk', 2),
('Kalinovskogo 66a', 'Minsk', 4)

INSERT INTO Clients(SocialStatusId, Name) VALUES
(1, 'Dmitriev Konstantin Iaroslavovich'),
(2, 'Konstantinov Karl Ivanovich'),
(1, 'Ignatova Izolda Timurovna'),
(5, 'Nikolaev Liubomir Donatovich'),
(4, 'Denisova Zlata Iliaovna'),
(3, 'Semenov Orest Iakunovich'),
(4, 'Vasileva Kharitina Igorevna'),
(5, 'Shestakova Tatiana Lvovna')

INSERT INTO Accounts(ClientId, BankId, CurrentMoney) VALUES
(2, 2, 800),
(1, 4, 300),
(5, 1, 3500),
(6, 3, 2000),
(3, 3, 400),
(5, 5, 2200),
(8, 3, 5230),
(7, 2, 4200),
(4, 1, 4920),
(2, 5, 500)

INSERT INTO Cards(Number, AccountId, BalanceMoney) VALUES
(5580835898522699, 1, 500),
(5197192113991936, 10, 500),
(5428285650664113, 8, 1300),
(4574768570119339, 2, 300),
(4701091541398908, 3, 2000),
(4815928372306745, 3, 500),
(5220569738680351, 3, 200),
(5125071392782272, 6, 2200),
(5357482612224715, 4, 1000),
(5231578238666957, 4, 100),
(4356110537492950, 5, 200),
(4305217312290236, 9, 3000),
(4682698464155066, 9, 900),
(4683878823811117, 8, 2000)

--Task 1. Output of all banks that have a branch in a certain city
SELECT bank.Name AS bank
FROM Banks bank
JOIN BankBranches branch
ON bank.Id = branch.BankId
WHERE branch.City = 'Gomel'

--Task 2. Displaying all cards indicating the owner's name
SELECT c.Name AS owner_name, cd.number AS card_number, cd.BalanceMoney AS card_balance, b.name AS bank_name
FROM Clients c
JOIN accounts a ON c.Id = a.ClientId
JOIN cards cd ON a.Id = cd.AccountId
JOIN banks b ON a.BankId = b.Id;

--Task 3. Displaying bank accounts where the balance does not match the card balance; the difference is entered in a separate column
SELECT 
    a.Id AS account_id,
    a.ClientId AS client_id,
    a.CurrentMoney AS account_balance,

    SUM(c.BalanceMoney) AS total_card_balance,
    a.CurrentMoney - SUM(c.BalanceMoney) AS difference
FROM 
    Accounts a
JOIN 
    Cards c ON a.Id = c.AccountId
GROUP BY 
    a.Id, a.BankId, a.ClientId, a.CurrentMoney
HAVING 
    a.CurrentMoney <> SUM(c.BalanceMoney)

--Task 4. Implementation using GroupBy
SELECT s.Name AS social_status, COUNT(c.Id) AS card_count
FROM SocialStatuses s
JOIN Clients cl ON s.Id = cl.SocialStatusId
JOIN Accounts a ON cl.Id = a.ClientId
JOIN Cards c ON a.Id = c.AccountId
GROUP BY s.Name;

--Task 4.1. Implementation using a subquery
SELECT s.Name AS social_status,
    (SELECT COUNT(c.Id)
     FROM Cards c
     JOIN Accounts a ON c.AccountId = a.Id
     JOIN Clients cl ON a.ClientId = cl.Id
     WHERE cl.SocialStatusId = s.Id
    ) AS card_count
FROM SocialStatuses s;

--Task 5. Creating a procedure for adding money to the balance for a certain social status
CREATE OR ALTER PROCEDURE AddMoneyBySocialStatus
    @social_status_id INT,
	@amount_of_money DECIMAL(10,2)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM SocialStatuses WHERE Id = @social_status_id)
    BEGIN
        THROW 50000, 'Социальный статус не существует', 1;
        RETURN;
    END

    UPDATE Accounts 
    SET CurrentMoney = CurrentMoney + @amount_of_money
    FROM Accounts a
    INNER JOIN Clients c ON a.ClientId = c.Id
    WHERE c.SocialStatusId = @social_status_id;

    IF @@ROWCOUNT = 0
    BEGIN
        THROW 50000, 'Нет привязанных аккаунтов для этого социального статуса', 1;
        RETURN;
    END
END

--Execute procedure
SELECT * FROM Accounts a
INNER JOIN Clients c ON a.ClientId = c.Id
WHERE c.SocialStatusId = 1;

EXEC AddMoneyBySocialStatus @social_status_id = 1, @amount_of_money = 100

SELECT * FROM Accounts a
INNER JOIN Clients c ON a.ClientId = c.Id
WHERE c.SocialStatusId = 1;

--Task 6. Listing available funds for each client
SELECT 
    c.Id AS ClientId,
    c.Name AS ClientName,
    a.CurrentMoney + ISNULL(SUM(Card.BalanceMoney), 0) AS AvailableFunds
FROM 
    Clients c
    INNER JOIN Accounts a ON c.Id = a.ClientId
    LEFT JOIN Cards Card ON a.Id = Card.AccountId
GROUP BY 
    c.Id, c.Name, a.CurrentMoney;

--Task 7. Creating a procedure that will transfer a certain amount from an account to the card of this account
CREATE PROCEDURE TransferMoneyToCard
    @account_id INT,
    @amount_to_transfer DECIMAL(10, 2),
    @card_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        
        DECLARE @total_card_balance DECIMAL(10, 2);
        SELECT @total_card_balance = ISNULL(SUM(BalanceMoney), 0) FROM Cards WHERE AccountId = @account_id;
		-- Checking that the amount to be transferred is available in the bank account
        IF @total_card_balance + @amount_to_transfer > (SELECT CurrentMoney FROM Accounts WHERE Id = @account_id)
        BEGIN
            THROW 50000, 'Недостаточно средств на счете для перевода на карту', 1;
            RETURN;
        END

        -- Transfer the amount to the card
        UPDATE Cards SET BalanceMoney = BalanceMoney + @amount_to_transfer WHERE Id = @card_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END

--Execute procedure

SELECT * FROM Accounts WHERE Id = 3;
SELECT * FROM Cards WHERE Id = 7;
EXEC TransferMoneyToCard @account_id = 3, @amount_to_transfer = 800, @card_id = 7
SELECT * FROM Accounts WHERE Id = 3;
SELECT * FROM Cards WHERE Id = 7;

--Task 8. Creating a trigger to prevent a decrease in the account balance by the amount for all cards
CREATE OR ALTER TRIGGER PreventAccountBalanceDecrease
ON Accounts 
AFTER UPDATE 
AS 
BEGIN
    IF EXISTS (SELECT * 
               FROM inserted i
               INNER JOIN Cards c ON i.Id = c.AccountId
               GROUP BY i.Id, i.CurrentMoney
               HAVING i.CurrentMoney < ISNULL(SUM(c.BalanceMoney), 0))
    BEGIN
        RAISERROR ('Нельзя уменьшить баланс аккаунта меньше, чем сумма балансов по всем карточкам', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
