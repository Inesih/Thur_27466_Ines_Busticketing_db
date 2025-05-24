#  BusTicketing Platform – Oracle PL/SQL Capstone Project

# 🎓 Student Information  
**Name:** Ihirwe Nzayisenga Ines  
**ID:** 27466  
**Course:** INSY 8311 (2024–2025)  
**Instructor:** Eric Maniraguha  
**Institution:** AUCA  
---
## 🔍 Problem Statement
Bus companies face issues such as overbooking, seat conflicts, and manual errors. This database system allows passengers to book seats, choose schedules, and pay securely while providing staff with operational control and reporting tools.

---

## 🎯 Objectives
- Allow passengers to reserve seats and make payments.
- Manage bus routes, schedules, and seating capacity.
- Prevent scheduling changes during holidays or weekdays via triggers.
- Track every booking/edit action in an audit table.
- 
---
## Solution Provide:
✔ **Real-time order processing**  
✔ **Automated inventory control**  
✔ **Business rule enforcement**  
✔ **Comprehensive activity auditing**  

---

## 🛠 Tech Stack  

| Component               | Tool                         |
|-------------------------|------------------------------|
| **Database**            | Oracle 21c                  |
| **Development**         | SQL Developer                |
| **Modeling**           | BPMN.io & SQL Modeler (ERD & BPMN)         |
| **Monitoring**         | Oracle Enterprise Manager    |

---
##  BPMN Diagram
Helps to so see the Work flow of the System through various processes and how their are conducted

---
##  ERD Diagram
Shows the Databse Schem how tables are related in other words  their Relationship 

---
##  OEM Diagram
The OEM Helped  me to live Monitor my Database through all the process i used Oracle Enteprise with a port number of 5505
![OEM](https://github.com/user-attachments/assets/1ad0c604-204d-432b-8d45-29effb1286f7)



##  Setup Guide  
I first created the Pluggable Database which is Mon_27483_Guervy_EcommercePlatform_DB
![Creation of PDB](https://github.com/user-attachments/assets/2e77b512-d6e6-4a7c-916d-7839aed686bb)

 
## 🗃️ Database Tables

### creation example of one of the tables 
```sql
CREATE TABLE Customer (
  CustomerID NUMBER PRIMARY KEY,
  FullName VARCHAR2(100),
  Email VARCHAR2(100),
  Password VARCHAR2(100),
  Phone VARCHAR2(20),
  Address VARCHAR2(255)
);

```
![creation of tables](https://github.com/user-attachments/assets/92d073b9-c1d6-4e20-bb84-32feaa594c00)


### Audit_Log
```sql
CREATE TABLE Audit_Log (
  LogID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  UserID VARCHAR2(50),
  ActionDate DATE,
  TableName VARCHAR2(50),
  Operation VARCHAR2(10),
  Status VARCHAR2(10)
);
```
![audit  table](https://github.com/user-attachments/assets/a4d2d5e1-b3fe-4089-9bd7-4d0d51534499)

---

## ⚙️ PL/SQL Package: ecommerce_pkg

### Specification
```sql
CREATE OR REPLACE PACKAGE ecommerce_pkg AS
  PROCEDURE Place_Order(p_customer_id IN NUMBER, p_product_id IN NUMBER, p_quantity IN NUMBER);
  FUNCTION Get_Total_Spent_By_Customer(p_customer_id IN NUMBER) RETURN NUMBER;
  TYPE pending_orders_cursor IS REF CURSOR;
  FUNCTION Get_Pending_Orders RETURN pending_orders_cursor;
END ecommerce_pkg;
/

### Body
CREATE OR REPLACE PACKAGE BODY ecommerce_pkg AS
  PROCEDURE Place_Order(p_customer_id IN NUMBER, p_product_id IN NUMBER, p_quantity IN NUMBER) IS
    v_price Product.Price%TYPE;
    v_subtotal NUMBER;
    v_order_id NUMBER;
    v_orderitem_id NUMBER;
  BEGIN
    SELECT Price INTO v_price FROM Product WHERE ProductID = p_product_id;
    v_subtotal := v_price * p_quantity;
    SELECT NVL(MAX(OrderID), 0) + 1 INTO v_order_id FROM Orders;

    INSERT INTO Orders(OrderID, CustomerID, OrderDate, TotalAmount, Status)
    VALUES (v_order_id, p_customer_id, SYSDATE, v_subtotal, 'Pending');

    SELECT NVL(MAX(OrderItemID), 0) + 1 INTO v_orderitem_id FROM OrderItem;
    INSERT INTO OrderItem(OrderItemID, OrderID, ProductID, Quantity, Subtotal)
    VALUES (v_orderitem_id, v_order_id, p_product_id, p_quantity, v_subtotal);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Order placed successfully. Order ID: ' || v_order_id);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END;

  FUNCTION Get_Total_Spent_By_Customer(p_customer_id IN NUMBER) RETURN NUMBER IS
    v_total NUMBER;
  BEGIN
    SELECT NVL(SUM(TotalAmount), 0) INTO v_total FROM Orders WHERE CustomerID = p_customer_id;
    RETURN v_total;
  END;

  FUNCTION Get_Pending_Orders RETURN pending_orders_cursor IS
    c_pending_orders pending_orders_cursor;
  BEGIN
    OPEN c_pending_orders FOR SELECT * FROM Orders WHERE Status = 'Pending';
    RETURN c_pending_orders;
  END;
END ecommerce_pkg;
/
```
![pkg1](https://github.com/user-attachments/assets/320bd78f-69ea-4d1f-8bc1-ece3e3fb51c5)

---

## 🔐 Trigger Logic
- Blocks DML actions on the `Schedule` table from Monday to Friday.
- Checks a `Holiday` table to block actions on specific holidays.
- Actions are logged in the `Audit_Log` table with status and timestamp.
In his trigger Helps Us to REstrict Modification of Data in Weekends
```sql
CREATE OR REPLACE TRIGGER trg_restrict_product_dml
BEFORE INSERT OR UPDATE OR DELETE ON Product
FOR EACH ROW
DECLARE
  v_holiday_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_holiday_count FROM Holiday WHERE HolidayDate = TRUNC(SYSDATE);
  IF TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') IN ('MON', 'TUE', 'WED', 'THU', 'FRI')
     OR v_holiday_count > 0 THEN
    INSERT INTO Audit_Log (UserID, ActionDate, TableName, Operation, Status)
    VALUES (USER, SYSDATE, 'Product', ORA_SYSEVENT, 'Denied');
    RAISE_APPLICATION_ERROR(-20001, 'DML operations on Product are restricted on weekdays and holidays.');
  ELSE
    INSERT INTO Audit_Log (UserID, ActionDate, TableName, Operation, Status)
    VALUES (USER, SYSDATE, 'Product', ORA_SYSEVENT, 'Allowed');
  END IF;
END;
/
```
![trigger weekends](https://github.com/user-attachments/assets/302fcbac-dcfa-46a0-b51e-5e24443e8e76)

---

-- Trigger test
```sql
UPDATE Product SET Price = 200 WHERE ProductID = 101;
```
![procedure success](https://github.com/user-attachments/assets/6a8491d1-d0f4-4d23-b303-4742c3159777)

---

## 👨‍🎓 Author
**Email: macariguervy@gmail.com**
**GitHub: github.com/RemezoGuervy**
**AUCA Student – Course Code : INSY 8311 (2024–2025)**
**Lecturer: Eric Maniraguha**
