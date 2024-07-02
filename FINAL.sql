CREATE DATABASE voovel;


--- HERE ARE TABLES

GO
--FIRST TABLE FOR SYSTEM INFO
CREATE TABLE sysInfo (
	Username nvarchar(20) COLLATE Latin1_General_BIN PRIMARY KEY,
	Password nvarchar(512),
	SignUpDate datetime,
	SysPhoneNum nvarchar(11)
);

 -- TABLE FOR PERSONAL INFO
CREATE TABLE personalInfo(
	Username nvarchar(20) COLLATE Latin1_General_BIN,
	FOREIGN KEY (Username) REFERENCES sysInfo(Username),
	FirstName nvarchar(20),
	LastName nvarchar(20),
	PhoneNum nvarchar(11),
	BirthDate date,
	NickName nvarchar(20),
	Id nvarchar(10),
	Address nvarchar(512)
);

-- TABLE FOR SIGN IN TIME
 CREATE TABLE SignIn_Info (
	Username nvarchar(20),
	SignIn_Date datetime
	);


 CREATE TABLE Notif_tb(
	Username nvarchar(20),
	Notif_time datetime,
	Notif_text nvarchar(512)
	);

 CREATE TABLE User_Permissions(
	Username nvarchar(20),
	Permitted nvarchar(20)
	);


 CREATE TABLE Receivers_tb(
	Sender_User nvarchar(20),
	Receiver_User nvarchar(30),
	Receive_Time datetime
 );


 CREATE TABLE ReceiversCC_tb(
	Sender_User nvarchar(20),
	Receiver_User nvarchar(30),
	Receive_Time datetime
 );


 CREATE TABLE Email_tb(
	E_ID INT IDENTITY(1,1) PRIMARY KEY,
	Sender nvarchar(30),
	E_Receivers nvarchar(30),
	E_ReceiversCC nvarchar(30),
	E_Subject nvarchar(50),
	E_Date datetime,
	E_Text nvarchar(512),
	E_Not_Read nvarchar(1)
 );


 ---HERE ARE PROCEDURES


 GO --PROCEDURE FOR SIGN UP PROCESS
CREATE PROCEDURE SignUp
	@username nvarchar(20),
	@password nvarchar(521),
	@sysphonenum nvarchar(11),
	@firstname nvarchar(20),
	@lastname nvarchar(20),
	@phonenum nvarchar(11),
	@birthdate date,
	@nickname nvarchar(20),
	@id nvarchar(10),
	@address nvarchar(512)
 AS
 BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
		IF NOT EXISTS (SELECT * FROM sysInfo WHERE Username COLLATE Latin1_General_CI_AI = @username) and LEN(@username) >= 6 and LEN(@password) >= 6
			BEGIN
				INSERT INTO sysInfo(Username, Password, SignUpDate, SysPhoneNum)
				VALUES (@username, HASHBYTES('SHA2_256', @password), GETDATE(), @sysphonenum);

				INSERT INTO personalInfo(Username,FirstName,LastName,PhoneNum,BirthDate, NickName, Id, Address)
				VALUES (@username, @firstname, @lastname, @phonenum, @birthdate, @nickname, @id, @address);

				INSERT INTO Notif_tb(Username,Notif_time, Notif_text)
				VALUES (@username, GETDATE(), 'You have signed up successfully');
				PRINT 'Sign up successful';
				COMMIT TRANSACTION;
			END
		ELSE IF LEN(@username) < 6 or LEN(@password) < 6
			BEGIN
				PRINT 'Username and Password MUST have at least 6 letters.';
				ROLLBACK TRANSACTION;
			END 
		ELSE
			BEGIN
				PRINT 'Username already exists.';
				ROLLBACK TRANSACTION;
			END
 END;



  GO --PROCEDURE FOR SIGN IN PROCESS
 CREATE PROCEDURE SignIn
	@username nvarchar(20),
	@password nvarchar(20)
	AS
	BEGIN

		IF EXISTS(SELECT * FROM sysInfo WHERE Username COLLATE Latin1_General_CI_AI = @username  AND Password = HASHBYTES('SHA2_256', @password))
			BEGIN
				INSERT INTO SignIn_Info(Username, SignIn_Date)
				VALUES (@username, GETDATE());
				PRINT 'Login successful.';

			END
		ELSE IF NOT EXISTS(SELECT * FROM sysInfo WHERE Username COLLATE Latin1_General_CI_AI = @username)
			BEGIN
				PRINT 'Username is not found.';
			END
		ELSE
			BEGIN
				PRINT 'Password is incorrect.';
			END
	END;




 GO 
 CREATE PROCEDURE Send_Notif
	@username nvarchar(20),
	@notif_text nvarchar(512)
	AS
	BEGIN
		INSERT INTO Notif_tb(Username, Notif_time, Notif_text)
		VALUES (@username, GETDATE(),@notif_text);
	END



