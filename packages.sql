CREATE OR REPLACE PACKAGE bank_management AS
    -- Collection types
    TYPE account_table IS TABLE OF bank_accounts%ROWTYPE;
    TYPE transaction_array IS VARRAY(50) OF VARCHAR2(500);
    TYPE customer_stats IS TABLE OF NUMBER INDEX BY VARCHAR2(50);
    
    -- Procedures
    PROCEDURE deposit_amount(p_account_id NUMBER, p_amount NUMBER, p_description VARCHAR2);
    PROCEDURE withdraw_amount(p_account_id NUMBER, p_amount NUMBER, p_description VARCHAR2);
    PROCEDURE transfer_amount(p_from_account NUMBER, p_to_account NUMBER, p_amount NUMBER);
    PROCEDURE display_account_statement(p_account_id NUMBER, p_days NUMBER DEFAULT 30);
    
    -- Functions
    FUNCTION get_account_balance(p_account_id NUMBER) RETURN NUMBER;
    FUNCTION get_customer_total_balance(p_customer_id NUMBER) RETURN NUMBER;
    FUNCTION get_transaction_history(p_account_id NUMBER) RETURN transaction_array;
    FUNCTION calculate_bank_statistics RETURN customer_stats;
    
    -- Global variables
    g_min_balance CONSTANT NUMBER := 100;
    g_max_withdrawal CONSTANT NUMBER := 5000;
    g_error_message VARCHAR2(500);
END bank_management;
/

