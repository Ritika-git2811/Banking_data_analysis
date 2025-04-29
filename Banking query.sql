use bank;
CREATE TABLE transactions (
    step INT,
    type VARCHAR(20),
    amount DECIMAL(15 , 2 ),
    nameorig VARCHAR(20),
    oldbalanceorg DECIMAL(15 , 2 ),
    newbalanceorg DECIMAL(15 , 2 ),
    newDest VARCHAR(20),
    oldbalanceDest DECIMAL(15 , 2 ),
    newbalanceDest DECIMAL(15 , 2 ),
    isfraud TINYINT,
    isflaggedfraud TINYINT
);
SELECT 
    *
FROM
    transactions
LIMIT 10;

#-- 1. Detecting Recursive Fraudulent Transactions
WITH RECURSIVE fraud_chain as (
SELECT nameOrig as initial_account,
newDest as next_account,
step,
amount,
newbalanceorg
FROM 
transactions
WHERE isFraud = 1 and type = 'TRANSFER'

UNION ALL 

SELECT fc.initial_account,
t.newDest,t.step,t.amount ,t.newbalanceorg
FROM fraud_chain fc
JOIN transactions t
ON fc.next_account = t.nameorig and fc.step < t.step 
where t.isfraud = 1 and t.type = 'TRANSFER')

SELECT * FROM fraud_chain;


#Analyzing Fraudulent Activity over Time
with rolling_fraud as ( SELECT nameorig,step, 
SUM(isfraud) OVER (PARTITION BY nameOrig order by STEP ROWS BETWEEN 4 PRECEDING and CURRENT ROW ) as fraud_rolling
FROM transactions)

SELECT * FROM rolling_fraud
WHERE fraud_rolling > 0 ;

-- 3. Complex Fraud Detection Using Multiple CTEs
-- Question:
-- Use multiple CTEs to identify accounts with suspicious activity, including large transfers, consecutive transactions without balance change, and flagged transactions.
WITH large_transfers as (
SELECT nameOrig,step,amount FROM transactions WHERE type = 'TRANSFER' and amount >500000),
no_balance_change as (
SELECT nameOrig,step,oldbalanceOrg,newbalanceOrg FROM transactions where oldbalanceOrg=newbalanceOrg),
flagged_transactions as (
SELECT nameOrig,step FROM transactions where  isflaggedfraud = 1) 

SELECT 
    lt.nameOrig
FROM 
    large_transfers lt
JOIN 
    no_balance_change nbc ON lt.nameOrig = nbc.nameOrig AND lt.step = nbc.step
JOIN 
    flagged_transactions ft ON lt.nameOrig = ft.nameOrig AND lt.step = ft.step;


-- 4. Write me a query that checks if the computed new_updated_Balance is the same as the actual newbalanceDest in the table. If they are equal, it returns those rows.

with CTE as (
SELECT amount,nameorig,oldbalancedest,newbalanceDest,(amount+oldbalancedest) as new_updated_Balance 
FROM transactions
)
SELECT * FROM CTE where new_updated_Balance = newbalanceDest;


SELECT 
    amount, nameorig, oldbalanceorg, newbalanceorg
FROM
    transactions
WHERE
    oldbalanceorg = 0 AND newbalanceorg = 0