GO 
CREATE PROCEDURE Self_Info_Show
	AS
	BEGIN
		SELECT sysInfo.Username, SignUpDate, SysPhoneNum, FirstName, LastName, PhoneNum, BirthDate, NickName, ID, Address
		FROM sysInfo
		FULL JOIN personalInfo
		ON sysInfo.Username = personalInfo.Username
		WHERE sysInfo.Username COLLATE Latin1_General_CI_AI = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC) 
	END 




GO
CREATE PROCEDURE Get_Notifs
	AS 
	BEGIN
		SELECT *
		FROM Notif_tb
		WHERE Username COLLATE Latin1_General_CI_AI  = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC)
		ORDER BY Notif_time DESC
	END



GO
CREATE PROCEDURE Give_Permission
	@Permitted_User nvarchar(20)
	AS
		DECLARE @Username nvarchar(20);
	BEGIN
		SELECT TOP 1 @Username = Username COLLATE Latin1_General_CI_AI FROM SignIn_Info ORDER BY SignIn_Date DESC;
		INSERT INTO User_Permissions(Username, Permitted)
		VALUES (@Username, @Permitted_User)
	END




GO 
CREATE PROCEDURE Others_Info_Show
	@username nvarchar(20)

	AS
	DECLARE @activeUser nvarchar(20) = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC)
	DECLARE @notif1 nvarchar(512) = CONCAT(@activeUser,' has tried to see your information and HAS PERMISSION.')
	DECLARE @notif2 nvarchar(512) = CONCAT(@activeUser,' has tried to see your information and DOES NOT HAVE PERMISSION.')
	BEGIN
		IF EXISTS(SELECT * FROM sysInfo WHERE Username = @username)
		BEGIN
			IF EXISTS(SELECT * FROM User_Permissions WHERE Username = @username AND Permitted = @activeUser)
			BEGIN
				SELECT sysInfo.Username, SignUpDate, SysPhoneNum, FirstName, LastName, PhoneNum, BirthDate, NickName, ID, Address
				FROM sysInfo
				FULL JOIN personalInfo
				ON sysInfo.Username = personalInfo.Username
				WHERE sysInfo.Username COLLATE Latin1_General_CI_AI = @username;

				EXEC Send_Notif @username, @notif1
			END
			ELSE
			BEGIN
				SELECT 
				REPLICATE('*', LEN(SysInfo.Username)) AS Username, 
				REPLICATE('*', LEN(SysPhoneNum)) AS SysPhoneNum,
				REPLICATE('*', LEN(FirstName)) AS FirstName,
				REPLICATE('*', LEN(LastName)) AS LastName,
				REPLICATE('*', LEN(PhoneNum)) AS PhoneNum,
				REPLICATE('*', LEN(BirthDate)) AS BirthDate,
				REPLICATE('*', LEN(NickName)) AS NickName,
				REPLICATE('*', LEN(Id)) AS ID,
				REPLICATE('*', LEN(Address)) AS Adress
				FROM sysInfo
				JOIN personalInfo
				ON sysInfo.Username = personalInfo.Username
				WHERE sysInfo.Username COLLATE Latin1_General_CI_AI = @username

				EXEC Send_Notif @username, @notif2
			END
		END
		ELSE
		BEGIN
			SELECT sysInfo.Username, SignUpDate, SysPhoneNum, FirstName, LastName, PhoneNum, BirthDate, NickName, ID, Address
			FROM sysInfo
			FULL JOIN personalInfo
			ON sysInfo.Username = personalInfo.Username
			WHERE sysInfo.Username COLLATE Latin1_General_CI_AI = @username;
		END
	END



 GO
 CREATE PROCEDURE Modify_User
	@password nvarchar(20) = NULL,
	@sysphonenum nvarchar(11) = NULL,
	@firstname nvarchar(20) = NULL,
	@lastname nvarchar(20) = NULL,
	@phonenum nvarchar(11) = NULL,
	@birthdate date = NULL,
	@nickname nvarchar(20) = NULL,
	@id nvarchar(10) = NULL,
	@address nvarchar(512) = NULL
	AS
		DECLARE @activeUser nvarchar(20) = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC)
		DECLARE @hashed_pass nvarchar(20) = HASHBYTES('SHA2_256', @password)
	BEGIN
		UPDATE sysInfo
		SET Password = ISNULL(@hashed_pass, Password), SysPhoneNum = ISNULL(@sysphonenum, SysPhoneNum)
		WHERE Username COLLATE Latin1_General_CI_AI = @activeUser;

		UPDATE personalInfo
		SET FirstName = ISNULL(@firstname, FirstName),
			LastName = ISNULL(@lastname, LastName),
			PhoneNum = ISNULL(@phonenum, PhoneNum),
			BirthDate = ISNULL(@birthdate, BirthDate),
			NickName = ISNULL(@nickname, NickName),
			Id = ISNULL(@id, Id),
			Address = ISNULL(@address, Address)
		WHERE Username COLLATE Latin1_General_CI_AI = @activeUser;

		EXEC Send_Notif @activeUser, 'Your profile has been updated successfully.'
	END



 GO
 CREATE PROC Delete_User
	@username nvarchar(20)
	AS 
	BEGIN
		DELETE FROM personalInfo WHERE Username COLLATE Latin1_General_CI_AI = @username
		DELETE FROM sysInfo WHERE Username COLLATE Latin1_General_CI_AI = @username
		DELETE FROM Notif_tb WHERE Username COLLATE Latin1_General_CI_AI = @username
		DELETE FROM SignIn_Info WHERE Username COLLATE Latin1_General_CI_AI = @username
		DELETE FROM User_Permissions WHERE Username COLLATE Latin1_General_CI_AI = @username
	END



	--EMAIL PART


 GO
 CREATE PROCEDURE Add_Receivers
	@N1 nvarchar(30) = N'',
	@N2 nvarchar(30) = N'',
	@N3 nvarchar(30) = N''
	AS
		DECLARE @sender nvarchar(30) = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC)
	BEGIN
		IF @N1 != N''
		BEGIN
			SET @N1 = LEFT(@N1, LEN(@N1) - 11);			
		END

		IF @N2 != N''
		BEGIN
			SET @N2 = LEFT(@N2, LEN(@N2) - 11);
		END

		IF @N3 != N''
		BEGIN
			SET @N3 = LEFT(@N3, LEN(@N3) - 11);
		END

		INSERT INTO Receivers_tb(Sender_User, Receiver_User, Receive_Time) VALUES (@sender, @N1, GETDATE());
		INSERT INTO Receivers_tb(Sender_User, Receiver_User, Receive_Time) VALUES (@sender, @N2, GETDATE());
		INSERT INTO Receivers_tb(Sender_User, Receiver_User, Receive_Time) VALUES (@sender, @N3, GETDATE());

		DELETE FROM Receivers_tb WHERE Receiver_User = N'';

	END