CREATE OR REPLACE PACKAGE BODY bank_management AS

    -- Function to get account balance
    FUNCTION get_account_balance(p_account_id NUMBER) RETURN NUMBER IS
        v_balance NUMBER;
    BEGIN
        SELECT balance INTO v_balance 
        FROM bank_accounts 
        WHERE account_id = p_account_id AND status = 'ACTIVE';
        
        RETURN v_balance;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            g_error_message := 'Account not found or inactive';
            RETURN -1;
        WHEN OTHERS THEN
            g_error_message := 'Error retrieving balance: ' || SQLERRM;
            RETURN -1;
    END get_account_balance;

    -- Function to get customer total balance
    FUNCTION get_customer_total_balance(p_customer_id NUMBER) RETURN NUMBER IS
        v_total_balance NUMBER := 0;
        CURSOR balance_cursor IS
            SELECT balance FROM bank_accounts 
            WHERE customer_id = p_customer_id AND status = 'ACTIVE';
    BEGIN
        FOR balance_rec IN balance_cursor LOOP
            v_total_balance := v_total_balance + balance_rec.balance;
        END LOOP;
        
        RETURN v_total_balance;
        
    EXCEPTION
        WHEN OTHERS THEN
            g_error_message := 'Error calculating total balance: ' || SQLERRM;
            RETURN -1;
    END get_customer_total_balance;

    -- Function to get transaction history using VARRAY
    FUNCTION get_transaction_history(p_account_id NUMBER) RETURN transaction_array IS
        v_transactions transaction_array := transaction_array();
        v_counter NUMBER := 1;
    BEGIN
        FOR trans_rec IN (
            SELECT transaction_type, amount, transaction_date, description
            FROM transactions
            WHERE account_id = p_account_id
            ORDER BY transaction_date DESC
        ) LOOP
            IF v_counter <= 50 THEN
                v_transactions.EXTEND;
                v_transactions(v_counter) := 
                    TO_CHAR(trans_rec.transaction_date, 'DD-MON-YY') || ' | ' ||
                    RPAD(trans_rec.transaction_type, 12) || ' | ' ||
                    '$' || LPAD(trans_rec.amount, 8) || ' | ' ||
                    trans_rec.description;
                v_counter := v_counter + 1;
            ELSE
                EXIT;
            END IF;
        END LOOP;
        
        RETURN v_transactions;
        
    EXCEPTION
        WHEN OTHERS THEN
            g_error_message := 'Error retrieving transaction history: ' || SQLERRM;
            RETURN transaction_array();
    END get_transaction_history;

    -- Function with associative array for bank statistics
    FUNCTION calculate_bank_statistics RETURN customer_stats IS
        v_stats customer_stats;
    BEGIN
        SELECT COUNT(*) INTO v_stats('TOTAL_CUSTOMERS') FROM bank_customers;
        SELECT COUNT(*) INTO v_stats('TOTAL_ACCOUNTS') FROM bank_accounts;
        SELECT SUM(balance) INTO v_stats('TOTAL_BALANCE') FROM bank_accounts WHERE status = 'ACTIVE';
        SELECT AVG(balance) INTO v_stats('AVERAGE_BALANCE') FROM bank_accounts WHERE status = 'ACTIVE';
        
        RETURN v_stats;
        
    EXCEPTION
        WHEN OTHERS THEN
            g_error_message := 'Error calculating statistics: ' || SQLERRM;
            RETURN customer_stats();
    END calculate_bank_statistics;

    -- Procedure with GOTO for deposit operation
    PROCEDURE deposit_amount(p_account_id NUMBER, p_amount NUMBER, p_description VARCHAR2) IS
        v_current_balance NUMBER;
        v_transaction_id NUMBER;
        v_customer_name VARCHAR2(100);
    BEGIN
        -- Validate amount
        IF p_amount <= 0 THEN
            g_error_message := 'Deposit amount must be positive';
            GOTO error_handler;
        END IF;
        
        -- Check if account exists and is active
        BEGIN
            SELECT balance, c.customer_name INTO v_current_balance, v_customer_name
            FROM bank_accounts a
            JOIN bank_customers c ON a.customer_id = c.customer_id
            WHERE a.account_id = p_account_id AND a.status = 'ACTIVE';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                g_error_message := 'Account not found or inactive';
                GOTO error_handler;
        END;
        
        -- Generate transaction ID
        SELECT NVL(MAX(transaction_id), 0) + 1 INTO v_transaction_id FROM transactions;
        
        -- Insert transaction record
        INSERT INTO transactions (transaction_id, account_id, transaction_type, amount, transaction_date, description)
        VALUES (v_transaction_id, p_account_id, 'DEPOSIT', p_amount, SYSDATE, p_description);
        
        -- Update account balance
        UPDATE bank_accounts SET balance = balance + p_amount WHERE account_id = p_account_id;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Deposit successful!');
        DBMS_OUTPUT.PUT_LINE('Customer: ' || v_customer_name);
        DBMS_OUTPUT.PUT_LINE('Amount: $' || p_amount);
        DBMS_OUTPUT.PUT_LINE('New Balance: $' || (v_current_balance + p_amount));
        GOTO success_exit;
        
        <<error_handler>>
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || g_error_message);
        ROLLBACK;
        RETURN;
        
        <<success_exit>>
        NULL;
        
    EXCEPTION
        WHEN OTHERS THEN
            g_error_message := 'Unexpected error during deposit: ' || SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR: ' || g_error_message);
            ROLLBACK;
    END deposit_amount;

    -- Procedure for withdrawal with validation
    PROCEDURE withdraw_amount(p_account_id NUMBER, p_amount NUMBER, p_description VARCHAR2) IS
        v_current_balance NUMBER;
        v_transaction_id NUMBER;
        v_customer_name VARCHAR2(100);
    BEGIN
        -- Validate amount
        IF p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Withdrawal amount must be positive');
        END IF;
        
        IF p_amount > g_max_withdrawal THEN
            RAISE_APPLICATION_ERROR(-20002, 'Withdrawal amount exceeds maximum limit of $' || g_max_withdrawal);
        END IF;
        
        -- Get current balance
        SELECT balance, c.customer_name INTO v_current_balance, v_customer_name
        FROM bank_accounts a
        JOIN bank_customers c ON a.customer_id = c.customer_id
        WHERE a.account_id = p_account_id AND a.status = 'ACTIVE';
        
        -- Check minimum balance requirement
        IF (v_current_balance - p_amount) < g_min_balance THEN
            RAISE_APPLICATION_ERROR(-20003, 'Insufficient funds. Minimum balance requirement: $' || g_min_balance);
        END IF;
        
        -- Generate transaction ID
        SELECT NVL(MAX(transaction_id), 0) + 1 INTO v_transaction_id FROM transactions;
        
        -- Insert transaction record
        INSERT INTO transactions (transaction_id, account_id, transaction_type, amount, transaction_date, description)
        VALUES (v_transaction_id, p_account_id, 'WITHDRAWAL', p_amount, SYSDATE, p_description);
        
        -- Update account balance
        UPDATE bank_accounts SET balance = balance - p_amount WHERE account_id = p_account_id;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Withdrawal successful!');
        DBMS_OUTPUT.PUT_LINE('Customer: ' || v_customer_name);
        DBMS_OUTPUT.PUT_LINE('Amount: $' || p_amount);
        DBMS_OUTPUT.PUT_LINE('New Balance: $' || (v_current_balance - p_amount));
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Account not found or inactive');
            ROLLBACK;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
            ROLLBACK;
    END withdraw_amount;

    -- Procedure for transfer between accounts
    PROCEDURE transfer_amount(p_from_account NUMBER, p_to_account NUMBER, p_amount NUMBER) IS
        v_from_balance NUMBER;
        v_to_balance NUMBER;
        v_from_customer VARCHAR2(100);
        v_to_customer VARCHAR2(100);
        v_transaction_id NUMBER;
    BEGIN
        -- Validate transfer to different account
        IF p_from_account = p_to_account THEN
            RAISE_APPLICATION_ERROR(-20004, 'Cannot transfer to the same account');
        END IF;
        
        -- Get from account details
        SELECT balance, c.customer_name INTO v_from_balance, v_from_customer
        FROM bank_accounts a
        JOIN bank_customers c ON a.customer_id = c.customer_id
        WHERE a.account_id = p_from_account AND a.status = 'ACTIVE';
        
        -- Get to account details
        SELECT balance, c.customer_name INTO v_to_balance, v_to_customer
        FROM bank_accounts a
        JOIN bank_customers c ON a.customer_id = c.customer_id
        WHERE a.account_id = p_to_account AND a.status = 'ACTIVE';
        
        -- Check sufficient funds
        IF (v_from_balance - p_amount) < g_min_balance THEN
            RAISE_APPLICATION_ERROR(-20005, 'Insufficient funds for transfer');
        END IF;
        
        -- Generate transaction IDs
        SELECT NVL(MAX(transaction_id), 0) + 1 INTO v_transaction_id FROM transactions;
        
        -- Record withdrawal transaction
        INSERT INTO transactions (transaction_id, account_id, transaction_type, amount, transaction_date, description)
        VALUES (v_transaction_id, p_from_account, 'WITHDRAWAL', p_amount, SYSDATE, 
                'Transfer to account ' || p_to_account);
        
        -- Record deposit transaction
        INSERT INTO transactions (transaction_id, account_id, transaction_type, amount, transaction_date, description)
        VALUES (v_transaction_id + 1, p_to_account, 'DEPOSIT', p_amount, SYSDATE, 
                'Transfer from account ' || p_from_account);
        
        -- Update balances
        UPDATE bank_accounts SET balance = balance - p_amount WHERE account_id = p_from_account;
        UPDATE bank_accounts SET balance = balance + p_amount WHERE account_id = p_to_account;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Transfer successful!');
        DBMS_OUTPUT.PUT_LINE('From: ' || v_from_customer || ' (Account: ' || p_from_account || ')');
        DBMS_OUTPUT.PUT_LINE('To: ' || v_to_customer || ' (Account: ' || p_to_account || ')');
        DBMS_OUTPUT.PUT_LINE('Amount: $' || p_amount);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: One or both accounts not found or inactive');
            ROLLBACK;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
            ROLLBACK;
    END transfer_amount;

    -- Procedure with cursor to display account statement
    PROCEDURE display_account_statement(p_account_id NUMBER, p_days NUMBER DEFAULT 30) IS
        CURSOR statement_cursor IS
            SELECT transaction_type, amount, transaction_date, description
            FROM transactions
            WHERE account_id = p_account_id
            AND transaction_date >= SYSDATE - p_days
            ORDER BY transaction_date DESC;
            
        v_account_info bank_accounts%ROWTYPE;
        v_customer_name VARCHAR2(100);
        v_transaction_count NUMBER := 0;
    BEGIN
        -- Get account and customer information
        SELECT a.*, c.customer_name INTO v_account_info, v_customer_name
        FROM bank_accounts a
        JOIN bank_customers c ON a.customer_id = c.customer_id
        WHERE a.account_id = p_account_id;
        
        DBMS_OUTPUT.PUT_LINE('=== ACCOUNT STATEMENT ===');
        DBMS_OUTPUT.PUT_LINE('Account ID: ' || v_account_info.account_id);
        DBMS_OUTPUT.PUT_LINE('Customer: ' || v_customer_name);
        DBMS_OUTPUT.PUT_LINE('Account Type: ' || v_account_info.account_type);
        DBMS_OUTPUT.PUT_LINE('Current Balance: $' || v_account_info.balance);
        DBMS_OUTPUT.PUT_LINE('Statement Period: Last ' || p_days || ' days');
        DBMS_OUTPUT.PUT_LINE('================================');
        
        -- Display transactions using cursor
        FOR trans_rec IN statement_cursor LOOP
            DBMS_OUTPUT.PUT_LINE(
                TO_CHAR(trans_rec.transaction_date, 'DD-MON-YY HH24:MI') || ' | ' ||
                RPAD(trans_rec.transaction_type, 12) || ' | ' ||
                '$' || LPAD(trans_rec.amount, 10) || ' | ' ||
                trans_rec.description
            );
            v_transaction_count := v_transaction_count + 1;
        END LOOP;
        
        IF v_transaction_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('No transactions found in the specified period.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('================================');
            DBMS_OUTPUT.PUT_LINE('Total transactions: ' || v_transaction_count);
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Account not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR generating statement: ' || SQLERRM);
    END display_account_statement;

END bank_management;
/