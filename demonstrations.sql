SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== BANK ACCOUNT MANAGEMENT SYSTEM ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test balance functions
    DBMS_OUTPUT.PUT_LINE('--- Account Balances ---');
    DBMS_OUTPUT.PUT_LINE('Account 101 Balance: $' || bank_management.get_account_balance(101));
    DBMS_OUTPUT.PUT_LINE('Customer 1 Total Balance: $' || bank_management.get_customer_total_balance(1));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test deposit procedure
    DBMS_OUTPUT.PUT_LINE('--- Deposit Operation ---');
    bank_management.deposit_amount(101, 1000, 'Salary deposit');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test withdrawal procedure
    DBMS_OUTPUT.PUT_LINE('--- Withdrawal Operation ---');
    bank_management.withdraw_amount(101, 500, 'ATM withdrawal');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test transfer procedure
    DBMS_OUTPUT.PUT_LINE('--- Transfer Operation ---');
    bank_management.transfer_amount(101, 102, 300, 'Transfer to checking');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test error handling
    DBMS_OUTPUT.PUT_LINE('--- Error Handling Examples ---');
    bank_management.deposit_amount(999, 100, 'Test'); -- Invalid account
    DBMS_OUTPUT.PUT_LINE('');
    bank_management.withdraw_amount(101, 10000, 'Large withdrawal'); -- Exceeds limit
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test account statement
    DBMS_OUTPUT.PUT_LINE('--- Account Statement ---');
    bank_management.display_account_statement(101, 365);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test transaction history with VARRAY
    DBMS_OUTPUT.PUT_LINE('--- Transaction History ---');
    DECLARE
        transactions bank_management.transaction_array;
    BEGIN
        transactions := bank_management.get_transaction_history(101);
        FOR i IN 1..transactions.COUNT LOOP
            IF transactions(i) IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE(transactions(i));
            END IF;
        END LOOP;
    END;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test bank statistics with associative array
    DBMS_OUTPUT.PUT_LINE('--- Bank Statistics ---');
    DECLARE
        stats bank_management.customer_stats;
        stat_name VARCHAR2(50);
    BEGIN
        stats := bank_management.calculate_bank_statistics();
        stat_name := stats.FIRST;
        WHILE stat_name IS NOT NULL LOOP
            DBMS_OUTPUT.PUT_LINE(RPAD(stat_name, 20) || ': ' || stats(stat_name));
            stat_name := stats.NEXT(stat_name);
        END LOOP;
    END;
    
END;
/