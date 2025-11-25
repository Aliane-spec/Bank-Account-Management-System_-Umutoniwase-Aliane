-- Create tables
CREATE TABLE bank_customers (
    customer_id NUMBER PRIMARY KEY,
    customer_name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100),
    phone_number VARCHAR2(15),
    join_date DATE,
    customer_type VARCHAR2(20) CHECK (customer_type IN ('REGULAR', 'PREMIUM', 'VIP'))
);

CREATE TABLE bank_accounts (
    account_id NUMBER PRIMARY KEY,
    customer_id NUMBER REFERENCES bank_customers(customer_id),
    account_type VARCHAR2(20) CHECK (account_type IN ('SAVINGS', 'CHECKING', 'BUSINESS')),
    balance NUMBER DEFAULT 0,
    open_date DATE,
    status VARCHAR2(10) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'FROZEN'))
);

CREATE TABLE transactions (
    transaction_id NUMBER PRIMARY KEY,
    account_id NUMBER REFERENCES bank_accounts(account_id),
    transaction_type VARCHAR2(20) CHECK (transaction_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER')),
    amount NUMBER,
    transaction_date DATE,
    description VARCHAR2(200)
);

-- Insert sample data
INSERT INTO bank_customers VALUES (1, 'Alice Johnson', 'alice@email.com', '555-0101', DATE '2022-01-15', 'PREMIUM');
INSERT INTO bank_customers VALUES (2, 'Bob Smith', 'bob@email.com', '555-0102', DATE '2022-03-20', 'REGULAR');
INSERT INTO bank_customers VALUES (3, 'Carol Davis', 'carol@email.com', '555-0103', DATE '2023-01-10', 'VIP');

INSERT INTO bank_accounts VALUES (101, 1, 'SAVINGS', 5000, DATE '2022-01-15', 'ACTIVE');
INSERT INTO bank_accounts VALUES (102, 1, 'CHECKING', 2500, DATE '2022-02-01', 'ACTIVE');
INSERT INTO bank_accounts VALUES (103, 2, 'SAVINGS', 3000, DATE '2022-03-20', 'ACTIVE');
INSERT INTO bank_accounts VALUES (104, 3, 'BUSINESS', 15000, DATE '2023-01-10', 'ACTIVE');

INSERT INTO transactions VALUES (1001, 101, 'DEPOSIT', 5000, DATE '2022-01-15', 'Initial deposit');
INSERT INTO transactions VALUES (1002, 102, 'DEPOSIT', 2500, DATE '2022-02-01', 'Account opening');
INSERT INTO transactions VALUES (1003, 103, 'DEPOSIT', 3000, DATE '2022-03-20', 'Initial deposit');

COMMIT;