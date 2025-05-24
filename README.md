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
![BPMN](https://github.com/user-attachments/assets/11e41935-5784-44b8-9510-3241f423901f)


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
CREATE TABLE Bus (
  BusID NUMBER PRIMARY KEY,
  PlateNumber VARCHAR2(20),
  Capacity NUMBER,
  Status VARCHAR2(20)
);


```
![table creation](https://github.com/user-attachments/assets/3f6c5990-9247-4280-a735-5fd83c921f99)



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
![audit table](https://github.com/user-attachments/assets/55d2be2d-7dfd-4f31-bfec-25f903c36b13)


---

## ⚙️ PL/SQL Package: bus_pkg

### Specification
```sql
CREATE OR REPLACE PACKAGE bus_pkg AS
  PROCEDURE Book_Ticket(p_passenger_id IN NUMBER, p_trip_id IN NUMBER, p_seat_number IN NUMBER);
  FUNCTION Get_Total_Paid_By_Passenger(p_passenger_id IN NUMBER) RETURN NUMBER;
END;
/


### Body
CREATE OR REPLACE PACKAGE BODY bus_pkg AS

  PROCEDURE Book_Ticket(p_passenger_id IN NUMBER, p_trip_id IN NUMBER, p_seat_number IN NUMBER) IS
    v_ticket_id NUMBER;
    v_fare NUMBER;
  BEGIN
    SELECT Fare INTO v_fare FROM Trip WHERE TripID = p_trip_id;
    SELECT NVL(MAX(TicketID), 0) + 1 INTO v_ticket_id FROM Ticket;

    INSERT INTO Ticket (TicketID, PassengerID, TripID, SeatNumber, BookingDate)
    VALUES (v_ticket_id, p_passenger_id, p_trip_id, p_seat_number, SYSDATE);

    INSERT INTO Payment (PaymentID, TicketID, Amount, PaymentDate, PaymentMethod)
    VALUES (v_ticket_id, v_ticket_id, v_fare, SYSDATE, 'Cash');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Ticket booked: ' || v_ticket_id);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END;

  FUNCTION Get_Total_Paid_By_Passenger(p_passenger_id IN NUMBER) RETURN NUMBER IS
    v_total NUMBER;
  BEGIN
    SELECT NVL(SUM(p.Amount), 0)
    INTO v_total
    FROM Payment p
    JOIN Ticket t ON p.TicketID = t.TicketID
    WHERE t.PassengerID = p_passenger_id;

    RETURN v_total;
  END;

END bus_pkg;
/

```
![pkg specification](https://github.com/user-attachments/assets/a523fade-7eca-4723-8602-88e01e1e169c)


---

## 🔐 Trigger Logic
- Blocks DML actions on the `Schedule` table from Monday to Friday.
- Checks a `Holiday` table to block actions on specific holidays.
- Actions are logged in the `Audit_Log` table with status and timestamp.
In this trigger Helps Us to REstrict Modification of Data in Weekends
```sql
CREATE OR REPLACE TRIGGER trg_restrict_ticket_dml
BEFORE INSERT OR UPDATE OR DELETE ON Ticket
FOR EACH ROW
DECLARE
  v_holiday_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_holiday_count
  FROM Holiday
  WHERE HolidayDate = TRUNC(SYSDATE);

  IF TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') IN ('SAT', 'SUN')
     OR v_holiday_count > 0 THEN

    -- Log the denied attempt
    INSERT INTO Audit_Log (UserID, ActionDate, TableName, Operation, Status)
    VALUES (USER, SYSDATE, 'Ticket', ORA_SYSEVENT, 'Denied');

    RAISE_APPLICATION_ERROR(-20002, 'Modifications to Ticket table are not allowed on weekends or holidays.');
  ELSE
    -- Log the allowed action
    INSERT INTO Audit_Log (UserID, ActionDate, TableName, Operation, Status)
    VALUES (USER, SYSDATE, 'Ticket', ORA_SYSEVENT, 'Allowed');
  END IF;
END;
/

```
![trigger](https://github.com/user-attachments/assets/be62e350-ac45-4bf7-a145-03f94e709608)


---



##  Contact
**Email: ihirwenzayisengaines@gmail.com**
**GitHub: github.com/Inesih**
