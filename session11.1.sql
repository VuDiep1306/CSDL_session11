create database session11;
use session11;
create table accounts (
accountID int primary key auto_increment,
balance decimal(10,2)
);
create table transactions (
transactionID int primary key auto_increment,
fromAccountID int not null,
toAccountID int not null,
amount decimal(10,2) not null,
transactionDate datetime not null, 
constraint fk_from_account 
	foreign key (fromAccountID) references Accounts(accountID),
constraint fk_to_account 
	foreign key (toAccountID) references Accounts(accountID)
);
-- Viết một stored procedure để thực hiện một giao dịch chuyển tiền 
-- từ một tài khoản sang tài khoản khác. 
-- Stored procedure này cần đảm bảo rằng giao dịch là nguyên tử (atomic)
-- và số dư của tài khoản nguồn không bị âm.
DELIMITER $$

CREATE PROCEDURE TransferMoney(
    IN _FromAccountID INT,
    IN _ToAccountID INT,
    IN _Amount DECIMAL(10,2)
)
BEGIN
    DECLARE currentBalance DECIMAL(10,2);
    START TRANSACTION;
    SELECT balance INTO currentBalance
    FROM accounts
    WHERE accountID = _FromAccountID
    FOR UPDATE;
    IF currentBalance < _Amount THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không đủ số dư để thực hiện giao dịch!';
    ELSE
        UPDATE accounts 
        SET balance = balance - _Amount
        WHERE accountID = _FromAccountID;

        UPDATE accounts 
        SET balance = balance + _Amount
        WHERE accountID = _ToAccountID;

        INSERT INTO transactions(fromAccountID, toAccountID, amount, transactionDate)
        VALUES (_FromAccountID, _ToAccountID, _Amount, NOW());

        COMMIT;
    END IF;

END $$

DELIMITER ;