GO
 CREATE PROCEDURE Add_ReceiversCC
	@N1 nvarchar(30) = N'',
	@N2 nvarchar(30) = N'',
	@N3 nvarchar(30) = N''
	AS
		DECLARE @sender nvarchar(30) = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC)
	BEGIN

		IF @N1 != N''
		BEGIN
			SET @N1 = LEFT(@N1, LEN(@N1) - 11);			
		END

		IF @N2 != N''
		BEGIN
			SET @N2 = LEFT(@N2, LEN(@N2) - 11);
		END

		IF @N3 != N'' 
		BEGIN
			SET @N3 = LEFT(@N3, LEN(@N3) - 11);
		END


		INSERT INTO ReceiversCC_tb(Sender_User, Receiver_User, Receive_Time) VALUES (@sender, @N1, GETDATE());
		INSERT INTO ReceiversCC_tb(Sender_User, Receiver_User, Receive_Time) VALUES (@sender, @N2, GETDATE());
		INSERT INTO ReceiversCC_tb(Sender_User, Receiver_User, Receive_Time) VALUES (@sender, @N3, GETDATE());

		DELETE FROM ReceiversCC_tb WHERE Receiver_User = N'';
	END



GO
 CREATE PROCEDURE Send_Email
	@receiver1 nvarchar(30),
	@receiver2 nvarchar(30),
	@receiver3 nvarchar(30),
	@receiverCC1 nvarchar(30),
	@receiverCC2 nvarchar(30),
	@receiverCC3 nvarchar(30),
	@email_subject nvarchar(50),
	@email_text nvarchar(512)
	AS
		DECLARE @active_user nvarchar(20) = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC);
	BEGIN
		IF @receiver1 != N'' AND EXISTS(SELECT Username FROM sysInfo WHERE Username COLLATE Latin1_General_CI_AI = LEFT(@receiver1, LEN(@receiver1) - 11))
		BEGIN
			INSERT INTO Email_tb(Sender, E_Receivers, E_ReceiversCC, E_Subject, E_Date, E_Text, E_Not_Read)
			VALUES (@active_user, @receiver1, N'', @email_subject, GETDATE(), @email_text, N'1');
			EXEC Add_Receivers @receiver1


			IF @receiver2 != N'' AND EXISTS(SELECT Username FROM sysInfo WHERE Username COLLATE Latin1_General_CI_AI = LEFT(@receiver2, LEN(@receiver2) - 11))
				BEGIN
					INSERT INTO Email_tb(Sender, E_Receivers, E_ReceiversCC, E_Subject, E_Date, E_Text, E_Not_Read)
					VALUES (@active_user, @receiver2, N'', @email_subject, GETDATE(), @email_text, N'1')	
					EXEC Add_Receivers @receiver2
				END

			IF @receiver3 != N'' AND EXISTS(SELECT Username FROM sysInfo WHERE Username COLLATE Latin1_General_CI_AI = LEFT(@receiver3, LEN(@receiver3) - 11))
				BEGIN
					INSERT INTO Email_tb(Sender, E_Receivers, E_ReceiversCC, E_Subject, E_Date, E_Text, E_Not_Read)
					VALUES (@active_user, @receiver3, N'', @email_subject, GETDATE(), @email_text, N'1')
					EXEC Add_Receivers @receiver3

				END


			IF @receiverCC1 != N'' AND EXISTS(SELECT Username FROM sysInfo WHERE Username COLLATE Latin1_General_CI_AI = LEFT(@receiverCC1, LEN(@receiverCC1) - 11))
				BEGIN
					INSERT INTO Email_tb(Sender, E_Receivers, E_ReceiversCC, E_Subject, E_Date, E_Text, E_Not_Read)
					VALUES (@active_user, N'', @receiverCC1, @email_subject, GETDATE(), @email_text, N'1')
					EXEC Add_ReceiversCC @receiverCC1
				END

			IF @receiverCC2 != N'' AND EXISTS(SELECT Username FROM sysInfo WHERE Username COLLATE Latin1_General_CI_AI = LEFT(@receiverCC2, LEN(@receiverCC2) - 11))
				BEGIN
					INSERT INTO Email_tb(Sender, E_Receivers, E_ReceiversCC, E_Subject, E_Date, E_Text, E_Not_Read)
					VALUES (@active_user, N'', @receiverCC2, @email_subject, GETDATE(), @email_text, N'1')
					EXEC Add_ReceiversCC @receiverCC2
				END


			IF @receiverCC3 != N'' AND EXISTS(SELECT Username FROM sysInfo WHERE Username COLLATE Latin1_General_CI_AI = LEFT(@receiverCC3, LEN(@receiverCC3) - 11))
				BEGIN
					INSERT INTO Email_tb(Sender, E_Receivers, E_ReceiversCC, E_Subject, E_Date, E_Text, E_Not_Read)
					VALUES (@active_user, N'', @receiverCC3, @email_subject, GETDATE(), @email_text, N'1')
					EXEC Add_ReceiversCC @receiverCC3
				END

		END
		ELSE
		BEGIN
			PRINT N'You MUST at least have ONE receiver OR receiver is NOT VALID.'
		END
	END


