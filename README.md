# Bank Account Management System - PL/SQL Project

## 🏦 Project Overview

A comprehensive Bank Account Management System built entirely in PL/SQL that demonstrates advanced database programming concepts including collections, functions, procedures, error handling, cursors, and GOTO statements. This system simulates real-world banking operations with secure transaction processing and account management.

## 🎯 Learning Objectives

This project serves as a practical implementation of key PL/SQL concepts:
- **Collections** (Nested Tables, VARRAYs, Associative Arrays)
- **Functions & Procedures** with parameters and return types
- **Advanced Error Handling** and exception management
- **Cursor Management** for efficient data processing
- **GOTO Statements** for controlled flow (demonstration purposes)
- **Package-based Architecture** for modular code organization

## 🗄️ Database Schema

### Tables Structure

#### 👥 Bank Customers Table
```sql
bank_customers (
    customer_id NUMBER PRIMARY KEY,
    customer_name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100),
    phone_number VARCHAR2(15),
    join_date DATE,
    customer_type VARCHAR2(20) CHECK (customer_type IN ('REGULAR', 'PREMIUM', 'VIP'))
)
```

#### 💰 Bank Accounts Table
```sql
bank_accounts (
    account_id NUMBER PRIMARY KEY,
    customer_id NUMBER REFERENCES bank_customers(customer_id),
    account_type VARCHAR2(20) CHECK (account_type IN ('SAVINGS', 'CHECKING', 'BUSINESS')),
    balance NUMBER DEFAULT 0,
    open_date DATE,
    status VARCHAR2(10) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'FROZEN'))
)
```

#### 🔄 Transactions Table
```sql
transactions (
    transaction_id NUMBER PRIMARY KEY,
    account_id NUMBER REFERENCES bank_accounts(account_id),
    transaction_type VARCHAR2(20) CHECK (transaction_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER')),
    amount NUMBER,
    transaction_date DATE,
    description VARCHAR2(200)
)
```

## 🏗️ Package Architecture

### 📦 BANK_MANAGEMENT Package Specification

#### Collection Types
- `account_table` - Nested table for account records
- `transaction_array` - VARRAY for transaction history
- `customer_stats` - Associative array for bank statistics

#### Key Functions
- `get_account_balance()` - Returns current account balance
- `get_customer_total_balance()` - Computes total balance across all customer accounts
- `get_transaction_history()` - Returns recent transactions using VARRAY
- `calculate_bank_statistics()` - Returns comprehensive bank statistics

#### Key Procedures
- `deposit_amount()` - Handles deposit operations with GOTO error handling
- `withdraw_amount()` - Manages withdrawals with comprehensive validation
- `transfer_amount()` - Processes inter-account transfers
- `display_account_statement()` - Generates detailed account statements

## 🚀 Installation & Setup

### Prerequisites
- Oracle Database 11g or higher
- SQL*Plus or SQL Developer
- Basic PL/SQL execution privileges

### Step-by-Step Setup

1. **Create Tables & Sample Data**
   ```sql
   -- Execute the table creation scripts first
   -- Then run the sample data insertion scripts
   ```

2. **Create Package Specification**
   ```sql
   -- Run the BANK_MANAGEMENT package specification
   ```

3. **Create Package Body**
   ```sql
   -- Run the BANK_MANAGEMENT package body
   ```

4. **Execute Demonstration Script**
   ```sql
   -- Run the demonstration script to test all features
   ```

## 💡 Key Features Demonstrated

### 1. Collection Types Implementation
- **Nested Tables**: `account_table` for returning multiple account records
- **Associative Arrays**: `customer_stats` for efficient bank statistics storage
- **VARRAY**: `transaction_array` for fixed-size transaction history

### 2. Function Design Patterns
- **Parameterized Functions**: Flexible account-based operations
- **Numeric Return Types**: Balance calculations and statistics
- **Collection Return Types**: Returning multiple records efficiently

### 3. Procedure Best Practices
- **Transaction Management**: COMMIT/ROLLBACK in all data modification procedures
- **Input Validation**: Comprehensive parameter validation with business rules
- **Error Handling**: Structured exception management with meaningful messages

