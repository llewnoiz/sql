USE [TEST]
GO
/****** Object:  Trigger [dbo].[trigger_test_history]    Script Date: 2023-08-17 오후 2:44:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[trigger_test_history]
   ON  [dbo].[test]
   AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	declare @TableName nvarchar(500)	
	declare @sql nvarchar(MAX)
	declare @columns NVARCHAR(MAX)
	declare @values NVARCHAR(MAX);
	declare @count int
	declare @insertedCount int
	declare @insertedMax int
	declare @max int

	declare @result nvarchar(max)
	declare @tmpName nvarchar(max) 
	declare @tmpType nvarchar(max) 							
	declare @tmpQuery nvarchar(max) 
	declare @param nvarchar(max) 
	declare @tmpVal nvarchar(max)	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	
	DECLARE @currentSessionID INT;
	--SET NOCOUNT ON;

	SET @TableName = 'test';
	SET @columns = '';
	SET @values = '';
	SET @count = 1;
	SET @max = 0;
	SET @insertedCount = 1;
	SET @insertedMax = 0;
	 -- INSERT 작업인 경우
    IF EXISTS (SELECT * FROM INSERTED) AND NOT EXISTS (SELECT * FROM DELETED)
    BEGIN

		-- current table colums information 
		select *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn into #rp_inserted from inserted;
		select @insertedMax = count(*) from #rp_inserted;

		SELECT @columns = @columns + column_name + ','
		FROM information_schema.columns
		WHERE table_name = @TableName;
		SET @columns = LEFT(@columns, LEN(@columns) - 1);
		
		SELECT ORDINAL_POSITION as id , column_name as name, DATA_TYPE as type  into #tempColumnTables
		FROM information_schema.columns
		WHERE table_name = @TableName;

		select @max = count(*) from #tempColumnTables;
		SET @sql = 'insert into ' +@TableName+' ('+@columns + ') '
		SET @sql = @sql + ' values';

	
		while @insertedCount <= @insertedMax
		begin 
			SET @count = 1;
			
			while @count <= @max
			begin
							
				set @tmpName = ( select name from #tempColumnTables where id = @count );		
				set @tmpType = (select type from #tempColumnTables where id = @count);
				set @tmpQuery = N'select @result = CASE  when ISNUMERIC('+@tmpName+') = 1 then '+@tmpName+' else '''+@tmpName+''' end from #rp_inserted where rn =' + CAST(@insertedCount AS nvarchar);
				set @param = N'@result nvarchar(max) OUTPUT';						
				set @tmpVal = '';
				EXEC sp_executesql @tmpQuery, @param, @result=@tmpVal OUTPUT;

				set @values = @values + @tmpVal + ','
				set @count = @count + 1;
				
			end;
			SET @values = LEFT(@values, LEN(@values) - 1);
			
			-- make dynamic sql
			SET @sql = @sql + ' ('+@values+'),';
			SET @values = ''
			SET @insertedCount = @insertedCount + 1;
			
		end

		SET @sql = LEFT(@sql, LEN(@sql) - 1) + ';';
		-- insert history db query		
		insert into history values(1,@sql,1);
    END;

	-- DELETE 작업인 경우
    IF EXISTS (SELECT * FROM DELETED) AND NOT EXISTS (SELECT * FROM INSERTED)
    BEGIN
		
		-- current table colums information 
		select distinct *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn into #rp_deleted from deleted;
		select @insertedMax = count(*) from #rp_deleted;

		SELECT ORDINAL_POSITION as id , column_name as name, DATA_TYPE as type  into #tempDelColumnTables
		FROM information_schema.columns
		WHERE table_name = @TableName;

		select @max = count(*) from #tempDelColumnTables;
		
		while @insertedCount <= @insertedMax
		begin 
			SET @count = 1;
			SET @sql = 'delete ' +@TableName
			SET @sql = @sql + ' where';

			while @count <= @max
			begin
							
				set @tmpName = ( select name from #tempDelColumnTables where id = @count );		
				set @tmpType = (select type from #tempDelColumnTables where id = @count);
				set @tmpQuery = N'select @result = CASE  when ISNUMERIC('+@tmpName+') = 1 then '+@tmpName+' else ' +@tmpName+ ' end from #rp_deleted where rn =' + CAST(@insertedCount AS nvarchar);
				set @param = N'@result nvarchar(max) OUTPUT';						
				set @tmpVal = '';
				EXEC sp_executesql @tmpQuery, @param, @result=@tmpVal OUTPUT;

				set @values = @values +' '+ @tmpName + '=' + @tmpVal + ' and'
				set @count = @count + 1;
				
			end;
			--SET @values = LEFT(@values, LEN(@values) - 3);
			
			-- make dynamic sql		
			SET @sql = @sql +@values;
			SET @values = ''
			SET @sql = LEFT(@sql, LEN(@sql) - 3);
			SET @sql =@sql + ';';
			-- insert history db query		
			insert into history values(1,@sql,2);
			SET @insertedCount = @insertedCount + 1;
			
		end

    END;


    -- UPDATE 작업인 경우
    IF EXISTS (SELECT * FROM INSERTED) AND EXISTS (SELECT * FROM DELETED)
    BEGIN

		select * from inserted;
		select * from deleted;
    END;
END