GO
 CREATE PROCEDURE Get_Received_Emails
 @page_num int
 AS
	DECLARE @active_user nvarchar(20) = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC);
 BEGIN
	SELECT E_ID, Sender, E_Subject, E_Date, E_Text , E_Not_Read
	FROM Email_tb
	WHERE E_Receivers != N'' AND LEFT(E_Receivers, LEN(E_Receivers) - 11) = @active_user
	ORDER BY E_Date DESC
	OFFSET (@page_num - 1) * 10 ROWS
	FETCH NEXT 10 ROWS ONLY;

 END



 GO
 CREATE PROCEDURE Read_Emails
	@e_id INT
	AS
		DECLARE @active_user nvarchar(20) = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC);
		DECLARE @res nvarchar(30) = (SELECT E_Receivers FROM Email_tb WHERE E_ID = @e_id)
		DECLARE @resCC nvarchar(30) = (SELECT E_ReceiversCC FROM Email_tb WHERE E_ID = @e_id)
	BEGIN
		IF LEFT(@res, LEN(@res) - 11) = @active_user OR LEFT(@resCC, LEN(@resCC) - 11) = @active_user
		BEGIN
			SELECT E_Text FROM Email_tb WHERE E_ID = @e_id
		
			UPDATE Email_tb
			SET E_Not_Read = N'0'
			WHERE E_ID = @e_id
		END
		ELSE
		BEGIN
			PRINT N'Sorry, you do NOT have permission';
		END
	END


