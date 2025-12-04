use session11;
create table Budgets (
budgetID int primary key auto_increment,
accountID int not null,
amount decimal(10,2),
month varchar(20),
foreign key (accountID) references accounts(accountID)
);
create table expenses (
expenseID int primary key auto_increment,
accountID int not null,
expenseDate datetime,
description varchar(255),
foreign key (accountID) references accounts(accountID)
);

-- Viết một stored procedure để thực hiện chi tiêu từ một tài khoản:
-- Trừ số tiền chi tiêu từ số dư tài khoản tương ứng trong bảng Accounts.
-- Thêm bản ghi chi tiêu vào bảng Expenses.
-- Cập nhật ngân sách trong bảng Budgets nếu cần.
-- Đảm bảo rằng số dư tài khoản không bị âm và toàn bộ giao dịch phải thành công hoặc không có gì thay đổi nếu có lỗi.

DELIMITER $$
CREATE PROCEDURE sp_spend_money (
    IN p_accountID INT,
    IN p_amount DECIMAL(10,2),
    IN p_description VARCHAR(255),
    IN p_month VARCHAR(20)
)
BEGIN
    DECLARE v_balance DECIMAL(10,2);
    DECLARE v_budget DECIMAL(10,2);

    -- Bắt đầu Transaction
    START TRANSACTION;

    -- Khóa dòng account để kiểm tra tránh tranh chấp
    SELECT balance INTO v_balance 
    FROM Accounts 
    WHERE accountID = p_accountID 
    FOR UPDATE;

    -- Nếu tài khoản không tồn tại
    IF v_balance IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tài khoản không tồn tại!';
    END IF;

    -- Kiểm tra số dư đủ không
    IF v_balance < p_amount THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số dư không đủ để chi tiêu!';
    END IF;

    -- Trừ tiền tài khoản
    UPDATE Accounts
    SET balance = balance - p_amount
    WHERE accountID = p_accountID;

    -- Thêm bản ghi chi tiêu
    INSERT INTO Expenses(accountID, expenseDate, description)
    VALUES (p_accountID, NOW(), p_description);

    -- Lấy ngân sách hiện tại
    SELECT amount INTO v_budget 
    FROM Budgets 
    WHERE accountID = p_accountID AND month = p_month
    FOR UPDATE;

    -- Nếu tồn tại ngân sách thì trừ đi
    IF v_budget IS NOT NULL THEN
        UPDATE Budgets
        SET amount = amount - p_amount
        WHERE accountID = p_accountID AND month = p_month;
    END IF;

    -- Hoàn tất transaction
    COMMIT;
END $$

DELIMITER ;