### 4. Advanced Error Handling
```sql
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Handle missing account scenarios
    WHEN OTHERS THEN
        -- General error handling with detailed messages
```

### 5. Cursor Implementation
- **Explicit Cursors**: Balance calculation and transaction processing
- **Cursor FOR Loops**: Efficient record processing in statements
- **Parameterized Cursors**: Dynamic query execution based on inputs

### 6. GOTO Usage (Demonstration)
- **Controlled Flow**: Clean error exit points in deposit operations
- **Label Management**: Structured code organization with meaningful labels
- **Best Practices**: Limited and justified usage for error handling

## 🧪 Testing the System

### Sample Test Scenarios

1. **Deposit Operation**
   ```sql
   -- Test successful deposit
   BEGIN
       bank_management.deposit_amount(101, 1000, 'Salary deposit');
   END;
   ```

2. **Withdrawal with Validation**
   ```sql
   -- Test withdrawal with insufficient funds
   BEGIN
       bank_management.withdraw_amount(101, 10000, 'Large withdrawal');
   END;
   ```

3. **Account Transfer**
   ```sql
   -- Test inter-account transfer
   BEGIN
       bank_management.transfer_amount(101, 102, 500, 'Fund transfer');
   END;
   ```

4. **Bank Statistics**
   ```sql
   -- Get comprehensive bank statistics
   DECLARE
       stats bank_management.customer_stats;
   BEGIN
       stats := bank_management.calculate_bank_statistics();
   END;
   ```

## 📊 Business Logic Highlights

### Banking Rules
- **Minimum Balance**: $100 required for all account types
- **Withdrawal Limit**: Maximum $5,000 per withdrawal transaction
- **Account Types**: Savings, Checking, Business with different features
- **Customer Tiers**: Regular, Premium, VIP with potential future benefits

### Transaction Security
- **Atomic Operations**: All transactions are all-or-nothing
- **Balance Validation**: Pre-transaction balance checks
- **Constraint Enforcement**: Database-level constraint validation
- **Audit Trail**: Complete transaction history tracking

## 🔧 Customization Options

### Easy Modifications

1. **Financial Parameters**
   ```sql
   -- Modify in package specification
   g_min_balance CONSTANT NUMBER := 250; -- Increase minimum balance
   g_max_withdrawal CONSTANT NUMBER := 10000; -- Increase withdrawal limit
   ```

2. **Account Types**
   ```sql
   -- Extend account type options
   account_type VARCHAR2(20) CHECK (account_type IN ('SAVINGS', 'CHECKING', 'BUSINESS', 'STUDENT'))
   ```

3. **Transaction Limits**
   ```sql
   -- Implement tier-based transaction limits
   -- Add daily withdrawal limits
   ```

## 🐛 Error Handling Scenarios

The system comprehensively handles various error conditions:
- ✅ Invalid account numbers
- ✅ Negative or zero transaction amounts
- ✅ Exceeding withdrawal limits
- ✅ Insufficient funds
- ✅ Same-account transfers
- ✅ Database constraint violations

## 📈 Performance Features

- **Bulk Operations**: Collection-based processing for multiple records
- **Efficient Cursors**: Proper cursor management and closure
- **Index-Friendly Queries**: Optimized for primary key lookups
- **Transaction Control**: Minimal locking periods

## 🎓 Learning Outcomes

After studying this project, you will understand:

1. **PL/SQL Collections**: When and how to use different collection types
2. **Modular Programming**: Package-based code organization and encapsulation
3. **Database Programming**: Transaction management and SQL integration
4. **Error Handling**: Comprehensive exception management strategies
5. **Banking Systems**: Financial transaction processing and validation

## 📝 Usage Notes

- Designed for educational purposes
- Includes demonstration of GOTO (use sparingly in production)
- Comprehensive error handling for learning
- Modular design for easy extension
- Well-commented code for understanding

## 🤝 Contributing

This is an educational project. Feel free to:
- Extend functionality with new features
- Improve error handling mechanisms
- Add additional validation rules
- Enhance performance optimizations

## 📄 License

Educational Use - Feel free to modify and learn from the code!

---

**Happy Banking!** 🏦💳