GO
 CREATE PROCEDURE Get_Sent_Emails
 @page_num int
 AS
	DECLARE @active_user nvarchar(20) = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC);
 BEGIN
	SELECT E_ID, E_Receivers, E_ReceiversCC, E_Subject, E_Date, E_Text , E_Not_Read
	FROM Email_tb
	WHERE Sender = @active_user
	ORDER BY E_Date DESC
	OFFSET (@page_num - 1) * 10 ROWS
	FETCH NEXT 10 ROWS ONLY;

 END



 GO
 CREATE PROCEDURE Delete_Email
 @e_id INT
 AS
 	DECLARE @active_user nvarchar(20) = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC);
	DECLARE @sender nvarchar(30) = (SELECT Sender FROM Email_tb WHERE E_ID = @e_id)
 BEGIN
 	IF @sender = @active_user
	BEGIN
		DELETE FROM Email_tb WHERE E_ID = @e_id
	END
	ELSE
	BEGIN
		PRINT 'Sorry, you do NOT have permission.'
	END
 END




 --- HERE ARE TRIGGERS

 GO
 CREATE TRIGGER LI_Notif_tr
 ON SignIn_Info
 AFTER INSERT
 AS
	DECLARE @active_user nvarchar(20) = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC)
 BEGIN
	INSERT INTO Notif_tb (Username, Notif_time, Notif_text)
	VALUES (@active_user, GETDATE(), N'You have logged in successfully.')
 END


 GO 
 CREATE TRIGGER E_Notif_tr
 ON Receivers_tb
 AFTER INSERT
 AS
	DECLARE @username nvarchar(20) = (SELECT TOP 1 Receiver_User FROM Receivers_tb ORDER BY Receive_Time DESC);
 BEGIN
	INSERT INTO Notif_tb (Username, Notif_time, Notif_text)
	VALUES (@username, GETDATE(), N'You have a new email.')

	DELETE FROM Notif_tb WHERE Username = N'';
 END


 GO 
 CREATE TRIGGER ECC_Notif_tr
 ON ReceiversCC_tb
 AFTER INSERT
 AS
	DECLARE @username nvarchar(20) = (SELECT TOP 1 Receiver_User FROM ReceiversCC_tb ORDER BY Receive_Time DESC);
 BEGIN
	INSERT INTO Notif_tb (Username, Notif_time, Notif_text)
	VALUES (@username, GETDATE(), N'You have a new email.')
	DELETE FROM Notif_tb WHERE Username = N'';
 END


 GO
 CREATE TRIGGER DE_Notif_tr
 ON Email_tb
 AFTER DELETE
 AS
  	DECLARE @active_user nvarchar(20) = (SELECT TOP 1 Username FROM SignIn_Info ORDER BY SignIn_Date DESC);
 BEGIN
	INSERT INTO Notif_tb(Username, Notif_time, Notif_text)
	VALUES (@active_user, GETDATE(), N'You have deleted an email.')
 END




 ---- TEST PART

 EXEC SignUp 'NazaninNQ', 'nnq2002','09111111112', 'Nazanin', 'Nickqalb', '09122222223', '11-11-2002', 'NNQ', '11302321', 'TEHRAN, AZADI';
 
 EXEC SignUp 'Arshia.HBR','ar224028', '09101753118','Arshia', 'Hosseini', '09101753118', '2002-01-06', 'ARShbR', '1102225526', 'Golestan_Kordkuy_5'; 

 EXEC SignIn 'NazaninNQ', 'nq2002';

 EXEC Self_Info_Show ;

 EXEC Give_Permission 'Arshia.HBR';

 EXEC Others_Info_Show 'Arshia.HBR';

 EXEC SignIn 'Arshia.HBR', 'ar224028';

 EXEC Others_Info_Show 'NazaninNQ';

 EXEC SignIn 'NazaninNQ', 'nnq2002';

 EXEC Modify_User 'nazi!', '09111111112', 'Nazanin', 'Nickqalb', '09122222223', '11-11-2002', 'NNQ', '11302321', 'TEHRAN, AZADI';

 EXEC Delete_User 'Arshia.HBR'

