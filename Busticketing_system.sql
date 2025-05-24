CREATE TABLE Passenger (
  PassengerID NUMBER PRIMARY KEY,
  FullName VARCHAR2(100),
  Email VARCHAR2(100),
  Phone VARCHAR2(20)
);
CREATE TABLE Bus (
  BusID NUMBER PRIMARY KEY,
  PlateNumber VARCHAR2(20),
  Capacity NUMBER,
  Status VARCHAR2(20)
);
CREATE TABLE Route (
  RouteID NUMBER PRIMARY KEY,
  Origin VARCHAR2(100),
  Destination VARCHAR2(100),
  Distance_KM NUMBER
);
CREATE TABLE Trip (
  TripID NUMBER PRIMARY KEY,
  BusID NUMBER,
  RouteID NUMBER,
  TripDate DATE,
  DepartureTime VARCHAR2(10),
  Fare NUMBER
);
CREATE TABLE Ticket (
  TicketID NUMBER PRIMARY KEY,
  PassengerID NUMBER,
  TripID NUMBER,
  SeatNumber NUMBER,
  BookingDate DATE
);
CREATE TABLE Payment (
  PaymentID NUMBER PRIMARY KEY,
  TicketID NUMBER,
  Amount NUMBER,
  PaymentDate DATE,
  PaymentMethod VARCHAR2(50)
);
CREATE TABLE Audit_Log (
  LogID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  UserID VARCHAR2(50),
  ActionDate DATE,
  TableName VARCHAR2(50),
  Operation VARCHAR2(10),
  Status VARCHAR2(10)
);

CREATE TABLE Holiday (
  HolidayDate DATE PRIMARY KEY,
  Description VARCHAR2(100)
);

-- Insert sample passenger
INSERT INTO Passenger VALUES (1, 'Alice Smith', 'alice@example.com', '0788000001');

-- Insert bus
INSERT INTO Bus VALUES (101, 'RAC 123 A', 60, 'Available');

-- Insert route
INSERT INTO Route VALUES (1, 'Kigali', 'Huye', 120);

-- Insert trip
INSERT INTO Trip VALUES (1001, 101, 1, TO_DATE('2025-06-10', 'YYYY-MM-DD'), '08:00 AM', 5000);

-- View available trips
SELECT TripID, TripDate, DepartureTime, Fare FROM Trip;

-- View booked tickets
SELECT * FROM Ticket;

-- View payments
SELECT * FROM Payment;

CREATE OR REPLACE PROCEDURE Book_Ticket (
  p_passenger_id IN NUMBER,
  p_trip_id IN NUMBER,
  p_seat_number IN NUMBER
) IS
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
  DBMS_OUTPUT.PUT_LINE('Ticket booked. ID: ' || v_ticket_id);
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

CREATE OR REPLACE FUNCTION Get_Total_Paid_By_Passenger (
  p_passenger_id IN NUMBER
) RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  SELECT NVL(SUM(p.Amount), 0)
  INTO v_total
  FROM Payment p
  JOIN Ticket t ON p.TicketID = t.TicketID
  WHERE t.PassengerID = p_passenger_id;

  RETURN v_total;
END;
/
DECLARE
  CURSOR c_trips IS
    SELECT TripID, TripDate, DepartureTime, Fare
    FROM Trip
    WHERE BusID = 101;

  v_id Trip.TripID%TYPE;
  v_date Trip.TripDate%TYPE;
  v_time Trip.DepartureTime%TYPE;
  v_fare Trip.Fare%TYPE;
BEGIN
  OPEN c_trips;
  LOOP
    FETCH c_trips INTO v_id, v_date, v_time, v_fare;
    EXIT WHEN c_trips%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Trip: ' || v_id || ' Date: ' || v_date || ' Time: ' || v_time || ' Fare: ' || v_fare);
  END LOOP;
  CLOSE c_trips;
END;
/
CREATE OR REPLACE PACKAGE bus_pkg AS
  PROCEDURE Book_Ticket(p_passenger_id IN NUMBER, p_trip_id IN NUMBER, p_seat_number IN NUMBER);
  FUNCTION Get_Total_Paid_By_Passenger(p_passenger_id IN NUMBER) RETURN NUMBER;
END;
/
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

